import 'dart:async';
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
  DateTime? _stableSince, _lastMotion;
  Timer? _poll;
  int _cameraGeneration = 0;
  bool _reviewed = false;
  bool get _current => mounted && widget.controller.profile?.id == _account;
  List<dynamic> get _frames => (_session['frames'] as List?) ?? [];
  CaptureTarget? get _target => _plan?.targets
      .where((t) => !_frames.any((f) => f['target_id'] == t.id))
      .firstOrNull;
  bool get _aimed =>
      _target != null &&
      angularDistance(_yaw, _pitch, _target!.yaw, _target!.pitch) < 6;
  bool get _steady =>
      _lastMotion != null &&
      DateTime.now().difference(_lastMotion!).inMilliseconds < 300 &&
      _stableSince != null &&
      DateTime.now().difference(_stableSince!).inMilliseconds >= 500;
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
      if (_current) setState(() => _error = tourError(e));
    }
  }

  Future<void> _openCamera() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final generation = ++_cameraGeneration;
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
      _orientation = _events.receiveBroadcastStream().listen(
        (event) {
          if (!mounted || !_current) return;
          final now = DateTime.now();
          final y = normalizeYaw((event['yaw'] as num).toDouble() + _yawOffset),
              p = (event['pitch'] as num).toDouble();
          if (angularDistance(_yaw, _pitch, y, p) > 1.5 || !_aimed) {
            _stableSince = null;
          }
          _lastMotion = now;
          _stableSince ??= now;
          setState(() {
            _yaw = y;
            _pitch = p;
            _roll = (event['roll'] as num).toDouble();
          });
        },
        onError: (Object e) {
          if (mounted && _current) {
            setState(
              () => _error =
                  'No pudimos leer la orientación. Puedes importar un panorama.',
            );
          }
        },
      );
      await _motion.invokeMethod('start');
      _aligned = _frames.isEmpty;
      if (_frames.isNotEmpty) {
        _yawOffset = (_frames.first['yaw'] as num).toDouble();
      }
    } catch (e) {
      await _release();
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _align() async {
    await _motion.invokeMethod('stop');
    await _motion.invokeMethod('start');
    if (mounted && _current) {
      setState(() {
        _aligned = true;
        _stableSince = null;
      });
    }
  }

  Future<void> _take() async {
    final target = _target;
    if (_busy || !_aligned || !_aimed || !_steady || target == null) return;
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
      _stableSince = null;
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final decoded = await compute(img.decodeImage, bytes);
      if (decoded == null || decoded.width != decoded.height * 2) {
        throw StateError(
          'Elige una esfera equirectangular completa de proporción 2:1, con metadatos GPano.',
        );
      }
      if (bytes.length > 32 * 1024 * 1024) {
        throw StateError(
          'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.',
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
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _frames.isEmpty) return;
    if (_session['mode'] != 'import' && _target != null) return;
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
      if (_current) setState(() => _error = tourError(e));
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
        if (_current) setState(() => _error = tourError(e));
      } finally {
        _searching = false;
      }
    });
  }

  Future<void> _release() async {
    _cameraGeneration++;
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
    final c = _camera;
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(fallback: '/tours/${widget.tourId}/edit'),
        title: const Text('Capturar posición 360°'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Quédate en la misma posición. Gira alrededor de la lente, sin caminar, e incluye techo y piso. Evita personas identificables y objetos demasiado cerca.',
          ),
          const SizedBox(height: 12),
          if (_error != null) TourNotice(_error!),
          if (_job != null) ...[
            Text(
              _job!.message,
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
                title: const Text(
                  'Revisé la costura, el techo y el piso sin huecos ni errores visibles.',
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
                          if (_current) setState(() => _error = tourError(e));
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
                  await widget.controller.tourRepository!.cancelJob(_job!.id);
                  if (mounted && _current) {
                    setState(
                      () =>
                          _job = TourJob({..._job!.data, 'state': 'cancelled'}),
                    );
                  }
                },
                child: const Text('Cancelar procesamiento'),
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
                child: const Text('Preparar nueva captura'),
              ),
          ] else ...[
            if (_missingWebFile) ...[
              const TourNotice(
                'El navegador no conserva este archivo al cerrar la pantalla. Elige el panorama de nuevo para iniciar otra subida.',
              ),
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
                          _target == null
                              ? 'Captura completa'
                              : _aimed
                              ? 'Mantén el teléfono estable'
                              : 'Apunta a ${_target!.yaw.toStringAsFixed(0)}° · inclinación ${_target!.pitch.toStringAsFixed(0)}°',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_plan != null)
              Text(
                '${_frames.length} de ${_plan!.targets.length} tomas aceptadas',
              ),
            if (c != null && !_aligned && _frames.isNotEmpty) ...[
              const TourNotice(
                'Vuelve al mismo lugar. Alinea la cámara con esta primera fotografía para recuperar la dirección.',
              ),
              FutureBuilder<Uint8List>(
                future: _store.readBytes(_frames.first['local_path'] as String),
                builder: (c, s) => s.hasData
                    ? SizedBox(height: 160, child: Image.memory(s.data!))
                    : const SizedBox(),
              ),
              FilledButton(
                onPressed: _align,
                child: const Text('Ya alineé la primera toma'),
              ),
            ],
            if (c != null && _aligned && _target != null)
              FilledButton(
                onPressed: _busy || !_aimed || !_steady ? null : _take,
                child: const Text('Aceptar toma'),
              ),
            if (_frames.isNotEmpty && _session['mode'] != 'import')
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        _frames.removeLast();
                        await _persist();
                        if (_current) setState(() {});
                      },
                child: const Text('Repetir última toma'),
              ),
            if (_frames.isNotEmpty)
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final restart = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Empezar otra captura'),
                            content: const Text(
                              'Las tomas actuales dejarán de formar parte de esta posición. La versión publicada se conserva.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Conservar tomas'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Empezar otra'),
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
                child: const Text('Empezar otra captura'),
              ),
            if (c == null &&
                !kIsWeb &&
                !widget.importOnly &&
                _session['mode'] != 'import')
              FilledButton(
                onPressed: _busy ? null : _openCamera,
                child: Text(
                  _frames.isEmpty ? 'Abrir cámara guiada' : 'Retomar captura',
                ),
              ),
            if (_frames.isEmpty)
              OutlinedButton(
                onPressed: _busy ? null : _import,
                child: const Text('Importar panorama esférico'),
              ),
            if (_frames.isNotEmpty &&
                (_session['mode'] == 'import' || _target == null))
              FilledButton(
                onPressed: _busy || _missingWebFile ? null : _send,
                child: Text(
                  _busy
                      ? 'Subiendo ${(_upload * 100).toStringAsFixed(0)} %'
                      : 'Subir y procesar panorama',
                ),
              ),
            TourNotice(
              kIsWeb
                  ? 'Mantén esta pantalla abierta durante la subida. Si la cierras, tendrás que elegir el archivo de nuevo. El procesamiento empieza tras confirmar la subida completa.'
                  : 'Las tomas aceptadas se guardan en este dispositivo. El procesamiento empieza después de confirmar la subida completa.',
            ),
          ],
        ],
      ),
    );
  }
}
