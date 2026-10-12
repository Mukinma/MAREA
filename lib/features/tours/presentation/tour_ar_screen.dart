import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marea/core/session/app_session_controller.dart';
import '../data/tour_local_store.dart';
import '../models/tour_models.dart';
import '../data/tour_progress_store.dart';
import 'tour_widgets.dart';
import 'tour_visit_screen.dart';

class TourARScreen extends StatefulWidget {
  const TourARScreen({
    required this.controller,
    required this.tourId,
    this.preview = false,
    this.pointId,
    this.referenceLoader,
    this.localStore,
    super.key,
  });
  final AppSessionController controller;
  final String tourId;
  final bool preview;
  final String? pointId;
  final Future<Uint8List> Function(String)? referenceLoader;
  final TourLocalStore? localStore;
  @override
  State<TourARScreen> createState() => _TourARScreenState();
}

class _TourARScreenState extends State<TourARScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('marea/tour_ar');
  static const _events = EventChannel('marea/tour_ar/events');
  TourRecord? _tour;
  TourProgress? _progress;
  TourProgressStore? _progressStore;
  TourPoint? _point;
  StreamSubscription<dynamic>? _tracking;
  Timer? _timer;
  List<Map<String, dynamic>> _references = [];
  DateTime? _recognizedAt;
  int _scanGeneration = 0;
  final _assetUrls = <String, (DateTime, Future<String>)>{};
  String? _approach;
  bool _supported = false,
      _scanning = false,
      _loading = true,
      _recognized = false,
      _busy = false;
  bool _everRecognized = false, _versionChanged = false;
  String? _error;
  late final String _account = widget.controller.profile?.id ?? '';
  bool get _current => mounted && widget.controller.profile?.id == _account;
  int get _seconds => _recognizedAt == null
      ? 0
      : DateTime.now().difference(_recognizedAt!).inSeconds;
  List<TourPoint> get _points {
    final all =
        _tour?.document.points
            .where(
              (p) =>
                  p.ar != null &&
                  (widget.preview ||
                      p.ar!['tested_version'] == p.ar!['reference_version']),
            )
            .toList() ??
        [];
    final order = jsonList(_tour?.document.data['ar_order']);
    all.sort((a, b) {
      final ai = order.indexOf(a.id), bi = order.indexOf(b.id);
      return (ai < 0 ? 10000 : ai).compareTo(bi < 0 ? 10000 : bi);
    });
    return all;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
    _load();
  }

  void _accountChanged() {
    if (!_current) {
      _stop();
    }
  }

  Future<void> _load() async {
    try {
      final tour = await widget.controller.tourRepository!.get(
        widget.tourId,
        edit: widget.preview,
      );
      if (tour == null) throw StateError('Este recorrido no está disponible.');
      final progress = widget.preview
          ? TourProgress(revisionId: tour.revisionId)
          : await (_progressStore = TourProgressStore(
              account: _account,
              tourId: tour.id,
              revisionId: tour.revisionId,
              read: (widget.localStore ?? TourLocalStore()).read,
              write: (widget.localStore ?? TourLocalStore()).write,
              sync: (save) {
                if (!_current) throw StateError('La sesión cambió.');
                return widget.controller.tourRepository!.progress(
                  tour.id,
                  tour.revisionId,
                  save: save,
                );
              },
            )).load();
      bool supported = false;
      if (!kIsWeb) {
        try {
          supported = await _channel.invokeMethod<bool>('supported') ?? false;
        } on MissingPluginException {
          supported = false;
        }
      }
      if (!mounted || !_current) return;
      setState(() {
        _tour = tour;
        _versionChanged = progress.revisionId != tour.revisionId;
        _progress = _versionChanged
            ? TourProgress(revisionId: tour.revisionId)
            : progress;
        _supported = supported;
        _point =
            _points.where((p) => p.id == widget.pointId).firstOrNull ??
            _points.firstOrNull;
      });
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _loading = false);
    }
  }

  Future<String> _assetUrl(String path) {
    final cached = _assetUrls[path];
    if (cached != null && DateTime.now().difference(cached.$1).inMinutes < 9) {
      return cached.$2;
    }
    final url = widget.controller.tourRepository!.assetUrl(path);
    _assetUrls[path] = (DateTime.now(), url);
    return url;
  }

  bool _canScan(int generation, TourPoint p) =>
      _current &&
      generation == _scanGeneration &&
      p.id == _point?.id &&
      p.ar?['reference_version'] == _point?.ar?['reference_version'] &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _scan() async {
    if (_point == null || !_supported || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final generation = ++_scanGeneration;
    try {
      final p = _point!, ar = p.ar!;
      final url = await _assetUrl(ar['reference_path'] as String);
      if (!_canScan(generation, p)) return;
      final response = widget.referenceLoader == null
          ? await http.get(Uri.parse(url))
          : null;
      if (response != null && response.statusCode != 200) {
        throw StateError('No pudimos abrir la referencia de esta parada.');
      }
      final bytes = response?.bodyBytes ?? await widget.referenceLoader!(url);
      if (!_canScan(generation, p)) return;
      final path = await (widget.localStore ?? TourLocalStore()).saveBytes(
        _account,
        'reference-${ar['reference_version']}',
        bytes,
      );
      if (!mounted ||
          !_current ||
          generation != _scanGeneration ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      await _tracking?.cancel();
      if (!_canScan(generation, p)) return;
      _references = [
        {
          'id': p.id,
          'path': path,
          'widthMeters': (ar['width_cm'] as num).toDouble() / 100,
        },
      ];
      _recognizedAt = null;
      _recognized = false;
      _tracking = _events.receiveBroadcastStream().listen(
        (event) {
          if (!mounted || !_current) return;
          if (event['state'] == 'error') {
            setState(() {
              _error = event['message'] as String? ?? 'No pudimos iniciar AR.';
              _scanning = false;
            });
            return;
          }
          if (event['id'] != _point?.id) return;
          final tracking = event['state'] == 'tracking';
          if (tracking) {
            _everRecognized = true;
            _recognizedAt ??= DateTime.now();
            if (!_recognized && !widget.preview) {
              _progress!.visit(_point!.id);
              _saveProgress();
            }
          } else {
            _recognizedAt = null;
          }
          setState(() => _recognized = tracking);
        },
        onError: (Object error) {
          if (mounted && _current) {
            setState(() {
              _scanning = false;
              _error =
                  'No pudimos iniciar la cámara AR. Puedes consultar la lista.';
            });
          }
        },
      );
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_current && _scanning) setState(() {});
      });
      setState(() => _scanning = true);
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _saveProgress() async {
    if (widget.preview || _tour == null) return;
    try {
      await _progressStore!.save(_progress!);
    } catch (e) {
      if (mounted && _current) {
        setState(
          () => _error = e is TourProgressPersistenceException
              ? 'No pudimos guardar el progreso en este dispositivo. Mantén la pantalla abierta e inténtalo de nuevo.'
              : 'Progreso guardado en este dispositivo. Se sincronizará al volver a abrir el recorrido.',
        );
      }
    }
  }

  Future<void> _report() async {
    if (!_recognized || _seconds < 3 || !widget.preview || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.controller.tourRepository!.reportAR(
        _tour!.id,
        _point!.id,
        _point!.ar!['reference_version'] as String,
        defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        _seconds,
      );
      if (mounted && _current) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prueba guardada para esta referencia.'),
          ),
        );
        _stop();
      }
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  void _stop() {
    _scanGeneration++;
    _tracking?.cancel();
    _tracking = null;
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _scanning = false;
        _recognized = false;
        _recognizedAt = null;
      });
    }
  }

  void _choose(TourPoint point) {
    final previous = _tour?.document.scenes
        .where((s) => s.points.any((p) => p.id == _point?.id))
        .firstOrNull;
    final destination = _tour?.document.scenes
        .where((s) => s.points.any((p) => p.id == point.id))
        .firstOrNull;
    final connection = previous == null
        ? null
        : jsonList(previous.data['connections'])
              .map(jsonMap)
              .where((c) => c['target_scene_id'] == destination?.id)
              .firstOrNull;
    _approach = connection?['instruction']?.toString();
    _approach ??= destination == null
        ? null
        : 'Busca la parada en ${destination.name}.';
    _stop();
    setState(() {
      _point = point;
      _everRecognized = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_accountChanged);
    _tracking?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    final next = _points
        .where(
          (p) =>
              !_progress!.visited.contains(p.id) &&
              !_progress!.skipped.contains(p.id),
        )
        .firstOrNull;
    if (next != null) {
      _choose(next);
    } else {
      _stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(fallback: '/tours/${widget.tourId}'),
        title: Text(
          widget.preview ? 'Probar AR en el local' : 'Recorrer con cámara',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) TourNotice(_error!),
                if (_versionChanged)
                  const TourNotice(
                    'El recorrido cambió. Estas paradas pertenecen a la versión actual.',
                  ),
                if (!_supported)
                  const TourNotice(
                    'AR no está disponible en este dispositivo. Puedes consultar las paradas y explorar el panorama.',
                  ),
                if (_progress != null && !widget.preview)
                  Text(
                    '${_progress!.visited.length} de ${_points.length} paradas visitadas · ${_progress!.skipped.length} saltadas',
                  ),
                if (point != null) ...[
                  Text(
                    point.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_scanning)
                    SizedBox(
                      height: 360,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child:
                                defaultTargetPlatform == TargetPlatform.android
                                ? AndroidView(
                                    key: ValueKey(point.id),
                                    viewType: 'marea/tour_ar_view',
                                    creationParams: {'references': _references},
                                    creationParamsCodec:
                                        const StandardMessageCodec(),
                                  )
                                : UiKitView(
                                    key: ValueKey(point.id),
                                    viewType: 'marea/tour_ar_view',
                                    creationParams: {'references': _references},
                                    creationParamsCodec:
                                        const StandardMessageCodec(),
                                  ),
                          ),
                          if (_recognized)
                            const Positioned(
                              top: 12,
                              left: 12,
                              child: Chip(label: Text('Imagen reconocida')),
                            ),
                        ],
                      ),
                    ),
                  if (_scanning)
                    Text(
                      _recognized
                          ? 'Imagen reconocida'
                          : !_everRecognized
                          ? 'Encuadra la imagen de esta parada'
                          : 'Ya no podemos confirmar la posición. Vuelve a encuadrar la referencia.',
                    ),
                  if (_approach != null) TourNotice(_approach!),
                  Text(point.description),
                  if (point.ar != null)
                    FutureBuilder<String>(
                      future: _assetUrl(point.ar!['reference_path'] as String),
                      builder: (c, s) => s.hasData
                          ? SizedBox(
                              height: 120,
                              child: Image.network(
                                s.data!,
                                errorBuilder: (_, e, st) =>
                                    const Text('Referencia no disponible'),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  if (_supported && !_scanning)
                    FilledButton(
                      onPressed: _busy ? null : _scan,
                      child: const Text('Escanear esta imagen'),
                    ),
                  if (_scanning)
                    OutlinedButton(
                      onPressed: _stop,
                      child: const Text('Volver a la lista'),
                    ),
                  if (widget.preview && _scanning)
                    FilledButton(
                      onPressed: _recognized && _seconds >= 3 && !_busy
                          ? _report
                          : null,
                      child: const Text('Guardar prueba de reconocimiento'),
                    ),
                  TextButton(
                    onPressed: () async {
                      _stop();
                      final continued = await showTourPoint(
                        context,
                        widget.controller,
                        point,
                      );
                      if (continued && _current && !widget.preview) {
                        setState(() => _progress!.visit(point.id));
                        await _saveProgress();
                        if (_current) _next();
                      }
                    },
                    child: const Text('Leer detalle de la parada'),
                  ),
                  if (!widget.preview && _progress!.visited.contains(point.id))
                    FilledButton(
                      onPressed: _next,
                      child: const Text('Siguiente parada'),
                    ),
                  if (!widget.preview)
                    OutlinedButton(
                      onPressed: () {
                        _progress!.skip(point.id);
                        _saveProgress();
                        final next = _points
                            .where(
                              (p) =>
                                  !_progress!.visited.contains(p.id) &&
                                  !_progress!.skipped.contains(p.id),
                            )
                            .firstOrNull;
                        if (next != null) {
                          _choose(next);
                        } else {
                          _stop();
                        }
                      },
                      child: const Text('Saltar parada'),
                    ),
                ],
                if (!widget.preview &&
                    _points.isNotEmpty &&
                    _points.every(
                      (p) =>
                          _progress!.visited.contains(p.id) ||
                          _progress!.skipped.contains(p.id),
                    )) ...[
                  const TourNotice(
                    'Terminaste el recorrido. Puedes volver al perfil o explorar el local en 360°.',
                  ),
                  FilledButton(
                    onPressed: () {
                      _stop();
                      context.push('/people/${_tour!.ownerId}');
                    },
                    child: const Text('Volver al perfil'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _stop();
                      context.push('/tours/${_tour!.id}');
                    },
                    child: const Text('Explorar el local en 360°'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Lista de paradas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                for (final p in _points)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      _progress?.visited.contains(p.id) == true
                          ? 'Visitada'
                          : _progress?.skipped.contains(p.id) == true
                          ? 'Saltada'
                          : 'Pendiente',
                    ),
                    selected: p.id == point?.id,
                    onTap: () => _choose(p),
                  ),
                const TourNotice(
                  'Busca cada imagen con la fotografía de referencia y la indicación del local. La lista permite leer sin cámara.',
                ),
              ],
            ),
    );
  }
}
