import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_theme.dart';

Widget testApp(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: child);
}
