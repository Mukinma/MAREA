import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:uuid/uuid.dart';

class StoryComposer extends StatefulWidget {
  const StoryComposer({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<StoryComposer> {
  final _text = TextEditingController();
  String _id = const Uuid().v4();
  Uint8List? _image;
  String? _path, _error;
  bool _busy = false;
  StoryInput? _submitted;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await ProfileImagePicker.pick(avatar: false);
      if (!mounted || image == null) return;
      setState(() {
        _image = image;
        _id = const Uuid().v4();
        _path = null;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    }
  }

  Future<void> _publish() async {
    final repo = widget.controller.storiesRepository;
    if (repo == null) {
      setState(() => _error = 'Las historias todavía no están disponibles.');
      return;
    }
    if (_image == null && _text.text.trim().isEmpty) {
      setState(() => _error = 'Escribe algo o añade una foto.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_image != null && _path == null) {
        _path = await repo.upload(_id, _image!);
      }
      final input = StoryInput(id: _id, text: _text.text, imagePath: _path);
      final validation = input.validate();
      if (validation != null) {
        setState(() => _error = validation);
        return;
      }
      _submitted ??= input;
      await repo.publish(_submitted!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Crear historia')),
      body: CommunityPage(
        title: '',
        children: [
          const Text(
            'Tu historia estará disponible durante 24 horas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_image!, height: 300, fit: BoxFit.contain),
            ),
            TextButton(
              onPressed: _busy || _submitted != null
                  ? null
                  : () => setState(() {
                      _image = null;
                      _path = null;
                      _id = const Uuid().v4();
                    }),
              child: const Text('Quitar foto'),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _busy || _submitted != null ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_image == null ? 'Añadir foto' : 'Cambiar foto'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            enabled: !_busy && _submitted == null,
            maxLength: 500,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '¿Qué quieres compartir?',
              hintText: 'Escribe tu historia',
            ),
          ),
          if (_error != null) CommunityNotice(message: _error!),
          if (_submitted != null && !_busy)
            const Text(
              'Reintenta para confirmar la publicación. Se conservará el contenido enviado.',
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _publish,
            child: Text(_busy ? 'Publicando…' : 'Publicar historia'),
          ),
        ],
      ),
    ),
  );
}
