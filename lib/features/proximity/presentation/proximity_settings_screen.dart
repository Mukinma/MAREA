import 'package:flutter/material.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';

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
      final status = await _bridge.status().timeout(const Duration(seconds: 8));
      if (_current) {
        setState(() {
          _status = status;
          _error = null;
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

  Future<void> _stop() async {
    if (!_current || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _bridge.stop();
      if (_current) await _refresh();
    } catch (_) {
      if (_current) {
        setState(() => _error = 'No pudimos detener los avisos. Reintenta.');
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _openPermissions() async {
    try {
      await _bridge.openSettings();
    } catch (_) {
      if (_current) {
        setState(() => _error = 'No pudimos abrir los permisos del teléfono.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = _status['supported'] == true;
    final enabled = _status['enabled'] == true;
    final running = _status['running'] == true;
    return ProfilePage(
      title: 'Ubicación y avisos cercanos',
      fallback: '/settings',
      busy: _current && _busy,
      body: SingleChildScrollView(
        child: ProfilePageFrame(
          child: !_current
              ? const Text('Abre los avisos desde tu sesión.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    const ProfileFormSection(
                      title: 'Ubicación en el mapa',
                      icon: Icons.map_outlined,
                      children: [
                        Text(
                          'MAREA usa tu ubicación para centrar el mapa o buscar lugares cercanos cuando tú lo solicitas.',
                        ),
                      ],
                    ),
                    ProfileFormSection(
                      title: 'Avisos a 20 metros',
                      icon: Icons.notifications_active_outlined,
                      children: [
                        const Text(
                          'Al activar los avisos, MAREA usa la ubicación precisa incluso con la app cerrada para avisarte si te acercas a una misión o un marcador de RA. Los lugares con ubicación aproximada quedan fuera de ese cálculo.',
                        ),
                        if (_error case final error?) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              error,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          if (_status.isEmpty)
                            OutlinedButton(
                              onPressed: _busy ? null : _refresh,
                              child: const Text('Reintentar'),
                            ),
                        ],
                        if (_status['supported'] == false)
                          const Text(
                            'Los avisos con la app cerrada están disponibles en Android.',
                          ),
                        if (enabled)
                          Text(
                            running
                                ? 'Avisos activos para ${_status['count'] ?? 0} lugares cargados.'
                                : 'El seguimiento está detenido. Revisa los permisos y reactívalo.',
                          ),
                        if (supported && !running)
                          FilledButton(
                            onPressed: _busy ? null : _activate,
                            child: Text(
                              enabled ? 'Reactivar avisos' : 'Activar avisos',
                            ),
                          ),
                        if (supported && enabled)
                          OutlinedButton(
                            onPressed: _busy ? null : _stop,
                            child: const Text('Detener avisos'),
                          ),
                        if (supported)
                          TextButton(
                            onPressed: _busy ? null : _openPermissions,
                            child: const Text('Abrir permisos del teléfono'),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
