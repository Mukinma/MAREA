// Isolated Android service probe. No Supabase, authentication or production data.
// Never include this target in a release build.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/proximity/data/native_proximity_bridge.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

void main() {
  if (!kDebugMode) throw UnsupportedError('QA target requires debug mode');
  runApp(const MaterialApp(home: ProximityProbe()));
}

class ProximityProbe extends StatefulWidget {
  const ProximityProbe({super.key});
  @override
  State<ProximityProbe> createState() => _ProximityProbeState();
}

class _ProximityProbeState extends State<ProximityProbe> {
  static const account = '11111111-1111-4111-8111-111111111111';
  static const mission = '22222222-2222-4222-8222-222222222222';
  static const marker = '33333333-3333-4333-8333-333333333333';
  final bridge = NativeProximityBridge.instance;
  StreamSubscription<String>? opened;
  String message =
      'Sólo QA: dos lugares de prueba en 0°, 0°. Sin conexión a Supabase.';

  @override
  void initState() {
    super.initState();
    opened = bridge.opened.listen((payload) {
      if (mounted) setState(() => message = 'Notificación abierta: $payload');
    });
  }

  Future<void> start() async {
    try {
      await bridge.bindAccount(account);
      await bridge.requestNotifications();
      await bridge.configure(account, [
        for (final kind in ProximityTargetKind.values)
          ProximityTarget(
            id: kind == ProximityTargetKind.mission ? mission : marker,
            title: kind == ProximityTargetKind.mission
                ? 'Misión QA'
                : 'Marcador QA',
            route: kind == ProximityTargetKind.mission
                ? '/missions/$mission'
                : '/ar-markers/$marker/scan',
            latitude: 0,
            longitude: 0,
            exact: true,
            kind: kind,
          ),
      ], start: true);
      final status = await bridge.status();
      if (mounted) setState(() => message = 'Servicio iniciado: $status');
    } catch (error) {
      if (mounted) {
        setState(() => message = 'Revisa permisos en Ajustes: $error');
      }
    }
  }

  @override
  void dispose() {
    unawaited(opened?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos QA aislados')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message),
          FilledButton(onPressed: start, child: const Text('Iniciar prueba')),
          TextButton(
            onPressed: () => bridge.stop(forget: true),
            child: const Text('Detener y borrar prueba'),
          ),
        ],
      ),
    ),
  );
}
