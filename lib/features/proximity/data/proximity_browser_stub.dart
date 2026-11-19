bool get browserLocationSupported => false;
bool get proximityPageVisible => false;

Future<bool> claimBrowserAlert(
  String account,
  String target,
  DateTime now,
) async => true;
void clearBrowserAlerts(String account) {}
