import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';

import '../application/proximity_controller.dart';
import '../data/proximity_browser.dart';
import 'foreground_proximity.dart';
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
  bool _activating = false;
  String? _error;
  bool get _current =>
      mounted && _account != null && widget.controller.profile?.id == _account;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
    if (!kIsWeb) _refresh();
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed && !_activating) {
      _refresh();
    }
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
          _error = AppLocalizations.tr('No pudimos consultar los avisos.');
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
    _activating = true;
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
          (status['ios'] != true && status['always'] != true) ||
          status['notifications'] != true) {
        setState(() {
          _status = status;
          _error = AppLocalizations.tr(
            status['ios'] == true
                ? 'En Ajustes permite la ubicación precisa y las notificaciones. Después vuelve y activa los avisos.'
                : 'En Ajustes permite ubicación precisa «Todo el tiempo» y las notificaciones. Después vuelve y activa los avisos.',
          );
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
              : AppLocalizations.tr(
                  'No pudimos activar los avisos. Revisa los permisos y vuelve a intentarlo.',
                ),
        );
      }
    } finally {
      _activating = false;
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
        setState(
          () => _error = AppLocalizations.tr(
            'No pudimos detener los avisos. Reintenta.',
          ),
        );
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
        setState(
          () => _error = AppLocalizations.tr(
            'No pudimos abrir los permisos del teléfono.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final webMonitor = ForegroundProximityScope.maybeOf(context);
    final ios = _status['ios'] == true;
    final supported = _status['supported'] == true;
    final enabled = _status['enabled'] == true;
    final running = _status['running'] == true;
    return ProfilePage(
      title: AppLocalizations.tr('Ubicación y avisos cercanos'),
      fallback: '/settings',
      busy: !kIsWeb && _current && _busy,
      body: SingleChildScrollView(
        child: ProfilePageFrame(
          child: !_current
              ? Text(AppLocalizations.tr('Abre los avisos desde tu sesión.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    ProfileFormSection(
                      title: AppLocalizations.tr('Ubicación en el mapa'),
                      icon: Icons.map_outlined,
                      children: [
                        Text(
                          AppLocalizations.tr(
                            'MAREA usa tu ubicación para centrar el mapa o buscar lugares cercanos cuando tú lo solicitas.',
                          ),
                        ),
                      ],
                    ),
                    if (kIsWeb)
                      ForegroundProximitySettings(
                        monitor: webMonitor,
                        account: _account!,
                        supported: browserLocationSupported,
                      )
                    else
                      ProfileFormSection(
                        title: AppLocalizations.tr('Avisos a 20 metros'),
                        icon: Icons.notifications_active_outlined,
                        children: [
                          Text(
                            AppLocalizations.tr(
                              ios
                                  ? 'Con ubicación precisa, MAREA te avisa de misiones y marcadores a 20 metros mientras usas la app. Con el permiso «Siempre» también puede avisarte en segundo plano. Si cierras la app por completo, vuelve a abrirla para reanudar los avisos.'
                                  : 'Al activar los avisos, MAREA usa la ubicación precisa incluso con la app cerrada para avisarte si te acercas a una misión o un marcador de RA. Los lugares con ubicación aproximada quedan fuera de ese cálculo.',
                            ),
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
                                child: Text(AppLocalizations.tr('Reintentar')),
                              ),
                          ],
                          if (_status['supported'] == false)
                            Text(
                              AppLocalizations.tr(
                                'Los avisos cercanos no están disponibles en este dispositivo.',
                              ),
                            ),
                          if (enabled)
                            Text(
                              running
                                  ? AppLocalizations.tr(
                                      'Avisos activos para ${_status['count'] ?? 0} lugares cargados.',
                                    )
                                  : AppLocalizations.tr(
                                      'El seguimiento está detenido. Revisa los permisos y reactívalo.',
                                    ),
                            ),
                          if (supported && !running)
                            FilledButton(
                              onPressed: _busy ? null : _activate,
                              child: Text(
                                enabled
                                    ? AppLocalizations.tr('Reactivar avisos')
                                    : AppLocalizations.tr('Activar avisos'),
                              ),
                            ),
                          if (ios && enabled && _status['always'] != true)
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      try {
                                        await _bridge.requestBackground();
                                        if (_current) await _refresh();
                                      } catch (_) {
                                        if (_current) await _openPermissions();
                                      }
                                    },
                              child: Text(
                                AppLocalizations.tr(
                                  'Permitir avisos en segundo plano',
                                ),
                              ),
                            ),
                          if (supported && enabled)
                            OutlinedButton(
                              onPressed: _busy ? null : _stop,
                              child: Text(
                                AppLocalizations.tr('Detener avisos'),
                              ),
                            ),
                          if (supported)
                            TextButton(
                              onPressed: _busy ? null : _openPermissions,
                              child: Text(
                                AppLocalizations.tr(
                                  'Abrir permisos del teléfono',
                                ),
                              ),
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

class ForegroundProximitySettings extends StatelessWidget {
  const ForegroundProximitySettings({
    required this.monitor,
    required this.account,
    required this.supported,
    super.key,
  });
  final ProximityController? monitor;
  final String account;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final controller = monitor;
    return ProfileFormSection(
      title: AppLocalizations.tr('Avisos a 20 metros'),
      icon: Icons.notifications_active_outlined,
      children: [
        Text(
          AppLocalizations.tr(
            'Activa los avisos para ver misiones y marcadores a 20 metros mientras esta pestaña esté visible. Al cerrar la pestaña se detiene el seguimiento.',
          ),
        ),
        if (!supported || controller == null)
          Text(
            AppLocalizations.tr(
              'Este navegador necesita una conexión segura y acceso a la ubicación para activar los avisos.',
            ),
          )
        else
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final error = controller.error;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        AppLocalizations.tr(
                          error is DeviceLocationFailure
                              ? error.message
                              : 'No pudimos obtener tu ubicación. Revisa los permisos del sitio y vuelve a intentarlo.',
                        ),
                      ),
                    ),
                  if (controller.running)
                    Text(
                      AppLocalizations.tr('Avisos activos en esta pestaña.'),
                    ),
                  if (!controller.running)
                    FilledButton(
                      onPressed:
                          controller.starting || account != controller.accountId
                          ? null
                          : () => controller.start(accountId: account),
                      child: Text(AppLocalizations.tr('Activar avisos')),
                    ),
                  if (controller.enabled)
                    OutlinedButton(
                      onPressed: controller.stop,
                      child: Text(AppLocalizations.tr('Detener avisos')),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
