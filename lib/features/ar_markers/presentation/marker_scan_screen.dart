import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../tours/models/business_ar_target.dart';
import '../../tours/presentation/tour_widgets.dart';
import '../application/marker_scan_controller.dart';
import '../data/marker_repository.dart';
import '../models/ar_marker.dart';

class MarkerScanScreen extends StatefulWidget {
  const MarkerScanScreen({
    required this.controller,
    required this.repository,
    required this.markerId,
    this.cameraBuilder,
    this.scanController,
    super.key,
  });
  final AppSessionController controller;
  final MarkerRepository repository;
  final String markerId;
  final Widget Function(Map<String, dynamic>)? cameraBuilder;
  final MarkerScanController? scanController;
  @override
  State<MarkerScanScreen> createState() => _MarkerScanScreenState();
}

class _MarkerScanScreenState extends State<MarkerScanScreen>
    with WidgetsBindingObserver {
  late final String _account = widget.controller.profile?.id ?? '';
  late final MarkerScanController _scan =
      widget.scanController ??
      MarkerScanController(
        repository: widget.repository,
        accountId: _account,
        markerId: widget.markerId,
        currentAccount: () => widget.controller.profile?.id,
      );
  bool get _current => mounted && widget.controller.profile?.id == _account;
  String? _reportedReference;
  static const _cardSize = Size(230, 110);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
    _scan.addListener(_changed);
    unawaited(_scan.load());
  }

  void _changed() {
    if (mounted) setState(() {});
    final marker = _scan.marker;
    if (_current &&
        marker?.isTested == true &&
        _reportedReference != marker!.referenceVersion) {
      _reportedReference = marker.referenceVersion;
      widget.controller.markersChanged();
    }
  }

  void _accountChanged() {
    if (!_current) unawaited(_scan.stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_scan.stop());
  }

  Future<void> _content() async {
    final seen = _scan.marker;
    if (!_current || seen == null || _scan.quad == null) return;
    await _scan.stop();
    if (!_current) return;
    try {
      final current = await widget.repository.get(_account, seen.id);
      if (!_current) return;
      if (current == null ||
          current.referenceVersion != seen.referenceVersion) {
        await _scan.load();
        return;
      }
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MarkerContent(marker: current),
      );
    } catch (_) {
      if (_current && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este contenido ya no está disponible.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_accountChanged);
    _scan.removeListener(_changed);
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reconocer marcador'),
      leading: TourBackButton(
        fallback: '/ar-markers',
        onPressed: () async {
          await _scan.stop();
          if (context.mounted) leaveTour(context, '/ar-markers');
        },
      ),
    ),
    body: !_current
        ? const Center(
            child: Text('La sesión cambió. Abre de nuevo tus marcadores.'),
          )
        : _scan.scanning
        ? _camera()
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_scan.loading) const LinearProgressIndicator(),
              if (_scan.error != null)
                TourNotice(_scan.error!, onRetry: _scan.load),
              if (_scan.marker != null) ...[
                Text(
                  _scan.marker!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text('Busca esta imagen y apúntale con la cámara.'),
                if (_scan.image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Image.memory(
                      _scan.image!,
                      height: 260,
                      cacheWidth: 1024,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (_scan.marker!.isLocal)
                  const Text('Marcador guardado en este dispositivo.'),
                if (_scan.marker!.isTested)
                  const Text('Reconocimiento comprobado para esta imagen.'),
                if (!_scan.supported && !_scan.loading)
                  const TourNotice(
                    'Este dispositivo no ofrece reconocimiento RA compatible.',
                  ),
                FilledButton.icon(
                  onPressed: _scan.loading || !_scan.supported
                      ? null
                      : _scan.start,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Abrir cámara'),
                ),
              ],
            ],
          ),
  );
  Widget _camera() => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final transform = arCardTransform(
              _scan.quad,
              constraints.biggest,
              _cardSize,
            );
            final params = <String, dynamic>{
              'references': _scan.references,
              'projectedCard': true,
              'sessionId': _scan.sessionId,
            };
            return ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: widget.cameraBuilder != null
                        ? widget.cameraBuilder!(params)
                        : defaultTargetPlatform == TargetPlatform.android
                        ? AndroidView(
                            key: ValueKey(_scan.sessionId),
                            viewType: 'marea/tour_ar_view',
                            creationParams: params,
                            creationParamsCodec: const StandardMessageCodec(),
                          )
                        : UiKitView(
                            key: ValueKey(_scan.sessionId),
                            viewType: 'marea/tour_ar_view',
                            creationParams: params,
                            creationParamsCodec: const StandardMessageCodec(),
                          ),
                  ),
                  if (transform != null && _scan.marker != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Transform(
                        transform: transform,
                        child: SizedBox.fromSize(
                          size: _cardSize,
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            child: InkWell(
                              onTap: _content,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _scan.marker!.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text('Toca para abrir el menú'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _scan.quad == null
                  ? 'Encuadra la imagen para reconocerla.'
                  : 'Imagen reconocida.',
            ),
            if (_scan.error != null) Text(_scan.error!),
            TextButton(
              onPressed: _scan.stop,
              child: const Text('Cerrar cámara'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MarkerContent extends StatelessWidget {
  const _MarkerContent({required this.marker});
  final ArMarker marker;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(marker.name, style: Theme.of(context).textTheme.headlineSmall),
          if (marker.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(marker.description),
            ),
          if (marker.menuUrl != null)
            FilledButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Abrir menú'),
              onPressed: () async {
                final uri = Uri.tryParse(marker.menuUrl!);
                if (uri == null ||
                    !{'http', 'https'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
                  return;
                }
                try {
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No pudimos abrir el enlace del men\u00fa.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No pudimos abrir el enlace del men\u00fa.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
    ),
  );
}
