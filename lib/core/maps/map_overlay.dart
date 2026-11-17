import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Intercept only actual controls, never the full-screen transparent layout.
class MapOverlay extends StatelessWidget {
  const MapOverlay({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      PointerInterceptor(intercepting: kIsWeb, child: child);
}
