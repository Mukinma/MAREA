// Manual browser regression harness; no account, backend or production route.
// flutter run -d web-server -t test/browser/image_picker_probe.dart --web-port 7361
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.ensureSemantics();
  runApp(const MaterialApp(home: _Probe()));
}

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  Uint8List? bytes;
  String result = 'Selecciona una imagen';
  Future<void> pick(bool avatar) async {
    try {
      final value = await ProfileImagePicker.pick(avatar: avatar);
      if (!mounted) return;
      setState(() {
        bytes = value;
        result = value == null
            ? 'Cancelado'
            : 'Imagen preparada: ${value.length} bytes';
      });
    } catch (error) {
      if (mounted) setState(() => result = 'Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          FilledButton(
            onPressed: () => pick(true),
            child: const Text('Foto de perfil'),
          ),
          FilledButton(
            onPressed: () => pick(false),
            child: const Text('Foto de publicación'),
          ),
          Text(result),
          if (bytes != null) Expanded(child: Image.memory(bytes!)),
        ],
      ),
    ),
  );
}
