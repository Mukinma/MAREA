import 'dart:async';
import 'package:marea/features/notifications/models/notification_destination.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/core/localization/app_locale_controller.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/l10n/app_localizations.dart' as generated_l10n;

class MareaApp extends StatefulWidget {
  const MareaApp({
    required this.controller,
    this.localeController,
    this.development = false,
    this.productionPilot = false,
    super.key,
  });
  final AppSessionController controller;
  final AppLocaleController? localeController;
  final bool development;
  final bool productionPilot;

  @override
  State<MareaApp> createState() => _MareaAppState();
}

class _MareaAppState extends State<MareaApp> {
  late final AppLocaleController _localeController =
      widget.localeController ?? AppLocaleController();
  late final _router = AppRouter.create(widget.controller);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sessionChanged);
    widget.controller.push?.addListener(_pushChanged);
    _localeController.addListener(_localeChanged);
    unawaited(_localeController.load());
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
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).notificationUnavailable,
                ),
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
    widget.controller.removeListener(_sessionChanged);
    widget.controller.push?.removeListener(_pushChanged);
    _localeController.removeListener(_localeChanged);
    _localeController.dispose();
    _router.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  void _localeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: ValueKey(_localeController.locale.toLanguageTag()),
      title: widget.productionPilot
          ? 'MAREA · Prueba RA'
          : widget.development
          ? 'MAREA Desarrollo'
          : 'MAREA',
      locale: _localeController.locale,
      supportedLocales: AppLocaleController.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...generated_l10n.AppLocalizations.localizationsDelegates,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('es', 'MX');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('es', 'MX');
      },
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        if (widget.development || widget.productionPilot) {
          content = Banner(
            message: widget.productionPilot ? 'PRUEBA RA' : 'DESARROLLO',
            location: BannerLocation.topEnd,
            color: Colors.deepOrange,
            child: content,
          );
        }
        return AppLocaleScope(controller: _localeController, child: content);
      },
    );
  }
}
