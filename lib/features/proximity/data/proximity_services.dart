import '../models/proximity_models.dart';

abstract interface class ProximityLocationSource {
  /// Only an explicit start action may pass requestPermission: true.
  Future<void> prepare({
    required bool requestPermission,
    required bool Function() isCurrent,
  });

  Stream<ProximityFix> watch();
}

abstract interface class ProximityTargetSource {
  /// Implementations must return only targets visible to the current account.
  Future<List<ProximityTarget>> load(ProximityFix fix);
}

abstract interface class ProximityNotificationSink {
  Future<void> present(
    ProximityEncounter encounter, {
    required String accountId,
    required bool Function() isCurrent,
  });

  Future<void> clearAccount(String accountId);
}
