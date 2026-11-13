import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../data/tour_local_store.dart';
import '../data/tus_uploader.dart';
import '../models/tour_models.dart';
import '../presentation/tour_widgets.dart';
import '../presentation/tour_panorama.dart';
import '../presentation/horizontal_panorama.dart';
import 'capture_plan.dart';
import 'capture_motion_gate.dart';
import 'capture_guidance_panel.dart';
import 'capture_auto_shutter.dart';
import 'capture_resume_photo.dart';
import 'capture_frames.dart';
import 'capture_cube_guide.dart';
import 'capture_history.dart';
import 'panorama_import.dart';

enum _CaptureAction {
  import,
  repeat,
  restart,
  manual,
  reference,
  angles,
  close,
  history,
}

enum _PanoramaSource { capture, gallery }

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
    this.localStore,
    this.listCameras,
    this.cameraFactory,
    super.key,
  });
  final AppSessionController controller;
  final String tourId, sceneId;
  final bool importOnly;
  final TourLocalStore? localStore;
  final Future<List<CameraDescription>> Function()? listCameras;
  final CameraController Function(CameraDescription)? cameraFactory;
  @override
  State<TourCaptureScreen> createState() => _TourCaptureScreenState();
}

class _TourCaptureScreenState extends State<TourCaptureScreen>
    with WidgetsBindingObserver {
  static const _motion = MethodChannel('marea/tour_motion');
  static const _events = EventChannel('marea/tour_motion/events');
  late final _store = widget.localStore ?? TourLocalStore();
  Future<Uint8List>? _importPreview;
  CameraController? _camera;
  StreamSubscription<dynamic>? _orientation;
  Map<String, dynamic> _session = {};
  bool get _horizontalImport => _session['panorama_kind'] == 'horizontal';
  CapturePlan? _plan;
  CaptureCubeGuide? _cubeGuide;
  int get _cubeGuideIndex => _cubeGuide?.nextIndex(_frames) ?? 0;
  CaptureCubeStep? get _cubeStep =>
      _cubeGuide != null && _cubeGuideIndex < _cubeGuide!.steps.length
      ? _cubeGuide!.steps[_cubeGuideIndex]
      : null;
  TourJob? _job;
  String? _error;
  bool _busy = false,
      _aligned = false,
      _searching = false,
      _missingWebFile = false;
  late final String _account = widget.controller.profile!.id;
  double _yaw = 0,
      _rawYaw = 0,
      _pitch = 0,
      _roll = 0,
      _yawOffset = 0,
      _upload = 0;
  double? _lensHfov, _lensVfov;
  String _motionSession = '';
  final _motionGate = CaptureMotionGate();
  bool _motionFresh = false, _motionSteady = false;
  bool _headingReady = false;
  Timer? _poll, _motionReadiness;
  int _cameraGeneration = 0;
  bool _reviewed = false;
  bool _restoring = true, _showAngles = false, _showReference = false;
  final _shutter = CaptureAutoShutter()..enabled = false;
  bool get _automatic => _shutter.enabled;
  set _automatic(bool value) => _shutter.enabled = value;
  bool get _autoPaused => _shutter.paused;
  set _autoPaused(bool value) => _shutter.paused = value;
  bool get _current => mounted && widget.controller.profile?.id == _account;
  List<dynamic> get _frames => (_session['frames'] as List?) ?? [];
  List<Map<String, dynamic>> get _processingFrames =>
      _session['mode'] == 'import'
      ? _frames.cast<Map<String, dynamic>>()
      : processableCaptureFrames(_frames);
  Map<String, dynamic>? get _reference =>
      processableCaptureFrames(_frames).firstOrNull;
  Set<String> get _coveredTargets => processableCaptureFrames(
    _frames,
  ).map((frame) => frame['target_id']).whereType<String>().toSet();
  CaptureTarget? get _target =>
      _plan?.targets.where((t) => !_coveredTargets.contains(t.id)).firstOrNull;
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
        _cubeGuide = CaptureCubeGuide.restore(stored['cube_guide']);
        if (stored['plan'] != null) {
          _plan = CapturePlan.fromJson(jsonMap(stored['plan']));
          if (_frames.isEmpty &&
              stored['capture_id'] == null &&
              stored['job_id'] == null &&
              stored['mode'] != 'import') {
            final previous = _plan!;
            _plan = null;
            _plan = CapturePlan.create(
              hfov: previous.hfov,
              vfov: previous.vfov,
            );
            _session['plan'] = _plan!.toJson();
            await _persist();
          }
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
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _restoring = false);
    }
  }

  Future<void> _openCamera() async {
    if (_busy || _restoring) return;
    setState(() {
      _busy = true;
      _error = null;
      _autoPaused = false;
    });
    final generation = ++_cameraGeneration;
    _resetMotion();
    try {
      final cameras = await (widget.listCameras ?? availableCameras)();
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
      final c =
          widget.cameraFactory?.call(rear) ??
          CameraController(rear, ResolutionPreset.high, enableAudio: false);
      _camera = c;
      await c.initialize();
      if (!_current ||
          generation != _cameraGeneration ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      try {
        await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      try {
        await c.setZoomLevel(1);
      } catch (_) {}
      try {
        await c.setFocusMode(FocusMode.auto);
        await c.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      _lensHfov = null;
      _lensVfov = null;
      _motionSession = tourId();
      _rawYaw = 0;
      _headingReady = false;
      _showReference = false;
      final reference = _reference;
      _aligned = reference == null;
      _yawOffset = (reference?['yaw'] as num?)?.toDouble() ?? 0;
      // Lens/guide metadata is optional for taking a local photograph.
      try {
        final calibration = await c.takePicture();
        final dimensions = await compute(
          _preparePhoto,
          await calibration.readAsBytes(),
        );
        if (!_current || generation != _cameraGeneration || _camera != c) {
          return;
        }
        final lens = await _motion
            .invokeMapMethod<String, dynamic>('cameraInfo', {
              'cameraName': rear.name,
              'imageWidth': dimensions['width'],
              'imageHeight': dimensions['height'],
            });
        final hfov = (lens?['hfov'] as num?)?.toDouble();
        final vfov = (lens?['vfov'] as num?)?.toDouble();
        if (hfov != null &&
            vfov != null &&
            hfov.isFinite &&
            vfov.isFinite &&
            hfov >= 1 &&
            hfov < 179 &&
            vfov >= 1 &&
            vfov < 179) {
          _lensHfov = hfov;
          _lensVfov = vfov;
          try {
            _plan ??= CapturePlan.create(hfov: hfov, vfov: vfov);
          } on StateError {
            // A guide need not fit this lens for the shutter to work.
          }
        }
      } catch (_) {
        // Keep the camera available even if calibration is unsupported.
      }
      if (!_current || generation != _cameraGeneration || _camera != c) return;
      _session['camera_name'] = rear.name;
      if (_plan != null) _session['plan'] = _plan!.toJson();
      _cubeGuide ??= CaptureCubeGuide.forPlan(_plan);
      _session['cube_guide'] = _cubeGuide!.toJson();
      _session['frames'] ??= <dynamic>[];
      _session['mode'] ??= 'photos';
      await _persist();
      if (!_current || generation != _cameraGeneration || _camera != c) {
        return;
      }
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      try {
        _orientation = _events.receiveBroadcastStream().listen(
          (event) {
            if (!mounted ||
                !_current ||
                generation != _cameraGeneration ||
                _camera != c) {
              return;
            }
            if (event is! Map ||
                event['yaw'] is! num ||
                event['pitch'] is! num ||
                event['roll'] is! num) {
              _resetMotion();
              return;
            }
            final rawYaw = (event['yaw'] as num).toDouble();
            final p = (event['pitch'] as num).toDouble();
            final r = (event['roll'] as num).toDouble();
            if (!rawYaw.isFinite || !p.isFinite || !r.isFinite) {
              _resetMotion();
              return;
            }
            final now = DateTime.now();
            final y = normalizeYaw(rawYaw + _yawOffset);
            _motionGate.update(yaw: y, pitch: p, target: _target, now: now);
            setState(() {
              _yaw = y;
              _rawYaw = rawYaw;
              _pitch = p;
              _roll = r;
              final heading = event['headingReady'];
              _headingReady = heading is bool
                  ? heading
                  : (_headingReady || p.abs() < 89.5);
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
              setState(() {});
            }
          },
        );
        await _motion.invokeMethod('start');
      } catch (_) {
        await _orientation?.cancel();
        _orientation = null;
        _resetMotion();
      }
      if (!_current || generation != _cameraGeneration || _camera != c) {
        return;
      }
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _release();
        return;
      }
      _motionReadiness = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _refreshReadiness(),
      );
    } catch (e) {
      await _release();
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _align() async {
    final camera = _camera;
    final reference = _reference;
    if (_busy || camera == null || reference == null) return;
    final generation = _cameraGeneration;
    bool canAlign() =>
        _current &&
        generation == _cameraGeneration &&
        _camera == camera &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!canAlign()) return;
    if (!_motionGate.isFresh(DateTime.now()) || !_headingReady) {
      setState(() {
        _showReference = false;
        _error =
            'Puedes seguir tomando fotos. La referencia necesita una lectura de orientación reciente.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final offset = (reference['yaw'] as num).toDouble() - _rawYaw;
    final previous = _session;
    try {
      _session = {
        ..._session,
        'frames': alignCaptureFrames(
          _frames,
          motionSession: _motionSession,
          yawOffset: offset,
          plan: _plan,
        ),
      };
      await _persist();
      if (!canAlign()) return;
      setState(() {
        _yawOffset = offset;
        _yaw = normalizeYaw(_rawYaw + offset);
        _aligned = true;
        _showReference = false;
        _autoPaused = false;
        _resetMotion();
      });
    } catch (e) {
      _session = previous;
      if (canAlign()) {
        _resetMotion();
        setState(() => _error = tourError(e));
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
    unawaited(
      _shutter.tick(
        active:
            !_busy &&
            _current &&
            _camera != null &&
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
        ready:
            _aligned &&
            _headingReady &&
            _lensHfov != null &&
            _lensVfov != null &&
            steady &&
            _target != null,
        capture: _take,
      ),
    );
  }

  Future<void> _take() async {
    final camera = _camera;
    if (_busy ||
        !_current ||
        camera == null ||
        !camera.value.isInitialized ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        (_automatic &&
            (!_aligned ||
                !_headingReady ||
                !_aimed ||
                !_steady ||
                _target == null))) {
      return;
    }
    setState(() => _busy = true);
    final suggestedStep = !_automatic ? _cubeStep : null;
    final measured =
        _headingReady &&
        _motionGate.isFresh(DateTime.now()) &&
        _rawYaw.isFinite &&
        _pitch.isFinite &&
        _roll.isFinite;
    final pose = <String, dynamic>{
      'pose_status': measured
          ? _aligned
                ? 'ready'
                : 'needs_reference'
          : 'unavailable',
      'pose_session': _motionSession,
      if (measured) ...{
        'sensor_yaw': _rawYaw,
        'pitch': _pitch,
        'roll': _roll,
        if (_aligned) 'yaw': _yaw,
      },
      if (_lensHfov != null) 'hfov': _lensHfov,
      if (_lensVfov != null) 'vfov': _lensVfov,
    };
    final target = measured && _aligned
        ? findCaptureTarget(
            plan: _plan,
            frames: _frames,
            yaw: _yaw,
            pitch: _pitch,
          )
        : null;
    try {
      final photo = await camera.takePicture();
      final prepared = await compute(_preparePhoto, await photo.readAsBytes());
      if (!mounted || !_current) return;
      final id = tourId();
      final local = await _store.saveBytes(
        _account,
        id,
        prepared['bytes'] as Uint8List,
      );
      final frame = {
        'id': id,
        'local_path': local,
        'width': prepared['width'],
        'height': prepared['height'],
        ...pose,
        if (suggestedStep != null) ...{
          'cube_guide_version': CaptureCubeGuide.version,
          'cube_guide_step': suggestedStep.target.id,
        },
        if (target != null) 'target_id': target.id,
      };
      _frames.add(frame);
      try {
        await _persist();
      } catch (_) {
        _frames.remove(frame);
        rethrow;
      }
      _resetMotion();
      if (_current &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_signalPhotoSaved());
      }
    } catch (e) {
      if (_current) {
        setState(() {
          _error = tourError(e);
          _autoPaused = true;
        });
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _signalPhotoSaved() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics are optional; a saved photo must stay accepted if unavailable.
    }
  }

  Future<void> _chooseSource() async {
    if (_busy || _restoring || !_current) return;
    if (kIsWeb || widget.importOnly) return _import();
    final source = await showModalBottomSheet<_PanoramaSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar fotos'),
              subtitle: const Text('Captura a tu ritmo con una guía opcional.'),
              onTap: () => Navigator.pop(context, _PanoramaSource.capture),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Importar desde galería'),
              subtitle: const Text(
                'Elige una foto 360°. Comprobaremos si es compatible.',
              ),
              onTap: () => Navigator.pop(context, _PanoramaSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!_current) return;
    switch (source) {
      case _PanoramaSource.capture:
        await _openCamera();
      case _PanoramaSource.gallery:
        await _import();
      case null:
        break;
    }
  }

  Future<void> _import() async {
    if (_busy || _restoring || !_current) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _release();
      if (!_current) return;
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !_current) return;
      if (await picked.length() > panoramaImportMaxBytes) {
        throw StateError(
          'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.',
        );
      }
      final bytes = await picked.readAsBytes();
      final info = await compute(inspectPanoramaImport, bytes);
      if (!mounted || !_current) return;
      if (_frames.isNotEmpty && !_missingWebFile) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usar este panorama'),
            content: Text(
              _session['mode'] == 'import'
                  ? 'El panorama anterior quedará en Capturas anteriores.'
                  : 'Las ${_frames.length} tomas de esta captura quedarán en Capturas anteriores.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Conservar captura'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Usar panorama'),
              ),
            ],
          ),
        );
        if (replace != true || !_current) return;
      }
      final id = tourId();
      final path = await _store.saveBytes(_account, id, bytes);
      if (!_current) return;
      await CaptureHistory(
        _store,
      ).archive(_account, widget.sceneId, _session, isCurrent: () => _current);
      if (!_current) return;
      final previous = _session;
      _session = {
        'mode': 'import',
        if (info.horizontal) 'panorama_kind': 'horizontal',
        'frames': [
          {
            'id': id,
            'local_path': path,
            'width': info.width,
            'height': info.height,
            if (!info.horizontal) ...{
              'yaw': 0,
              'pitch': 0,
              'roll': 0,
              'hfov': 360,
              'vfov': 180,
            },
            'target_id': 'import',
          },
        ],
      };
      try {
        await _persist();
      } catch (_) {
        _session = previous;
        rethrow;
      }
      _plan = null;
      _missingWebFile = false;
      _importPreview = Future.value(bytes);
      _cubeGuide = null;
      _job = null;
      _poll?.cancel();
      _reviewed = false;
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!widget.controller.allowCaptureUploads || _busy || _frames.isEmpty) {
      return;
    }
    final sending = _processingFrames;
    if (_session['mode'] != 'import' &&
        (sending.length < 6 || sending.length > 96)) {
      setState(
        () => _error =
            'Puedes guardar todas tus fotos. Para preparar el panorama hacen falta entre 6 y 96 fotos con orientación y datos de lente disponibles.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = widget.controller.tourRepository!;
    TourTusUploader? uploader;
    try {
      await _release();
      if (!_current) return;
      if (_horizontalImport && !await repo.supportsHorizontalPanoramas()) {
        throw StateError(
          'La panorámica está guardada. La subida de panorámicas horizontales aún no está disponible.',
        );
      }
      if (!_current) return;
      uploader = repo.uploader();
      _session['capture_id'] ??= await repo.beginCapture(
        widget.tourId,
        widget.sceneId,
        _session['mode'] as String? ?? 'photos',
      );
      await _persist();
      for (var i = 0; i < sending.length; i++) {
        if (!mounted || !_current) return;
        final frame = sending[i];
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
            if (_current) setState(() => _upload = (i + v) / sending.length);
          },
        );
        frame['path'] = remote;
        await _persist();
      }
      final manifest = {
        'mode': _session['mode'] ?? 'photos',
        if (_horizontalImport) 'panorama_kind': 'horizontal',
        'frames': sending
            .map(
              (f) => Map<String, dynamic>.from(f as Map)
                ..remove('local_path')
                ..remove('upload')
                ..remove('pose_status')
                ..remove('pose_session')
                ..remove('sensor_yaw')
                ..remove('cube_guide_version')
                ..remove('cube_guide_step'),
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
      if (_current) setState(() => _error = tourError(e));
    } finally {
      uploader?.dispose();
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
        if (_current) setState(() => _error = tourError(e));
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
    _autoPaused = true;
    _aligned = false;
    final c = _camera;
    _camera = null;
    final orientation = _orientation;
    _orientation = null;
    await orientation?.cancel();
    try {
      await _motion.invokeMethod('stop');
    } catch (_) {}
    await c?.dispose();
  }

  Future<void> _captureAction(_CaptureAction action) async {
    if (_busy || _restoring || !_current) return;
    try {
      switch (action) {
        case _CaptureAction.import:
          await _import();
        case _CaptureAction.repeat:
          _autoPaused = true;
          _frames.removeLast();
          _resetMotion();
          await _persist();
          if (_current) setState(() {});
        case _CaptureAction.restart:
          final restart = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Empezar otra captura'),
              content: const Text(
                'La captura actual se conservará en Capturas anteriores. La nueva empieza sin fotos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Conservar tomas'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Empezar otra'),
                ),
              ],
            ),
          );
          if (restart != true || !_current) return;
          await _startNewCapture();
        case _CaptureAction.manual:
          setState(() {
            _automatic = !_automatic;
            _autoPaused = false;
            _resetMotion();
            if (_automatic && !_aligned && _reference != null) {
              _showReference = true;
              _autoPaused = true;
            }
          });
        case _CaptureAction.reference:
          setState(() {
            _showReference = true;
            _autoPaused = true;
          });
        case _CaptureAction.angles:
          setState(() => _showAngles = !_showAngles);
        case _CaptureAction.close:
          await _release();
          if (_current) setState(() {});
        case _CaptureAction.history:
          await _showCaptureHistory();
      }
    } catch (error) {
      if (_current) {
        setState(() {
          _error = tourError(error);
          _autoPaused = true;
        });
      }
    }
  }

  Future<void> _startNewCapture() async {
    if (_busy || !_current) return;
    setState(() => _busy = true);
    try {
      await _release();
      if (!_current) return;
      await CaptureHistory(
        _store,
      ).archive(_account, widget.sceneId, _session, isCurrent: () => _current);
      if (!_current) return;
      final previous = _session;
      _session = {};
      try {
        await _persist();
      } catch (_) {
        _session = previous;
        rethrow;
      }
      if (!_current) return;
      _cubeGuide = null;
      _plan = null;
      _job = null;
      _poll?.cancel();
      _missingWebFile = false;
      _showReference = false;
      _reviewed = false;
      _error = null;
    } catch (error) {
      if (_current) _error = tourError(error);
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _showCaptureHistory() async {
    await _release();
    if (!_current) return;
    setState(() {});
    final entries = await CaptureHistory(
      _store,
    ).list(_account, widget.sceneId, isCurrent: () => _current);
    if (!_current || !mounted) return;
    final chosen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Capturas anteriores'),
              subtitle: Text('Tus fotos se conservan en este dispositivo.'),
            ),
            if (entries.isEmpty)
              const ListTile(
                title: Text('Todavía no hay capturas anteriores.'),
              ),
            for (final entry in entries)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  '${((entry['session'] as Map)['frames'] as List? ?? []).length} fotos',
                ),
                subtitle: Text(() {
                  final date = DateTime.tryParse(
                    entry['saved_at'] as String? ?? '',
                  )?.toLocal();
                  return date == null
                      ? 'Captura guardada'
                      : '${MaterialLocalizations.of(context).formatShortDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}';
                }()),
                trailing: const Text('Retomar'),
                onTap: () => Navigator.pop(context, entry),
              ),
          ],
        ),
      ),
    );
    if (!_current || chosen == null) return;
    final restored = jsonMap(chosen['session']);
    final jobId = restored['job_id'];
    final restoredJob = jobId is String
        ? await widget.controller.tourRepository!.job(jobId)
        : null;
    if (!_current) return;
    await CaptureHistory(
      _store,
    ).archive(_account, widget.sceneId, _session, isCurrent: () => _current);
    if (!_current) return;
    final previous = _session;
    _session = restored;
    try {
      await _persist();
    } catch (_) {
      _session = previous;
      rethrow;
    }
    if (!_current) return;
    _plan = _session['plan'] is Map
        ? CapturePlan.fromJson(jsonMap(_session['plan']))
        : null;
    _cubeGuide = CaptureCubeGuide.restore(_session['cube_guide']);
    _importPreview = null;
    _missingWebFile = false;
    _reviewed = false;
    _poll?.cancel();
    _job = restoredJob;
    if (_job != null) _watch();
    _showReference = false;
    setState(() {});
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
    final c = _camera;
    final resuming =
        c != null &&
        c.value.isInitialized &&
        _showReference &&
        _reference != null &&
        _session['mode'] != 'import' &&
        _frames.isNotEmpty;
    var referenceAspect = .75;
    if (resuming) {
      final width = (_reference!['width'] as num?)?.toDouble();
      final height = (_reference!['height'] as num?)?.toDouble();
      if (width != null && height != null && width > 0 && height > 0) {
        referenceAspect = width / height;
      }
    }
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(
          fallback: '/tours/${widget.tourId}/edit',
          onPressed: resuming
              ? () => setState(() {
                  _showReference = false;
                  if (!_aligned) _automatic = false;
                })
              : null,
        ),
        title: const Text('Fotos para el panorama'),
        actions: [
          if (c != null && !resuming)
            IconButton(
              tooltip: 'Terminar fotos',
              icon: const Icon(Icons.check),
              onPressed: _busy
                  ? null
                  : () async {
                      await _release();
                      if (_current) setState(() {});
                    },
            ),
          if (_job == null)
            PopupMenuButton<_CaptureAction>(
              tooltip: 'Más opciones de captura',
              enabled: !_busy && !_restoring,
              onOpened: () => setState(() => _autoPaused = true),
              onSelected: _captureAction,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _CaptureAction.history,
                  child: Text('Capturas anteriores'),
                ),
                PopupMenuItem(
                  value: _CaptureAction.import,
                  child: Text(
                    _session['mode'] == 'import'
                        ? 'Cambiar panorama'
                        : 'Importar desde galería',
                  ),
                ),
                if (_frames.isNotEmpty && _session['mode'] != 'import')
                  const PopupMenuItem(
                    value: _CaptureAction.repeat,
                    child: Text('Repetir última toma'),
                  ),
                if (_frames.isNotEmpty)
                  const PopupMenuItem(
                    value: _CaptureAction.restart,
                    child: Text('Empezar otra captura'),
                  ),
                if (c != null) ...[
                  if (_reference != null)
                    const PopupMenuItem(
                      value: _CaptureAction.reference,
                      child: Text('Usar foto inicial como referencia'),
                    ),
                  PopupMenuItem(
                    value: _CaptureAction.manual,
                    child: Text(
                      _automatic
                          ? 'Usar captura manual'
                          : 'Usar captura automática',
                    ),
                  ),
                  PopupMenuItem(
                    value: _CaptureAction.angles,
                    child: Text(
                      _showAngles ? 'Ocultar orientación' : 'Ver orientación',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _CaptureAction.close,
                    child: Text('Cerrar cámara'),
                  ),
                ],
              ],
            ),
        ],
      ),
      bottomNavigationBar: c != null && c.value.isInitialized && !resuming
          ? CaptureGuidancePanel(
              target: _target,
              yaw: _yaw,
              pitch: _pitch,
              fresh: _headingReady && _motionGate.isFresh(DateTime.now()),
              aimed: _aimed,
              steady: _steady,
              busy: _busy,
              onTake: _take,
              automatic: _automatic,
              paused: _autoPaused,
              showAngles: _showAngles,
              onTogglePause: () => setState(() {
                _autoPaused = !_autoPaused;
                _resetMotion();
              }),
              cubeGuide: _cubeGuide,
              guideIndex: _cubeGuideIndex,
            )
          : null,
      body: resuming
          ? Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TourNotice(_error!),
                  ),
                Expanded(
                  child: CaptureResumePhoto(
                    store: _store,
                    path: _reference!['local_path'] as String,
                    livePreview: CameraPreview(c),
                    aspectRatio: referenceAspect,
                    counterLabel: '${_frames.length} fotos guardadas',
                    busy: _busy,
                    onAlign: _align,
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _session['mode'] == 'import'
                      ? _horizontalImport
                            ? 'Revisa la panorámica elegida antes de subirla. Puedes recorrerla de izquierda a derecha.'
                            : 'Revisa el panorama elegido antes de subirlo. Después del procesamiento podrás comprobar la costura, el techo y el piso.'
                      : c != null
                      ? 'Gira sobre el mismo punto, sin caminar. El centro es tu referencia.'
                      : 'Empieza al frente, a la altura de tus ojos. El cubo te indicará qué lado fotografiar, siempre desde el centro.',
                ),
                const SizedBox(height: 12),
                if (_error != null) TourNotice(_error!),
                if (_job != null) ...[
                  Text(
                    _job!.message,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!_job!.terminal) const LinearProgressIndicator(),
                  if (_job!.state == 'ready') ...[
                    SizedBox(
                      height: 320,
                      child: TourPanorama(
                        repository: widget.controller.tourRepository!,
                        scene: TourScene({
                          'id': widget.sceneId,
                          'name': 'Panorama procesado',
                          ...jsonMap(_job!.data['result']),
                          'points': [],
                          'connections': [],
                        }),
                      ),
                    ),
                    CheckboxListTile(
                      value: _reviewed,
                      onChanged: (v) => setState(() => _reviewed = v ?? false),
                      title: Text(
                        _job!.data['result']?['panorama_kind'] == 'horizontal'
                            ? 'Revisé la panorámica de izquierda a derecha y se ve correctamente.'
                            : 'Revisé la costura, el techo y el piso sin huecos ni errores visibles.',
                      ),
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
                                  setState(() => _error = tourError(e));
                                }
                              } finally {
                                if (_current) setState(() => _busy = false);
                              }
                            },
                      child: const Text('Usar panorama revisado'),
                    ),
                  ],
                  if (!_job!.terminal)
                    OutlinedButton(
                      onPressed: () async {
                        await widget.controller.tourRepository!.cancelJob(
                          _job!.id,
                        );
                        if (mounted && _current) {
                          setState(
                            () => _job = TourJob({
                              ..._job!.data,
                              'state': 'cancelled',
                            }),
                          );
                        }
                      },
                      child: const Text('Cancelar procesamiento'),
                    ),
                  if (_job!.terminal && _job!.state != 'ready')
                    OutlinedButton(
                      onPressed: _busy ? null : _startNewCapture,
                      child: const Text('Preparar nueva captura'),
                    ),
                ] else ...[
                  if (_missingWebFile) ...[
                    const TourNotice(
                      'El navegador no conserva este archivo al cerrar la pantalla. Elige el panorama de nuevo para iniciar otra subida.',
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _import,
                      child: const Text('Volver a elegir panorama'),
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
                                !_automatic
                                    ? _cubeStep != null
                                          ? '${_cubeStep!.faceLabel} · ${_cubeStep!.zoneLabel}'
                                          : 'Puedes seguir tomando fotos libremente'
                                    : _target == null
                                    ? 'Puedes seguir tomando fotos'
                                    : !_motionFresh
                                    ? 'Esperando orientación del teléfono'
                                    : _aimed
                                    ? 'Mantén el teléfono estable'
                                    : _showAngles
                                    ? 'Apunta a ${_target!.yaw.toStringAsFixed(0)}° · inclinación ${_target!.pitch.toStringAsFixed(0)}°'
                                    : 'Sigue la guía para la siguiente foto',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_session['mode'] != 'import')
                    Text('${_frames.length} fotos guardadas'),
                  if (_showAngles && _plan != null)
                    Text(
                      'Guía opcional: ${_coveredTargets.length} de ${_plan!.targets.length} direcciones',
                    ),
                  if (c == null && _frames.isEmpty && !_missingWebFile)
                    FilledButton(
                      onPressed: _busy || _restoring ? null : _chooseSource,
                      child: Text(
                        _restoring ? 'Preparando captura…' : 'Añadir panorama',
                      ),
                    ),
                  if (c == null &&
                      _frames.isNotEmpty &&
                      !kIsWeb &&
                      !widget.importOnly &&
                      _session['mode'] != 'import')
                    FilledButton(
                      onPressed: _busy || _restoring ? null : _openCamera,
                      child: const Text('Retomar captura'),
                    ),
                  if (_session['mode'] == 'import' &&
                      _frames.isNotEmpty &&
                      !_missingWebFile) ...[
                    Text(
                      '${_horizontalImport ? 'Panorámica horizontal elegida' : 'Panorama 360° elegido'} · ${_frames.first['width']} × ${_frames.first['height']}',
                    ),
                    SizedBox(
                      height: 240,
                      child: FutureBuilder<Uint8List>(
                        future: _importPreview ??= _store.readBytes(
                          _frames.first['local_path'] as String,
                        ),
                        builder: (context, snapshot) => snapshot.hasData
                            ? _horizontalImport
                                  ? HorizontalPanorama(
                                      image: MemoryImage(snapshot.data!),
                                      aspectRatio:
                                          (_frames.first['width'] as num) /
                                          (_frames.first['height'] as num),
                                    )
                                  : Image.memory(
                                      snapshot.data!,
                                      cacheWidth: 1200,
                                      fit: BoxFit.contain,
                                    )
                            : snapshot.hasError
                            ? const TourNotice(
                                'No pudimos abrir el archivo local. Elígelo de nuevo en Más opciones.',
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                  if (_frames.isNotEmpty &&
                      c == null &&
                      _session['mode'] != 'import' &&
                      _processingFrames.length < _frames.length)
                    TourNotice(
                      'Se prepararán ${_processingFrames.length} fotos con orientación disponible. Las demás quedan guardadas aquí. Puedes usar la foto inicial desde Más opciones para recuperar la dirección de las fotos de esta sesión.',
                    ),
                  if (_frames.isNotEmpty && c == null)
                    FilledButton(
                      onPressed:
                          _busy ||
                              _missingWebFile ||
                              !widget.controller.allowCaptureUploads
                          ? null
                          : _send,
                      child: Text(
                        _busy
                            ? 'Subiendo ${(_upload * 100).toStringAsFixed(0)} %'
                            : _session['mode'] == 'import'
                            ? 'Subir panorámica'
                            : 'Preparar panorama (${_processingFrames.length} fotos)',
                      ),
                    ),
                  TourNotice(
                    !widget.controller.allowCaptureUploads
                        ? 'Esta prueba guarda las fotos sólo en el teléfono. La preparación y el envío están desactivados.'
                        : kIsWeb
                        ? 'Mantén esta pantalla abierta durante la subida. Si la cierras, tendrás que elegir el archivo de nuevo. El procesamiento empieza tras confirmar la subida completa.'
                        : 'Tus fotos se guardan en este dispositivo. Al preparar el panorama se comprobará la unión de las imágenes.',
                  ),
                ],
              ],
            ),
    );
  }
}
