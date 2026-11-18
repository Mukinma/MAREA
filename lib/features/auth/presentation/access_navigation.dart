import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AccessNavigation on BuildContext {
  void goWithAccessEmail(String path, {required String? email}) {
    final returnTo = GoRouterState.of(this).uri.queryParameters['returnTo'];
    // A router redirect would otherwise replace the match and discard extra.
    final location = Uri(
      path: path,
      queryParameters: returnTo == null ? null : {'returnTo': returnTo},
    );
    go(location.toString(), extra: email);
  }
}
