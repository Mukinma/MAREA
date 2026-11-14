import 'dart:async';

import 'package:flutter/services.dart';

import '../models/proximity_models.dart';

class NativeProximityBridge {
  NativeProximityBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('marea/proximity_background') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened' && call.arguments is String) {
        _pending = call.arguments as String;
        _opened.add(_pending!);
      }
    });
  }
  static final instance = NativeProximityBridge();
  final MethodChannel _channel;
  final _opened = StreamController<String>.broadcast();
  String? _pending;
  Stream<String> get opened => _opened.stream;

  Future<Map<String, dynamic>> status() async {
    try {
      return Map<String, dynamic>.from(
        await _channel.invokeMapMethod<String, dynamic>('status') ?? {},
      );
    } on MissingPluginException {
      return {'supported': false, 'enabled': false};
    }
  }

  Future<void> bindAccount(String? account, {bool foreground = false}) async {
    try {
      await _channel.invokeMethod<void>('bindAccount', {
        'accountId': account,
        'foreground': foreground,
      });
    } on MissingPluginException {
      /* Background service is Android-only. */
    }
  }

  Future<void> requestNotifications() =>
      _channel.invokeMethod<void>('requestNotifications');
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');
  Future<void> stop({bool forget = false}) =>
      _channel.invokeMethod<void>('stop', {'forget': forget});
  Future<void> configure(
    String account,
    List<ProximityTarget> targets, {
    required bool start,
  }) async {
    await _channel.invokeMethod<void>(start ? 'start' : 'updateTargets', {
      'accountId': account,
      'targets': [
        for (final target in targets)
          if (target.isValid)
            {
              'id': target.id,
              'title': target.title.length <= 120
                  ? target.title
                  : target.title.substring(0, 120),
              'route': target.route,
              'latitude': target.latitude,
              'longitude': target.longitude,
              'exact': target.exact,
              if (target.expiresAt != null)
                'expiresAt': target.expiresAt!.millisecondsSinceEpoch,
            },
      ],
    });
  }

  Future<String?> takePending() async {
    final pending = _pending;
    _pending = null;
    if (pending != null) return pending;
    try {
      return await _channel.invokeMethod<String>('takeLaunchPayload');
    } on MissingPluginException {
      return null;
    }
  }
}
