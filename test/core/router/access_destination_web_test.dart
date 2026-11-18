import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/access_destination_store.dart'
    if (dart.library.js_interop) 'package:marea/core/router/access_destination_store_web.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';

void main() {
  test(
    'web restores a protected destination after leaving the app for Google',
    () {
      writeAccessDestination(null);
      addTearDown(() => writeAccessDestination(null));
      final destination = Uri.parse('/missions/mission-1?from=map');
      final beforeGoogle = AppRouteGuard(persistDestination: true);
      expect(
        Uri.parse(
          beforeGoogle.redirectFor(AuthStatus.unauthenticated, destination)!,
        ).path,
        '/login',
      );

      final afterGoogle = AppRouteGuard(persistDestination: true);
      expect(
        afterGoogle.redirectFor(AuthStatus.authenticated, Uri.parse('/')),
        destination.toString(),
      );
      expect(readAccessDestination(), isNull);
    },
    skip: !kIsWeb,
  );
}
