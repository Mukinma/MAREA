import 'dart:async';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../data/tour_local_store.dart';
import '../models/tour_models.dart';
import '../presentation/tour_widgets.dart';
import '../presentation/tour_panorama.dart';
import 'capture_plan.dart';
import 'capture_motion_gate.dart';
import 'capture_guidance_panel.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
String _tourJobMessage(TourJob job, AppLocalizations l10n) {
  final message = job.data['message'];
  if (message != null) return message as String;
  return switch (job.state) {
    'queued' => core_l10n.AppLocalizations.tr(l10n.procesamientoEnEspera),
    'running' => core_l10n.AppLocalizations.tr(l10n.procesandoPanorama),
    'ready' => core_l10n.AppLocalizations.tr(l10n.panoramaListoRevision),
    'needs_recapture' => core_l10n.AppLocalizations.tr(l10n.necesitamosNuevasFotografias),
    'cancelled' => core_l10n.AppLocalizations.tr(l10n.procesamientoCancelado),
    _ => core_l10n.AppLocalizations.tr(l10n.noPudimosProcesarPanorama),
  };
}

Map<String, dynamic> _preparePhoto(Uint8List source) {
  final image = img.decodeImage(source);
  if (image == null) throw StateError('No pudimos leer la fotografía.');
  final oriented = img.bakeOrientation(image);
  final resized = oriented.width > 2560 || oriented.height > 2560
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 2560 : null,
          height: oriented.height > oriented.width ? 2560 : null,
        )
      : oriented;
  return {
    'bytes': Uint8List.fromList(img.encodeJpg(resized, quality: 90)),
    'width': resized.width,
    'height': resized.height,
  };
}

class TourCaptureScreen extends StatefulWidget {
  const TourCaptureScreen({
    required this.controller,
    required this.tourId,
    required this.sceneId,
    this.importOnly = false,
    super.key,
  });
  final AppSessionController controller;
  final String tourId, sceneId;
  final bool importOnly;
  @override
  State<TourCaptureScreen> createState() => _TourCaptureScreenState();
}

