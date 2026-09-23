import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';

void main() {
  test('refresh scrolling accepts touch and mouse dragging', () {
    final devices = MareaRefreshScrollBehavior().dragDevices;

    expect(devices, contains(PointerDeviceKind.touch));
    expect(devices, contains(PointerDeviceKind.mouse));
    expect(devices, contains(PointerDeviceKind.trackpad));
  });
}
