import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/tour_local_store.dart';
import '../presentation/tour_widgets.dart';

/// Keeps the reference loaded while orientation events rebuild the capture UI.
class CaptureResumePhoto extends StatefulWidget {
  const CaptureResumePhoto({
    required this.store,
    required this.path,
    this.livePreview,
    this.aspectRatio = 9 / 16,
    this.onAlign,
    this.busy = false,
    this.counterLabel,
    super.key,
  });

  final TourLocalStore store;
  final String path;
  final Widget? livePreview;
  final double aspectRatio;
  final VoidCallback? onAlign;
  final bool busy;
  final String? counterLabel;

  @override
  State<CaptureResumePhoto> createState() => _CaptureResumePhotoState();
}

class _CaptureResumePhotoState extends State<CaptureResumePhoto> {
  late Future<Uint8List> _photo = widget.store.readBytes(widget.path);

  @override
  void didUpdateWidget(CaptureResumePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.store != widget.store) {
      _photo = widget.store.readBytes(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = FutureBuilder<Uint8List>(
      key: ObjectKey(_photo),
      future: _photo,
      builder: (context, snapshot) {
        if (widget.livePreview != null) return _alignment(snapshot);
        return _reference(snapshot);
      },
    );
    return widget.livePreview == null
        ? SizedBox(height: 160, width: double.infinity, child: photo)
        : photo;
  }

  Widget _reference(AsyncSnapshot<Uint8List> snapshot) {
    if (snapshot.hasError) {
      return TourNotice(
        'No pudimos abrir la foto guía.',
        onRetry: () => setState(() {
          _photo = widget.store.readBytes(widget.path);
        }),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return RepaintBoundary(
      child: Image.memory(
        key: const ValueKey('capture-resume-reference'),
        snapshot.data!,
        cacheWidth: 768,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        semanticLabel: 'Primera toma para retomar la captura',
      ),
    );
  }

  Widget _alignment(AsyncSnapshot<Uint8List> snapshot) {
    final ready =
        snapshot.connectionState == ConnectionState.done &&
        snapshot.hasData &&
        !snapshot.hasError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.hasError
                        ? 'No pudimos abrir la foto guía.'
                        : 'Vuelve al mismo punto y encuadra como en la foto superpuesta.',
                  ),
                  if (widget.counterLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.counterLabel!,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.livePreview!,
                      if (ready)
                        IgnorePointer(
                          child: Opacity(
                            opacity: .42,
                            child: _reference(snapshot),
                          ),
                        )
                      else if (!snapshot.hasError)
                        ColoredBox(
                          color: Colors.black54,
                          child: _reference(snapshot),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Foto guía sobre cámara en vivo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.busy
                ? null
                : snapshot.hasError
                ? () => setState(() {
                    _photo = widget.store.readBytes(widget.path);
                  })
                : ready
                ? widget.onAlign
                : null,
            child: Text(
              snapshot.hasError ? 'Reintentar' : 'Continuar con este encuadre',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