class _TourCaptureScreenState extends State<TourCaptureScreen>
    with WidgetsBindingObserver {
  static const _motion = MethodChannel('marea/tour_motion');
  static const _events = EventChannel('marea/tour_motion/events');
  final _store = TourLocalStore();
  CameraController? _camera;
  StreamSubscription<dynamic>? _orientation;
  Map<String, dynamic> _session = {};
  CapturePlan? _plan;
  TourJob? _job;
  String? _error;
  bool _busy = false,
      _aligned = false,
      _searching = false,
      _missingWebFile = false;
  late final String _account = widget.controller.profile!.id;
  double _yaw = 0, _pitch = 0, _roll = 0, _yawOffset = 0, _upload = 0;
  final _motionGate = CaptureMotionGate();
  bool _motionFresh = false, _motionSteady = false;
  Timer? _poll, _motionReadiness;
  int _cameraGeneration = 0;
  bool _reviewed = false;
  bool get _current => mounted && widget.controller.profile?.id == _account;
  String _captureError(Object error, AppLocalizations l10n) =>
      switch (tourError(error, l10n: l10n)) {
        'No pudimos leer la fotografía.' => core_l10n.AppLocalizations.tr(l10n.fotoNoLeida),
        'La sesión cambió.' => core_l10n.AppLocalizations.tr(l10n.estadoSesionCambio),
        'No hay cámara trasera disponible. Puedes importar un panorama.' =>
          core_l10n.AppLocalizations.tr(l10n.sinCamaraTrasera),
        'No pudimos obtener los datos de la lente. Importa un panorama 360°.' =>
          core_l10n.AppLocalizations.tr(l10n.errorDatosLente),
        'Retoma con la misma cámara o empieza otra captura.' =>
          core_l10n.AppLocalizations.tr(l10n.mismaCamaraCaptura),
        'No pudimos leer la orientación. Puedes importar un panorama.' =>
          core_l10n.AppLocalizations.tr(l10n.orientacionNoLeida),
        'Elige una esfera equirectangular completa de proporción 2:1, con metadatos GPano.' =>
          core_l10n.AppLocalizations.tr(l10n.proporcionEsfericaGpano),
        'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.' =>
          core_l10n.AppLocalizations.tr(l10n.panoramaSuperaLimite),
        'No pudimos conocer la lente. Puedes importar un panorama 360°.' =>
          core_l10n.AppLocalizations.tr(l10n.noConocemosLente),
        'La lente cambió desde la primera toma. Usa la misma cámara o empieza otra captura.' =>
          core_l10n.AppLocalizations.tr(l10n.lenteCambio),
        'Esta lente requiere demasiadas tomas. Usa la cámara principal o importa una esfera completa.' =>
          core_l10n.AppLocalizations.tr(l10n.demasiadasTomasLente),
        'Vuelve a elegir el archivo para continuar la carga.' =>
          core_l10n.AppLocalizations.tr(l10n.volverElegirArchivoCarga),
        'El servidor no confirmó la fotografía completa.' =>
          core_l10n.AppLocalizations.tr(l10n.fotoSubidaNoConfirmada),
        _ => tourError(error, l10n: l10n),
      };
  List<dynamic> get _frames => (_session['frames'] as List?) ?? [];
  CaptureTarget? get _target => _plan?.targets
      .where((t) => !_frames.any((f) => f['target_id'] == t.id))
      .firstOrNull;
  bool get _aimed => _motionGate.aimed;
  bool get _steady => _motionGate.isSteady(DateTime.now());
  String get _key => 'capture-${widget.sceneId}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
    _restore();
  }

  void _accountChanged() {
    if (widget.controller.profile?.id != _account) {
      _release();
    }
  }

  Future<void> _persist() async {
    if (!_current) throw StateError('La sesión cambió.');
    await _store.write(_account, _key, _session);
  }

  Future<void> _restore() async {
    try {
      final stored = await _store.read(_account, _key);
      if (!mounted || !_current) return;
      if (stored != null) {
        _session = stored;
        if (stored['plan'] != null) {
          _plan = CapturePlan.fromJson(jsonMap(stored['plan']));
        }
        if (stored['job_id'] != null) {
          _job = await widget.controller.tourRepository!.job(
            stored['job_id'] as String,
          );
          if (!mounted || !_current) return;
          _watch();
        }
      }
      if (kIsWeb && _job == null && _frames.isNotEmpty) {
        try {
          await _store.readBytes(_frames.first['local_path'] as String);
        } catch (_) {
          _missingWebFile = true;
        }
      }
      setState(() {});
    } catch (e) {
      if (_current) {
        setState(
          () => _error = tourError(
            e,
            l10n: AppLocalizations.of(context) ?? AppLocalizationsEs(),
          ),
        );
      }
    }
  }

  Future<void> _openCamera() async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final generation = ++_cameraGeneration;
    _resetMotion();
    try {
      final cameras = await availableCameras();
      if (!_current ||
          generation != _cameraGeneration ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final rear =
          cameras
              .where(
                (c) =>
                    c.lensDirection == CameraLensDirection.back &&
                    c.lensType == CameraLensType.wide,
              )
              .firstOrNull ??
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull;
      if (rear == null) {
        throw StateError(
          'No hay cámara trasera disponible. Puedes importar un panorama.',
        );
      }
      final c = CameraController(
        rear,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = c;
      await c.initialize();
      if (!_current ||
          generation != _cameraGeneration ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await c.setZoomLevel(1);
      try {
        await c.setFocusMode(FocusMode.auto);
        await c.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      // Calibrate against the actual portrait JPEG, never preview dimensions.
      final calibration = await c.takePicture();
      final dimensions = await compute(
        _preparePhoto,
        await calibration.readAsBytes(),
      );
      if (!_current ||
          generation != _cameraGeneration ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      try {
        await c.setFocusMode(FocusMode.locked);
        await c.setExposureMode(ExposureMode.locked);
      } catch (_) {
        /* Some cameras expose only automatic modes. */
      }
      final lens = await _motion
          .invokeMapMethod<String, dynamic>('cameraInfo', {
            'cameraName': rear.name,
            'imageWidth': dimensions['width'],
            'imageHeight': dimensions['height'],
          });
      if (lens == null) {
        throw StateError(
          'No pudimos obtener los datos de la lente. Importa un panorama 360°.',
        );
      }
      if (_frames.isNotEmpty && _plan != null) {
        _plan!.checkLens(
          hfov: (lens['hfov'] as num).toDouble(),
          vfov: (lens['vfov'] as num).toDouble(),
        );
        if (_session['camera_name'] != null &&
            _session['camera_name'] != rear.name) {
          throw StateError(
            'Retoma con la misma cámara o empieza otra captura.',
          );
        }
      } else {
        _plan = CapturePlan.create(
          hfov: (lens['hfov'] as num).toDouble(),
          vfov: (lens['vfov'] as num).toDouble(),
        );
      }
      _session['camera_name'] = rear.name;
      _session['plan'] = _plan!.toJson();
      _session['frames'] ??= <dynamic>[];
      await _persist();
      if (!_current) {
        await _release();
        return;
      }
      _yawOffset = _frames.isEmpty
          ? 0
          : (_frames.first['yaw'] as num).toDouble();
      _orientation = _events.receiveBroadcastStream().listen(
        (event) {
          if (!mounted ||
              !_current ||
              generation != _cameraGeneration ||
              _camera != c) {
            return;
          }
          final now = DateTime.now();
          final y = normalizeYaw((event['yaw'] as num).toDouble() + _yawOffset),
              p = (event['pitch'] as num).toDouble();
          _motionGate.update(yaw: y, pitch: p, target: _target, now: now);
          setState(() {
            _yaw = y;
            _pitch = p;
            _roll = (event['roll'] as num).toDouble();
            _motionFresh = _motionGate.isFresh(now);
            _motionSteady = _motionGate.isSteady(now);
          });
        },
        onError: (Object e) {
          if (mounted &&
              _current &&
              generation == _cameraGeneration &&
              _camera == c) {
            _resetMotion();
            setState(
              () => _error =
                  core_l10n.AppLocalizations.tr(l10n.orientacionNoLeida),
            );
          }
        },
      );
      await _motion.invokeMethod('start');
      if (!_current || generation != _cameraGeneration || _camera != c) {
        return;
      }
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      _aligned = _frames.isEmpty;
      _motionReadiness = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _refreshReadiness(),
      );
    } catch (e) {
      await _release();
      if (_current) setState(() => _error = _captureError(e, l10n));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _align() async {
    final camera = _camera;
    if (_busy || camera == null) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    final generation = _cameraGeneration;
    bool canAlign() =>
        _current &&
        generation == _cameraGeneration &&
        _camera == camera &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!canAlign()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _resetMotion();
    try {
      await _motion.invokeMethod('stop');
      if (!canAlign()) return;
      await _motion.invokeMethod('start');
      if (!canAlign()) return;
      setState(() => _aligned = true);
    } catch (e) {
      if (canAlign()) {
        _resetMotion();
        setState(() => _error = _captureError(e, l10n));
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  void _resetMotion() {
    _motionGate.reset();
    _motionFresh = false;
    _motionSteady = false;
  }

  void _refreshReadiness() {
    if (!_current || _camera == null) return;
    final now = DateTime.now();
    final fresh = _motionGate.isFresh(now);
    final steady = _motionGate.isSteady(now);
    if (fresh != _motionFresh || steady != _motionSteady) {
      setState(() {
        _motionFresh = fresh;
        _motionSteady = steady;
      });
    }
  }

  Future<void> _take() async {
    final target = _target;
    if (_busy || !_aligned || !_aimed || !_steady || target == null) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    setState(() => _busy = true);
    final pose = {'yaw': _yaw, 'pitch': _pitch, 'roll': _roll};
    try {
      final photo = await _camera!.takePicture();
      final prepared = await compute(_preparePhoto, await photo.readAsBytes());
      if (!mounted || !_current) return;
      final id = tourId();
      final local = await _store.saveBytes(
        _account,
        id,
        prepared['bytes'] as Uint8List,
      );
      _frames.add({
        'id': id,
        'local_path': local,
        'width': prepared['width'],
        'height': prepared['height'],
        ...pose,
        'hfov': _plan!.hfov,
        'vfov': _plan!.vfov,
        'target_id': target.id,
      });
      await _persist();
      _resetMotion();
    } catch (e) {
      if (_current) setState(() => _error = _captureError(e, l10n));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final decoded = await compute(img.decodeImage, bytes);
      if (decoded == null || decoded.width != decoded.height * 2) {
        throw StateError(
          core_l10n.AppLocalizations.tr(l10n.proporcionEsfericaGpano),
        );
      }
      if (bytes.length > 32 * 1024 * 1024) {
        throw StateError(
          core_l10n.AppLocalizations.tr(l10n.panoramaSuperaLimite),
        );
      }
      if (!mounted || !_current) return;
      final id = tourId();
      final path = await _store.saveBytes(_account, id, bytes);
      _session = {
        'mode': 'import',
        'frames': [
          {
            'id': id,
            'local_path': path,
            'width': decoded.width,
            'height': decoded.height,
            'yaw': 0,
            'pitch': 0,
            'roll': 0,
            'hfov': 360,
            'vfov': 180,
            'target_id': 'import',
          },
        ],
      };
      await _persist();
    } catch (e) {
      if (_current) setState(() => _error = _captureError(e, l10n));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _frames.isEmpty) return;
    if (_session['mode'] != 'import' && _target != null) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = widget.controller.tourRepository!;
    final uploader = repo.uploader();
    try {
      await _release();
      if (!_current) return;
      _session['capture_id'] ??= await repo.beginCapture(
        widget.tourId,
        widget.sceneId,
        _session['mode'] as String? ?? 'photos',
      );
      await _persist();
      for (var i = 0; i < _frames.length; i++) {
        if (!mounted || !_current) return;
        final frame = jsonMap(_frames[i]);
        final remote = '$_account/${_session['capture_id']}/${frame['id']}.jpg';
        await uploader.upload(
          bytes: await _store.readBytes(frame['local_path'] as String),
          bucket: 'tour-inputs',
          path: remote,
          checkpoint: frame['upload'] as Map<String, dynamic>?,
          save: (checkpoint) async {
            frame['upload'] = checkpoint;
            await _persist();
          },
          isCurrent: () => _current,
          progress: (v) {
            if (_current) setState(() => _upload = (i + v) / _frames.length);
          },
        );
        frame['path'] = remote;
        await _persist();
      }
      final manifest = {
        'mode': _session['mode'] ?? 'photos',
        'frames': _frames
            .map(
              (f) => Map<String, dynamic>.from(f as Map)
                ..remove('local_path')
                ..remove('upload'),
            )
            .toList(),
      };
      _job = await repo.submitCapture(
        _session['capture_id'] as String,
        manifest,
      );
      _session['job_id'] = _job!.id;
      await _persist();
      _watch();
    } catch (e) {
      if (_current) setState(() => _error = _captureError(e, l10n));
    } finally {
      uploader.dispose();
      if (_current) setState(() => _busy = false);
    }
  }

  void _watch() {
    _poll?.cancel();
    if (_job?.terminal ?? true) return;
    _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_searching || !_current) return;
      _searching = true;
      try {
        final j = await widget.controller.tourRepository!.job(_job!.id);
        if (mounted && _current) {
          setState(() => _job = j);
          if (j.terminal) _poll?.cancel();
        }
      } catch (e) {
        if (_current) {
          setState(
            () => _error = tourError(
              e,
              l10n: AppLocalizations.of(context) ?? AppLocalizationsEs(),
            ),
          );
        }
      } finally {
        _searching = false;
      }
    });
  }

  Future<void> _release() async {
    _cameraGeneration++;
    _motionReadiness?.cancel();
    _motionReadiness = null;
    _resetMotion();
    final c = _camera;
    _camera = null;
    await _orientation?.cancel();
    _orientation = null;
    try {
      await _motion.invokeMethod('stop');
    } catch (_) {}
    await c?.dispose();
    _aligned = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _release();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_accountChanged);
    _poll?.cancel();
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    final c = _camera;
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(fallback: '/tours/${widget.tourId}/edit'),
        title: Text(core_l10n.AppLocalizations.tr(l10n.capturarPosicion360)),
      ),
      bottomNavigationBar:
          c != null && c.value.isInitialized && _aligned && _target != null
          ? CaptureGuidancePanel(
              target: _target!,
              yaw: _yaw,
              pitch: _pitch,
              fresh: _motionGate.isFresh(DateTime.now()),
              aimed: _aimed,
              steady: _steady,
              busy: _busy,
              onTake: _take,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(core_l10n.AppLocalizations.tr(l10n.instruccionCapturaPanorama)),
          const SizedBox(height: 12),
          if (_error != null) TourNotice(_error!),
          if (_job != null) ...[
            Text(
              _tourJobMessage(_job!, l10n),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (!_job!.terminal) const LinearProgressIndicator(),
            if (_job!.state == 'ready') ...[
              SizedBox(
                height: 320,
                child: TourPanorama(
                  repository: widget.controller.tourRepository!,
                  scene: TourScene({
                    'id': widget.sceneId,
                    'name': core_l10n.AppLocalizations.tr(l10n.panoramaProcesado),
                    ...jsonMap(_job!.data['result']),
                    'points': [],
                    'connections': [],
                  }),
                ),
              ),
              CheckboxListTile(
                value: _reviewed,
                onChanged: (v) => setState(() => _reviewed = v ?? false),
                title: Text(core_l10n.AppLocalizations.tr(l10n.confirmacionRevisionPanorama)),
              ),
              FilledButton(
                onPressed: _busy || !_reviewed
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await widget.controller.tourRepository!.attach(
                            widget.tourId,
                            widget.sceneId,
                            _job!.id,
                          );
                          if (context.mounted && _current) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (_current) {
                            setState(
                              () => _error = tourError(
                                e,
                                l10n: l10n,
                              ),
                            );
                          }
                        } finally {
                          if (_current) setState(() => _busy = false);
                        }
                      },
                child: Text(core_l10n.AppLocalizations.tr(l10n.usarPanoramaRevisado)),
              ),
            ],
            if (!_job!.terminal)
              OutlinedButton(
                onPressed: () async {
                  await widget.controller.tourRepository!.cancelJob(_job!.id);
                  if (mounted && _current) {
                    setState(
                      () =>
                          _job = TourJob({..._job!.data, 'state': 'cancelled'}),
                    );
                  }
                },
                child: Text(core_l10n.AppLocalizations.tr(l10n.cancelarProcesamiento)),
              ),
            if (_job!.terminal && _job!.state != 'ready')
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _job = null;
                    _reviewed = false;
                    _session = {};
                    _plan = null;
                    _poll?.cancel();
                  });
                  _persist();
                },
                child: Text(core_l10n.AppLocalizations.tr(l10n.prepararNuevaCaptura)),
              ),
          ] else ...[
            if (_missingWebFile) ...[
              TourNotice(core_l10n.AppLocalizations.tr(l10n.archivoWebNoConservado)),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        _session = {};
                        _plan = null;
                        _missingWebFile = false;
                        await _persist();
                        if (_current) setState(() {});
                        if (_current) await _import();
                      },
                child: Text(core_l10n.AppLocalizations.tr(l10n.volverElegirPanorama)),
              ),
            ],
            if (c != null && c.value.isInitialized)
              AspectRatio(
                aspectRatio: .75,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CameraPreview(c),
                    const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _target == null
                              ? core_l10n.AppLocalizations.tr(l10n.capturaCompleta)
                              : !_motionFresh
                              ? core_l10n.AppLocalizations.tr(l10n.esperandoOrientacion)
                              : _aimed
                              ? core_l10n.AppLocalizations.tr(l10n.mantenerTelefonoEstable)
                              : core_l10n.AppLocalizations.tr(
                                  l10n.apuntarObjetivo(
                                    _target!.yaw.toStringAsFixed(0),
                                    _target!.pitch.toStringAsFixed(0),
                                  ),
                                ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_plan != null)
              Text(
                core_l10n.AppLocalizations.tr(
                  l10n.tomasAceptadas(
                    _frames.length,
                    _plan!.targets.length,
                  ),
                ),
              ),
            if (c != null && !_aligned && _frames.isNotEmpty) ...[
              TourNotice(core_l10n.AppLocalizations.tr(l10n.alinearCapturaInicialAyuda)),
              FutureBuilder<Uint8List>(
                future: _store.readBytes(_frames.first['local_path'] as String),
                builder: (c, s) => s.hasData
                    ? SizedBox(height: 160, child: Image.memory(s.data!))
                    : const SizedBox(),
              ),
              FilledButton(
                onPressed: _busy ? null : _align,
                child: Text(core_l10n.AppLocalizations.tr(l10n.yaAlineePrimeraToma)),
              ),
            ],
            if (_frames.isNotEmpty && _session['mode'] != 'import')
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        _frames.removeLast();
                        _resetMotion();
                        await _persist();
                        if (_current) setState(() {});
                      },
                child: Text(core_l10n.AppLocalizations.tr(l10n.repetirUltimaToma)),
              ),
            if (_frames.isNotEmpty)
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final restart = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(core_l10n.AppLocalizations.tr(l10n.empezarOtraCaptura)),
                            content: Text(core_l10n.AppLocalizations.tr(l10n.capturasDejaranPosicion)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(core_l10n.AppLocalizations.tr(l10n.conservarTomas)),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(core_l10n.AppLocalizations.tr(l10n.empezarOtra)),
                              ),
                            ],
                          ),
                        );
                        if (restart != true || !_current) return;
                        await _release();
                        if (!_current) return;
                        _session = {};
                        _plan = null;
                        _missingWebFile = false;
                        await _persist();
                        if (_current) setState(() {});
                      },
                child: Text(core_l10n.AppLocalizations.tr(l10n.empezarOtraCaptura)),
              ),
            if (c == null &&
                !kIsWeb &&
                !widget.importOnly &&
                _session['mode'] != 'import')
              FilledButton(
                onPressed: _busy ? null : _openCamera,
                child: Text(
                  _frames.isEmpty
                      ? core_l10n.AppLocalizations.tr(l10n.abrirCamaraGuiada)
                      : core_l10n.AppLocalizations.tr(l10n.retomarCaptura),
                ),
              ),
            if (_frames.isEmpty)
              OutlinedButton(
                onPressed: _busy ? null : _import,
                child: Text(core_l10n.AppLocalizations.tr(l10n.importarPanoramaEsferico)),
              ),
            if (_frames.isNotEmpty &&
                (_session['mode'] == 'import' || _target == null))
              FilledButton(
                onPressed: _busy || _missingWebFile ? null : _send,
                child: Text(
                  _busy
                      ? core_l10n.AppLocalizations.tr(
                          l10n.subiendoPorcentaje(
                            (_upload * 100).toStringAsFixed(0),
                          ),
                        )
                      : core_l10n.AppLocalizations.tr(l10n.subirProcesarPanorama),
                ),
              ),
            TourNotice(
              kIsWeb
                  ? core_l10n.AppLocalizations.tr(l10n.subidaWebEnCurso)
                  : core_l10n.AppLocalizations.tr(l10n.subidaDispositivoEnCurso),
            ),
          ],
        ],
      ),
    );
  }
}
