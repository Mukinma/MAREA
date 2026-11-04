// Real backend and application, for the explicitly authorized production pilot.
// Accounts and content must be new, tracked pilot resources. No embedded session.
import 'package:marea/main.dart' as application;

Future<void> main() => application.startMarea(productionPilot: true);
