import 'dart:async';
import 'package:marea/features/notifications/models/notification_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/features/proximity/data/app_proximity_targets.dart';
import 'package:marea/features/proximity/data/native_proximity_bridge.dart';
import 'package:marea/features/proximity/data/local_proximity_notifications.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

class MareaApp extends StatefulWidget {
  const MareaApp({
    required this.controller,
    this.development = false,
    this.productionPilot = false,
    super.key,
  });
  final AppSessionController controller;
  final bool development;
  final bool productionPilot;

  @override
  State<MareaApp> createState() => _MareaAppState();
}

class _MareaAppState extends State<MareaApp> with WidgetsBindingObserver {
  late final _router = AppRouter.create(widget.controller);
  StreamSubscription<String>? _proximityOpened;
  Timer? _proximityTimer;
  String? _proximityAccount;
  bool _proximityBound = false, _refreshingProximity = false;
  int _markerRevision = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sessionChanged);
    widget.controller.push?.addListener(_pushChanged);
    if (widget.controller.markerRepository != null) {
      WidgetsBinding.instance.addObserver(this);
      _proximityOpened = NativeProximityBridge.instance.opened.listen(
        (_) => _openProximity(),
      );
      _proximityTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshProximity(),
      );
      _router.routeInformationProvider.addListener(_refreshProximity);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
    });
  }

  void _sessionChanged() {
    final c = widget.controller;
    unawaited(
      c.push?.setSession(
        c.profile?.id,
        ready:
            c.status == AuthStatus.authenticated &&
            !c.needsOnboarding &&
            !c.needsLegalAcceptance &&
            !c.isRecovering,
      ),
    );
    _pushChanged();
    _syncProximity();
  }

  bool get _readyForProximity =>
      widget.controller.status == AuthStatus.authenticated &&
      widget.controller.profile != null &&
      !widget.controller.needsOnboarding &&
      !widget.controller.needsLegalAcceptance &&
      !widget.controller.isRecovering;

  Future<void> _syncProximity() async {
    final c = widget.controller;
    if (c.markerRepository == null || c.status == AuthStatus.initializing) {
      return;
    }
    final account = _readyForProximity ? c.profile?.id : null;
    if (!_proximityBound || account != _proximityAccount) {
      _proximityBound = true;
      _proximityAccount = account;
      try {
        await NativeProximityBridge.instance.bindAccount(
          account,
          foreground:
              WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed,
        );
      } catch (_) {}
      if (!mounted || account != _proximityAccount) return;
      await _openProximity();
      unawaited(_refreshProximity());
    }
    if (_markerRevision != c.markerRevision) {
      _markerRevision = c.markerRevision;
      unawaited(_refreshProximity());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.controller.markerRepository != null && _readyForProximity) {
        unawaited(
          NativeProximityBridge.instance
              .bindAccount(widget.controller.profile?.id, foreground: true)
              .catchError((Object _) {}),
        );
      }
      unawaited(_syncProximity());
      unawaited(_refreshProximity());
    }
    // The native location service owns background monitoring. Camera screens
    // independently release their cameras when the app leaves the foreground.
  }

  Future<void> _refreshProximity() async {
    if (!mounted ||
        !_readyForProximity ||
        _refreshingProximity ||
        widget.controller.markerRepository == null ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final account = widget.controller.profile!.id;
    _refreshingProximity = true;
    bool current() =>
        mounted &&
        _readyForProximity &&
        widget.controller.profile?.id == account;
    try {
      final bridge = NativeProximityBridge.instance;
      final state = await bridge.status();
      if (!current() ||
          state['enabled'] != true ||
          state['accountId'] != account) {
        return;
      }
      final fix = await const GeolocatorDeviceLocationService().current(
        isCurrent: current,
      );
      if (!current()) return;
      final targets = await AppProximityTargets(widget.controller).load(
        ProximityFix(
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          timestamp: DateTime.now(),
        ),
      );
      if (current()) await bridge.configure(account, targets, start: false);
    } catch (_) {
      // Keep the last downloaded places when offline; do not invent locations.
    } finally {
      _refreshingProximity = false;
    }
  }

  Future<void> _openProximity() async {
    if (!mounted || !_readyForProximity) return;
    final account = widget.controller.profile!.id;
    String? raw;
    try {
      raw = await NativeProximityBridge.instance.takePending();
    } catch (_) {
      return;
    }
    if (!mounted ||
        !_readyForProximity ||
        widget.controller.profile?.id != account) {
      return;
    }
    final notice = ProximityNotificationPayload.parse(
      raw,
      currentAccountId: account,
    );
    if (notice != null) unawaited(_router.push(notice.route));
  }

  bool _openingPush = false;
  void _pushChanged() {
    if (!mounted || _openingPush) return;
    final c = widget.controller;
    if (c.profile == null ||
        c.status != AuthStatus.authenticated ||
        c.needsOnboarding ||
        c.needsLegalAcceptance ||
        c.isRecovering) {
      return;
    }
    final notice = c.push?.takePending(c.profile!.id);
    if (notice == null) return;
    _openingPush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = c.profile?.id;
      try {
        final notification = await c.push!.repository.notification(
          notice.notificationId,
        );
        if (!mounted || user != c.profile?.id || user != notice.recipientId) {
          return;
        }
        if (notification == null) {
          _router.go('/home');
          final context = _router.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Esta notificación ya no está disponible.'),
              ),
            );
          }
          return;
        }
        try {
          await c.socialRepository?.markRead(id: notification.id);
        } catch (_) {}
        if (!mounted || user != c.profile?.id) return;
        await c.notifications?.refresh();
        if (!mounted || user != c.profile?.id) return;
        unawaited(_router.push(notificationDestination(notification)));
      } catch (_) {
        // The inbox provides a retry without trusting a URL from the push payload.
        if (mounted && user == c.profile?.id) _router.go('/home');
      } finally {
        _openingPush = false;
        if (mounted) _pushChanged();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proximityTimer?.cancel();
    unawaited(_proximityOpened?.cancel());
    _router.routeInformationProvider.removeListener(_refreshProximity);
    widget.controller.removeListener(_sessionChanged);
    widget.controller.push?.removeListener(_pushChanged);
    _router.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.productionPilot
          ? 'MAREA · Prueba RA'
          : widget.development
          ? 'MAREA Desarrollo'
          : 'MAREA',
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: widget.development || widget.productionPilot
          ? (context, child) => Banner(
              message: widget.productionPilot ? 'PRUEBA RA' : 'DESARROLLO',
              location: BannerLocation.topEnd,
              color: Colors.deepOrange,
              child: child ?? const SizedBox.shrink(),
            )
          : null,
    );
  }
}
