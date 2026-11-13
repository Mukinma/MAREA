import 'dart:async';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
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

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
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
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  String _arError(Object error) {
    if (error is StateError &&
        error.message == 'No pudimos abrir la referencia de esta parada.') {
      return core_l10n.AppLocalizations.tr(_l10n.errorAbrirReferenciaParada);
    }
    if (error is StateError &&
        error.message ==
            'No pudimos confirmar que la prueba se guardó para esta referencia. '
                'Mantén la imagen encuadrada y vuelve a intentarlo.') {
      return core_l10n.AppLocalizations.tr(_l10n.pruebaReferenciaNoConfirmada);
    }
    return tourError(error, l10n: _l10n);
  }
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
      if (tour == null) {
        if (mounted && _current) {
          setState(() => _error = core_l10n.AppLocalizations.tr(_l10n.recorridoNoDisponible));
        }
        return;
      }
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
      if (_current) setState(() => _error = _arError(e));
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
              _error = event['message'] as String? ?? core_l10n.AppLocalizations.tr(_l10n.errorIniciarCamara);
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
              _error = core_l10n.AppLocalizations.tr(_l10n.errorIniciarCamaraAr);
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
      if (_current) setState(() => _error = _arError(e));
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
              ? core_l10n.AppLocalizations.tr(_l10n.errorGuardarProgreso)
              : core_l10n.AppLocalizations.tr(_l10n.progresoGuardado),
        );
      }
    }
  }

  Future<void> _report() async {
    if (!_recognized || _seconds < 3 || !widget.preview || _busy) return;
    final tour = _tour!, point = _point!;
    final reference = Map<String, dynamic>.from(point.ar!);
    final version = reference['reference_version'] as String;
    final generation = _scanGeneration;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await widget.controller.tourRepository!.reportAR(
        tour.id,
        point.id,
        version,
        defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        _seconds,
      );
      final savedPoint = saved.document.point(point.id);
      final savedReference = savedPoint?.ar;
      final width = reference['width_cm'];
      if (saved.data['id'] != tour.id ||
          saved.data['owner_id'] != _account ||
          tour.ownerId != _account ||
          savedPoint == null ||
          version.isEmpty ||
          savedReference?['reference_version'] != version ||
          savedReference?['tested_version'] != version ||
          reference['reference_path'] is! String ||
          (reference['reference_path'] as String).isEmpty ||
          savedReference?['reference_path'] != reference['reference_path'] ||
          width is! num ||
          !width.isFinite ||
          width <= 0 ||
          savedReference?['width_cm'] != width) {
        throw StateError(
          'No pudimos confirmar que la prueba se guardó para esta referencia. '
          'Mantén la imagen encuadrada y vuelve a intentarlo.',
        );
      }
      if (generation != _scanGeneration || _point?.id != point.id) return;
      if (mounted && _current) {
        setState(() {
          _tour = saved;
          _point = savedPoint;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (AppLocalizations.of(context) ?? AppLocalizationsEs())
                  .pruebaGuardadaReferencia,
            ),
          ),
        );
        _stop();
      }
    } catch (e) {
      if (_current) {
        setState(() => _error = _arError(e));
      }
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
        : core_l10n.AppLocalizations.tr(
            _l10n.buscaParadaEn(destination.name),
          );
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    final point = _point;
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(fallback: '/tours/${widget.tourId}'),
        title: Text(
          widget.preview ? core_l10n.AppLocalizations.tr(l10n.probarArEnLocal) : core_l10n.AppLocalizations.tr(l10n.recorrerConCamara),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) TourNotice(_error!),
                if (_versionChanged)
                  TourNotice(core_l10n.AppLocalizations.tr(l10n.recorridoCambioParadas)),
                if (!_supported)
                  TourNotice(core_l10n.AppLocalizations.tr(l10n.arNoDisponible)),
                if (_progress != null && !widget.preview)
                  Text(
                    core_l10n.AppLocalizations.tr(
                      l10n.paradasVisitadas(
                        _progress!.visited.length,
                        _points.length,
                        _progress!.skipped.length,
                      ),
                    ),
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
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Chip(label: Text(core_l10n.AppLocalizations.tr(l10n.imagenReconocida))),
                            ),
                        ],
                      ),
                    ),
                  if (_scanning)
                    Text(
                      _recognized
                          ? core_l10n.AppLocalizations.tr(l10n.imagenReconocida)
                          : !_everRecognized
                          ? core_l10n.AppLocalizations.tr(l10n.encuadraImagenParada)
                          : core_l10n.AppLocalizations.tr(l10n.referenciaNoConfirmada),
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
                                errorBuilder: (_, e, st) => Text(
                                  core_l10n.AppLocalizations.tr(l10n.referenciaNoDisponible),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  if (_supported && !_scanning)
                    FilledButton(
                      onPressed: _busy ? null : _scan,
                      child: Text(core_l10n.AppLocalizations.tr(l10n.escanearImagen)),
                    ),
                  if (_scanning)
                    OutlinedButton(
                      onPressed: _stop,
                      child: Text(core_l10n.AppLocalizations.tr(l10n.volverLista)),
                    ),
                  if (widget.preview && _scanning)
                    FilledButton(
                      onPressed: _recognized && _seconds >= 3 && !_busy
                          ? _report
                          : null,
                      child: Text(
                        core_l10n.AppLocalizations.tr(l10n.guardarPruebaReconocimiento),
                      ),
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
                    child: Text(core_l10n.AppLocalizations.tr(l10n.leerDetalleParada)),
                  ),
                  if (!widget.preview && _progress!.visited.contains(point.id))
                    FilledButton(
                      onPressed: _next,
                      child: Text(core_l10n.AppLocalizations.tr(l10n.siguienteParada)),
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
                      child: Text(core_l10n.AppLocalizations.tr(l10n.saltarParada)),
                    ),
                ],
                if (!widget.preview &&
                    _points.isNotEmpty &&
                    _points.every(
                      (p) =>
                          _progress!.visited.contains(p.id) ||
                          _progress!.skipped.contains(p.id),
                    )) ...[
                  TourNotice(core_l10n.AppLocalizations.tr(l10n.terminasteRecorrido)),
                  FilledButton(
                    onPressed: () {
                      _stop();
                      context.push('/people/${_tour!.ownerId}');
                    },
                    child: Text(core_l10n.AppLocalizations.tr(l10n.volverPerfil)),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _stop();
                      context.push('/tours/${_tour!.id}');
                    },
                    child: Text(
                      core_l10n.AppLocalizations.tr(l10n.explorarLocal),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  core_l10n.AppLocalizations.tr(l10n.listaParadas),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                for (final p in _points)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      _progress?.visited.contains(p.id) == true
                          ? core_l10n.AppLocalizations.tr(l10n.visitada)
                          : _progress?.skipped.contains(p.id) == true
                          ? core_l10n.AppLocalizations.tr(l10n.saltada)
                          : core_l10n.AppLocalizations.tr(l10n.pendiente),
                    ),
                    selected: p.id == point?.id,
                    onTap: () => _choose(p),
                  ),
                TourNotice(core_l10n.AppLocalizations.tr(l10n.instruccionBuscarImagen)),
              ],
            ),
    );
  }
}
