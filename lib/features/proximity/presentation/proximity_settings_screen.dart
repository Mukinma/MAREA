import 'package:flutter/material.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/presentation/tour_widgets.dart';

import '../data/app_proximity_targets.dart';
import '../data/native_proximity_bridge.dart';
import '../models/proximity_models.dart';

class ProximitySettingsScreen extends StatefulWidget {
  const ProximitySettingsScreen({
    required this.controller,
    this.bridge,
    this.location = const GeolocatorDeviceLocationService(),
    super.key,
  });
  final AppSessionController controller;
  final NativeProximityBridge? bridge;
  final DeviceLocationService location;
  @override
  State<ProximitySettingsScreen> createState() =>
      _ProximitySettingsScreenState();
}

class _ProximitySettingsScreenState extends State<ProximitySettingsScreen>
    with WidgetsBindingObserver {
  late final _bridge = widget.bridge ?? NativeProximityBridge.instance;
  late final _account = widget.controller.profile?.id;
  Map<String, dynamic> _status = {};
  bool _busy = true;
  String? _error;
  bool get _current =>
      mounted && _account != null && widget.controller.profile?.id == _account;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
    _refresh();
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await _bridge.status();
      if (_current) {
        setState(() {
          _status = status;
          _busy = false;
        });
      }
    } catch (_) {
      if (_current) {
        setState(() {
          _error = 'No pudimos consultar los avisos.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _activate() async {
    if (!_current || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _bridge.requestNotifications();
      if (!_current) return;
      final position = await widget.location.current(
        requestPermission: true,
        isCurrent: () => _current,
      );
      if (!_current) return;
      final status = await _bridge.status();
      if (!_current) return;
      if (status['precise'] != true ||
          status['always'] != true ||
          status['notifications'] != true) {
        setState(() {
          _status = status;
          _error =
              'En Ajustes permite ubicación precisa «Todo el tiempo» y las notificaciones. Después vuelve y activa los avisos.';
        });
        return;
      }
      final targets = await AppProximityTargets(widget.controller).load(
        ProximityFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        ),
      );
      if (!_current) return;
      await _bridge.configure(_account!, targets, start: true);
      if (!_current) return;
      await _refresh();
    } catch (e) {
      if (_current) {
        setState(
          () => _error = e is DeviceLocationFailure
              ? e.message
              : 'No pudimos activar los avisos. Revisa los permisos y vuelve a intentarlo.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Avisos a 20 metros'),
      leading: const TourBackButton(fallback: '/profile'),
    ),
    body: !_current
        ? const Center(child: Text('Abre los avisos desde tu sesión.'))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Recibe un aviso al acercarte a una Misión o un marcador RA, también con el teléfono bloqueado.',
              ),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) TourNotice(_error!),
              if (_status['supported'] == false)
                const TourNotice(
                  'El seguimiento con la app cerrada está disponible en Android. La compatibilidad de iOS está pendiente.',
                ),
              if (_status['enabled'] == true) ...[
                Text(
                  _status['running'] == true
                      ? 'Avisos activos para ${_status['count'] ?? 0} lugares cargados.'
                      : 'El seguimiento está detenido. Revisa los permisos y reactívalo.',
                ),
                if (_status['running'] != true)
                  FilledButton(
                    onPressed: _busy ? null : _activate,
                    child: const Text('Reactivar avisos'),
                  ),
                const Text(
                  'Los lugares se actualizan al abrir MAREA. El aviso depende de una ubicación GPS precisa; no se repite continuamente mientras permaneces dentro.',
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (!_current) return;
                          try {
                            await _bridge.stop();
                            await _refresh();
                          } catch (_) {
                            if (_current) {
                              setState(
                                () => _error =
                                    'No pudimos detener los avisos. Reintenta.',
                              );
                            }
                          }
                        },
                  child: const Text('Detener avisos'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _busy || _status['supported'] != true
                      ? null
                      : _activate,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Activar avisos'),
                ),
              TextButton(
                onPressed: _busy || _status['supported'] != true
                    ? null
                    : _bridge.openSettings,
                child: const Text('Abrir permisos del teléfono'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sólo se usan lugares con ubicación exacta. Las ubicaciones aproximadas no disparan avisos de 20 metros.',
              ),
            ],
          ),
  );
}
