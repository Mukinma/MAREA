import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';

/// The same source rectangle is used for the preview and exported photograph.
Rect coverPhotoRect(Size image, double zoom, Offset position) {
  final width = math.min(image.width, image.height * 2) / zoom;
  final height = width / 2;
  return Rect.fromLTWH(
    (position.dx * image.width - width / 2).clamp(0.0, image.width - width),
    (position.dy * image.height - height / 2).clamp(0.0, image.height - height),
    width,
    height,
  );
}

class CoverPhotoEditor extends StatefulWidget {
  const CoverPhotoEditor({
    required this.bytes,
    required this.waveColors,
    super.key,
  });
  final Uint8List bytes;
  final List<int> waveColors;

  @override
  State<CoverPhotoEditor> createState() => _CoverPhotoEditorState();
}

class _CoverPhotoEditorState extends State<CoverPhotoEditor> {
  ui.Image? _image;
  double _zoom = 1, _startZoom = 1;
  Offset _position = const Offset(.5, .5),
      _startPosition = const Offset(.5, .5),
      _startFocal = Offset.zero;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      try {
        final image = (await codec.getNextFrame()).image;
        if (!mounted) {
          image.dispose();
          return;
        }
        setState(() => _image = image);
      } finally {
        codec.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos abrir esta imagen. Prueba con otra fotografía.',
        );
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Rect get _rect => coverPhotoRect(
    Size(_image!.width.toDouble(), _image!.height.toDouble()),
    _zoom,
    _position,
  );

  Future<void> _usePhoto() async {
    if (_image == null || _exporting) return;
    setState(() {
      _exporting = true;
      _error = null;
    });
    ui.Picture? picture;
    ui.Image? cropped;
    try {
      final rect = _rect;
      final width = (math.min(1600, rect.width.floor()).clamp(2, 1600) ~/ 2) * 2;
      final height = width ~/ 2;
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        _image!,
        rect,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      // Only the photograph is exported. The waves belong to the UI overlay.
      picture = recorder.endRecording();
      cropped = await picture.toImage(width, height);
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const AppFailure('No pudimos preparar tu portada.');
      }
      final bytes = await ProfileImagePicker.prepare(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        avatar: false,
      );
      if (mounted) Navigator.pop(context, bytes);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppFailure
              ? error.message
              : 'No pudimos preparar tu portada. Prueba otra fotografía.',
        );
      }
    } finally {
      cropped?.dispose();
      picture?.dispose();
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajustar foto de portada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arrastra la foto para encuadrarla. Pellizca o usa los botones para acercarla.',
          ),
          const SizedBox(height: 16),
          if (_image == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_image != null)
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                key: const Key('cover-photo-crop'),
                onScaleStart: (details) {
                  _startZoom = _zoom;
                  final rect = _rect;
                  _startPosition = Offset(
                    rect.center.dx / _image!.width,
                    rect.center.dy / _image!.height,
                  );
                  _startFocal = details.localFocalPoint;
                },
                onScaleUpdate: (details) {
                  final zoom = (_startZoom * details.scale).clamp(1.0, 4.0);
                  final source = coverPhotoRect(
                    Size(_image!.width.toDouble(), _image!.height.toDouble()),
                    zoom,
                    _startPosition,
                  );
                  final delta = details.localFocalPoint - _startFocal;
                  setState(() {
                    _zoom = zoom;
                    _position = Offset(
                      (_startPosition.dx -
                              delta.dx *
                                  source.width /
                                  constraints.maxWidth /
                                  _image!.width)
                          .clamp(0.0, 1.0),
                      (_startPosition.dy -
                              delta.dy *
                                  source.height /
                                  (constraints.maxWidth / 2) /
                                  _image!.height)
                          .clamp(0.0, 1.0),
                    );
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _CoverPhotoPainter(_image!, _rect),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: constraints.maxWidth * .32,
                          child: ProfileWaves(colors: widget.waveColors),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Alejar foto',
                onPressed: _image == null || _exporting || _zoom <= 1
                    ? null
                    : () =>
                          setState(() => _zoom = (_zoom - .25).clamp(1.0, 4.0)),
                icon: const Icon(Icons.remove),
              ),
              TextButton(
                onPressed: _exporting
                    ? null
                    : () => setState(() {
                        _zoom = 1;
                        _position = const Offset(.5, .5);
                      }),
                child: const Text('Restablecer encuadre'),
              ),
              IconButton(
                tooltip: 'Acercar foto',
                onPressed: _image == null || _exporting || _zoom >= 4
                    ? null
                    : () =>
                          setState(() => _zoom = (_zoom + .25).clamp(1.0, 4.0)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _image == null || _exporting ? null : _usePhoto,
            child: Text(_exporting ? 'Preparando foto…' : 'Usar foto'),
          ),
          TextButton(
            onPressed: _exporting ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

class _CoverPhotoPainter extends CustomPainter {
  const _CoverPhotoPainter(this.image, this.source);
  final ui.Image image;
  final Rect source;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    source,
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.high,
  );
  @override
  bool shouldRepaint(_CoverPhotoPainter oldDelegate) =>
      image != oldDelegate.image || source != oldDelegate.source;
}
