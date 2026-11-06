import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/home_feed/presentation/story_camera_screen.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:uuid/uuid.dart';

class StoryComposer extends StatefulWidget {
  const StoryComposer({
    required this.controller,
    this.autoOpenCamera = false,
    super.key,
  });
  final AppSessionController controller;
  final bool autoOpenCamera;

  @override
  State<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<StoryComposer> {
  Uint8List? _image;
  String? _path;
  String? _error;
  bool _busy = false;
  String _category = 'otros';
  UserType? _targetType;
  late String _id;
  StoryInput? _submitted;
  final _editorKey = GlobalKey();
  final _strokes = <_StoryStroke>[];
  final _textOverlays = <_StoryTextOverlay>[];
  bool _drawing = false;
  Color _drawingColor = Colors.white;
  double _drawingWidth = 5;

  @override
  void initState() {
    super.initState();
    _id = const Uuid().v4();
    if (widget.autoOpenCamera && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openCamera() async {
    final image = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const StoryCameraScreen()),
    );
    if (!mounted || image == null) return;
    setState(() {
      _image = image;
      _path = null;
      _error = null;
      _id = const Uuid().v4();
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (!mounted || file == null) return;
      final image = await ProfileImagePicker.prepare(
        await file.readAsBytes(),
        avatar: false,
      );
      setState(() {
        _image = image;
        _path = null;
        _error = null;
        _id = const Uuid().v4();
      });
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    }
  }

  Future<void> _saveEditorImage() async {
    if (_image == null || _strokes.isEmpty && _textOverlays.isEmpty) return;
    await Future<void>.delayed(Duration.zero);
    final boundary =
        _editorKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data != null) _image = data.buffer.asUint8List();
  }

  Future<void> _addTextOverlay() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Añadir texto'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 120,
            decoration: const InputDecoration(hintText: 'Escribe algo...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
    if (!mounted || value == null || value.isEmpty) return;
    setState(() => _textOverlays.add(_StoryTextOverlay(value)));
  }

  Future<void> _showStoryOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: [
                for (final entry in communityCategories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<UserType?>(
              initialValue: _targetType,
              decoration: const InputDecoration(
                labelText: 'Público',
                prefixIcon: Icon(Icons.people_outline),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final type in UserType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.databaseValue),
                  ),
              ],
              onChanged: (value) => setState(() => _targetType = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final repo = widget.controller.storiesRepository;
    if (repo == null) {
      setState(() => _error = 'Las historias todavía no están disponibles.');
      return;
    }
    if (_image == null) {
      setState(() => _error = 'Toma una foto o elige una de tu galería.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _saveEditorImage();
      if (_image != null && _path == null) {
        _path = await repo.upload(_id, _image!);
      }

      final input = StoryInput(
        id: _id,
        text: '',
        imagePath: _path,
        category: _category,
        targetType: _targetType,
      );
      final validation = input.validate();
      if (validation != null) {
        setState(() => _error = validation);
        return;
      }
      _submitted ??= input;
      await repo.publish(_submitted!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_image == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toma una foto o elige una de tu galería.',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _toolButton(
                          Icons.photo_library_outlined,
                          _pickFromGallery,
                        ),
                        const SizedBox(width: 16),
                        _toolButton(Icons.camera_alt_outlined, _openCamera),
                      ],
                    ),
                  ],
                ),
              )
            else
              RepaintBoundary(
                key: _editorKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: Image.memory(_image!, fit: BoxFit.contain),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StoryDrawingPainter(_strokes),
                      ),
                    ),
                    for (final overlay in _textOverlays)
                      Positioned(
                        left: overlay.position.dx,
                        top: overlay.position.dy,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: (_) {
                            overlay.startPosition = overlay.position;
                            overlay.startScale = overlay.scale;
                          },
                          onScaleUpdate: (details) {
                            final size = MediaQuery.sizeOf(context);
                            setState(() {
                              if (details.pointerCount == 1) {
                                overlay.position = Offset(
                                  (overlay.position.dx +
                                          details.focalPointDelta.dx)
                                      .clamp(0, size.width - 80),
                                  (overlay.position.dy +
                                          details.focalPointDelta.dy)
                                      .clamp(0, size.height - 80),
                                );
                              }
                              overlay.scale =
                                  (overlay.startScale * details.scale).clamp(
                                    .6,
                                    4,
                                  );
                            });
                          },
                          child: SizedBox(
                            width: 240,
                            height: 120,
                            child: Transform.scale(
                              scale: overlay.scale,
                              alignment: Alignment.topLeft,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    overlay.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      shadows: [Shadow(blurRadius: 5)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_drawing)
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: (details) => setState(
                            () => _strokes.add(
                              _StoryStroke(
                                points: [details.localPosition],
                                color: _drawingColor,
                                width: _drawingWidth,
                              ),
                            ),
                          ),
                          onPanUpdate: (details) => setState(
                            () =>
                                _strokes.last.points.add(details.localPosition),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: _toolButton(Icons.close, () => Navigator.pop(context)),
            ),
            if (_image != null)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _toolButton(
                      Icons.text_fields,
                      _addTextOverlay,
                      label: 'Texto',
                    ),
                    _toolButton(
                      Icons.edit,
                      () => setState(() => _drawing = !_drawing),
                      label: 'Dibujar',
                      active: _drawing,
                    ),
                    _toolButton(
                      Icons.tune,
                      _showStoryOptions,
                      label: 'Opciones',
                    ),
                  ],
                ),
              ),
            if (_image != null)
              Positioned(
                top: 12,
                right: 76,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _drawing
                      ? _drawingControls()
                      : const SizedBox.shrink(),
                ),
              ),
            if (_image != null)
              Positioned(
                right: 16,
                bottom: 18,
                child: FloatingActionButton(
                  onPressed: _busy ? null : _publish,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.arrow_forward),
                ),
              ),
            if (_error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 82,
                child: Material(
                  color: Colors.black87,
                  child: CommunityNotice(message: _error!),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _drawingControls() => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in [
                Colors.white,
                Colors.black,
                Colors.red,
                Colors.yellow,
                Colors.cyan,
                Colors.green,
              ])
                GestureDetector(
                  onTap: () => setState(() => _drawingColor = color),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _drawingColor == color
                            ? AppColors.aqua
                            : Colors.white54,
                        width: _drawingColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 150,
            child: Slider(
              value: _drawingWidth,
              min: 2,
              max: 18,
              onChanged: (value) => setState(() => _drawingWidth = value),
              activeColor: AppColors.aqua,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _toolButton(
    IconData icon,
    VoidCallback onPressed, {
    String? label,
    bool active = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? AppColors.aqua : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _busy ? null : onPressed,
            icon: Icon(
              icon,
              color: active ? AppColors.brandNavy : Colors.white,
            ),
            tooltip: label,
          ),
        ),
      ),
    ),
  );
}

class _StoryTextOverlay {
  _StoryTextOverlay(this.text) : position = const Offset(80, 180);
  final String text;
  Offset position;
  double scale = 1;
  Offset startPosition = const Offset(80, 180);
  double startScale = 1;
}

class _StoryStroke {
  _StoryStroke({
    required this.points,
    required this.color,
    required this.width,
  });
  final List<Offset> points;
  final Color color;
  final double width;
}

class _StoryDrawingPainter extends CustomPainter {
  const _StoryDrawingPainter(this.strokes);
  final List<_StoryStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < stroke.points.length; i++) {
        canvas.drawLine(stroke.points[i - 1], stroke.points[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StoryDrawingPainter oldDelegate) => true;
}
