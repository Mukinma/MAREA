import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:photo_manager/photo_manager.dart';

class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  String? _error;
  bool _loading = true;
  bool _capturing = false;
  bool _pickingGallery = false;
  bool _initializing = false;
  bool _switchingCamera = false;
  FlashMode _flash = FlashMode.off;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  Uint8List? _latestGalleryPhoto;
  int _initializationGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _loadLatestGalleryPhoto();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initializationGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _initializationGeneration++;
      final controller = _controller;
      _controller = null;
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (_initializing || !mounted) return;
    _initializing = true;
    final generation = ++_initializationGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw StateError('No encontramos una cámara disponible.');
      }
      _cameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == _lensDirection,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || generation != _initializationGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _zoom = _minZoom;
        _loading = false;
      });
      unawaited(_configureCamera(controller));
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.code == 'CameraAccessDenied'
            ? 'Necesitamos permiso para usar la cámara. Actívalo en Ajustes.'
            : 'No pudimos abrir la cámara. Inténtalo nuevamente.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _configureCamera(CameraController controller) async {
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted || !identical(_controller, controller)) return;
      _minZoom = minZoom;
      _maxZoom = maxZoom;
      setState(() => _zoom = minZoom);
    } catch (error) {
      debugPrint('No pudimos configurar el zoom de la cámara: $error');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final prepared = await ProfileImagePicker.prepare(bytes, avatar: false);
      if (mounted) Navigator.of(context).pop<Uint8List>(prepared);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos capturar la foto. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _loadLatestGalleryPhoto() async {
    if (kIsWeb) return;
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) return;
      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      if (albums.isEmpty) return;
      final assets = await albums.first.getAssetListPaged(page: 0, size: 1);
      if (assets.isEmpty) return;
      final thumbnail = await assets.first.thumbnailDataWithSize(
        const ThumbnailSize(160, 160),
      );
      if (mounted && thumbnail != null) {
        setState(() => _latestGalleryPhoto = thumbnail);
      }
    } catch (error) {
      debugPrint('No pudimos cargar la miniatura de la galería: $error');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_capturing || _pickingGallery) return;
    setState(() => _pickingGallery = true);
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
      if (mounted) Navigator.of(context).pop<Uint8List>(image);
    } catch (error) {
      debugPrint('No pudimos seleccionar la foto de la galería: $error');
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir esa foto. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _pickingGallery = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _capturing ||
        _switchingCamera ||
        _initializing) {
      return;
    }
    final nextDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final nextIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection == nextDirection,
    );
    if (nextIndex < 0) return;
    _switchingCamera = true;
    _lensDirection = nextDirection;
    _cameraIndex = nextIndex;
    _initializationGeneration++;
    final current = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    await current?.dispose();
    if (mounted) await _initialize();
    _switchingCamera = false;
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.off,
    };
    await controller.setFlashMode(next);
    if (mounted) setState(() => _flash = next);
  }

  @override
  Widget build(BuildContext context) {
    final camera = _controller;
    final Widget preview;
    if (camera?.value.isInitialized == true) {
      preview = GestureDetector(
        onDoubleTap: _switchCamera,
        onScaleUpdate: (details) {
          final next = (_zoom * details.scale).clamp(_minZoom, _maxZoom);
          camera?.setZoomLevel(next);
          setState(() => _zoom = next);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ClipRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxHeight / camera!.value.aspectRatio,
                    height: constraints.maxHeight,
                    child: CameraPreview(camera),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else if (_loading) {
      preview = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else {
      preview = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error ?? 'No pudimos abrir la cámara.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            preview,
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(Icons.close, () => Navigator.of(context).pop()),
                  const Text(
                    'HISTORIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  _roundButton(
                    _flash == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    _cycleFlash,
                    tooltip: 'Cambiar flash',
                  ),
                  _roundButton(
                    Icons.flip_camera_ios,
                    _switchCamera,
                    tooltip: 'Cambiar cámara',
                  ),
                ],
              ),
            ),
            if (_error != null && camera?.value.isInitialized == true)
              Positioned(
                left: 20,
                right: 20,
                bottom: 150,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _capture,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _capturing ? 68 : 78,
                  height: _capturing ? 68 : 78,
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.aqua, width: 5),
                  ),
                  child: _capturing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 42,
              left: 28,
              child: Semantics(
                button: true,
                label: 'Abrir galería',
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                      border: Border.all(color: Colors.white, width: 2),
                      image: _latestGalleryPhoto == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(_latestGalleryPhoto!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: _latestGalleryPhoto == null
                        ? const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton(
    IconData icon,
    VoidCallback onPressed, {
    String? tooltip,
  }) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.black54,
      shape: BoxShape.circle,
    ),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip ?? (icon == Icons.close ? 'Cerrar' : 'Cambiar cámara'),
    ),
  );
}
