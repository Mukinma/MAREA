import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/proximity_controller.dart';
import '../data/local_proximity_notifications.dart';
import '../data/proximity_browser.dart';
import '../data/proximity_services.dart';
import '../models/proximity_models.dart';

class ForegroundProximityScope extends InheritedWidget {
  const ForegroundProximityScope({
    required this.controller,
    required super.child,
    super.key,
  });
  final ProximityController controller;

  static ProximityController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ForegroundProximityScope>()
      ?.controller;

  @override
  bool updateShouldNotify(ForegroundProximityScope oldWidget) =>
      controller != oldWidget.controller;
}

typedef ForegroundNotice = ({
  String title,
  ProximityNotificationPayload payload,
});

class ForegroundProximityNotices extends ChangeNotifier
    implements ProximityNotificationSink {
  ForegroundProximityNotices({this.claim = claimBrowserAlert});
  final Future<bool> Function(String, String, DateTime) claim;
  final _queue = <ForegroundNotice>[];
  ForegroundNotice? get current => _queue.firstOrNull;

  @override
  Future<void> present(
    ProximityEncounter encounter, {
    required String accountId,
    required bool Function() isCurrent,
  }) async {
    final target = encounter.target;
    final payload = ProximityNotificationPayload(
      recipientId: accountId,
      targetId: target.id,
      kind: target.kind,
      route: target.route,
    );
    if (!isCurrent() || !target.isValid || !payload.isValid) return;
    if (!await claim(accountId, target.key, encounter.occurredAt) ||
        !isCurrent())
      return;
    _queue.add((title: target.title, payload: payload));
    notifyListeners();
  }

  void dismiss() {
    if (_queue.isEmpty) return;
    _queue.removeAt(0);
    notifyListeners();
  }

  void clear() {
    if (_queue.isEmpty) return;
    _queue.clear();
    notifyListeners();
  }

  @override
  Future<void> clearAccount(String accountId) async {
    clearBrowserAlerts(accountId);
    _queue.removeWhere((notice) => notice.payload.recipientId == accountId);
    notifyListeners();
  }
}

class ForegroundProximityBanner extends StatelessWidget {
  const ForegroundProximityBanner({
    required this.notices,
    required this.open,
    super.key,
  });
  final ForegroundProximityNotices notices;
  final void Function(ProximityNotificationPayload) open;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: notices,
    builder: (context, _) {
      final notice = notices.current;
      if (notice == null) return const SizedBox.shrink();
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          '${AppLocalizations.tr('A 20 metros o menos')} · ${notice.title}',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        notices.dismiss();
                        open(notice.payload);
                      },
                      child: Text(
                        AppLocalizations.tr(
                          notice.payload.kind == ProximityTargetKind.mission
                              ? 'Ver misión'
                              : 'Ver marcador',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.tr('Cerrar'),
                      onPressed: notices.dismiss,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
