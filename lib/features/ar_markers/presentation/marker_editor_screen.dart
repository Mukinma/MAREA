import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../data/marker_repository.dart';
import '../models/ar_marker.dart';

/// Reads dimensions before decoding pixels, then strips metadata from the JPEG.
Uint8List prepareMarkerImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw StateError('Elige una imagen de hasta 10 MB.');
  }
  try {
    final decoder = image.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null) {
      throw StateError('No pudimos leer la imagen. Elige un JPG, PNG o WebP.');
    }
    if (info.width < 64 ||
        info.height < 64 ||
        info.width > 8192 ||
        info.height > 8192 ||
        info.width * info.height > 24000000) {
      throw StateError(
        'Elige una imagen de entre 64 píxeles y 24 megapíxeles.',
      );
    }
    final decoded = decoder!.decodeFrame(0);
    if (decoded == null) {
      throw StateError(
        'No pudimos leer la imagen. Prueba con otra fotografía.',
      );
    }
    final oriented = image.bakeOrientation(decoded);
    final resized = oriented.width > 1600 || oriented.height > 1600
        ? image.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1600 : null,
            height: oriented.height > oriented.width ? 1600 : null,
          )
        : oriented;
    final jpeg = Uint8List.fromList(image.encodeJpg(resized, quality: 90));
    if (jpeg.length > 4 * 1024 * 1024) {
      throw StateError(
        'La imagen sigue siendo muy pesada. Elige otra más pequeña.',
      );
    }
    return jpeg;
  } on StateError {
    rethrow;
  } catch (_) {
    throw StateError('No pudimos leer la imagen. Elige un JPG, PNG o WebP.');
  }
}

class MarkerEditorScreen extends StatefulWidget {
  const MarkerEditorScreen({
    required this.controller,
    required this.repository,
    this.markerId,
    this.locationService = const GeolocatorDeviceLocationService(),
    super.key,
  });

  final AppSessionController controller;
  final MarkerRepository repository;
  final String? markerId;
  final DeviceLocationService locationService;

  @override
  State<MarkerEditorScreen> createState() => _MarkerEditorScreenState();
}

class _MarkerEditorScreenState extends State<MarkerEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _menuUrl = TextEditingController();
  final _width = TextEditingController(text: '20');
  late final String? _owner = widget.controller.profile?.id;
  ArMarker? _marker;
  Uint8List? _draftImage;
  Future<Uint8List>? _existingImage;
  String? _error, _saved;
  double? _latitude, _longitude, _accuracy;
  bool _locationExact = false, _active = false;
  bool _loading = false, _saving = false, _picking = false, _locating = false;
  bool _accountEnded = false;
  bool _unavailable = false;

  bool get _current =>
      mounted &&
      !_accountEnded &&
      _owner != null &&
      widget.controller.profile?.id == _owner;
  bool get _busy => _loading || _saving || _picking || _locating;
  double? get _widthCm =>
      double.tryParse(_width.text.trim().replaceAll(',', '.'));
  bool get _tested =>
      _marker?.isTested == true &&
      _draftImage == null &&
      _widthCm == _marker!.widthCm;
  bool get _exactLocation =>
      _locationExact &&
      _latitude != null &&
      _longitude != null &&
      _latitude!.isFinite &&
      _longitude!.isFinite &&
      _latitude! >= -90 &&
      _latitude! <= 90 &&
      _longitude! >= -180 &&
      _longitude! <= 180 &&
      _accuracy != null &&
      _accuracy!.isFinite &&
      _accuracy! >= 0 &&
      _accuracy! <= 20;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_accountChanged);
    if (_owner != null && widget.markerId != null) _load();
  }

  void _accountChanged() {
    if (_owner == widget.controller.profile?.id) return;
    setState(() {
      _accountEnded = true;
      _marker = null;
      _draftImage = null;
      _existingImage = null;
      _latitude = _longitude = _accuracy = null;
      _active = false;
      for (final input in [_name, _description, _menuUrl, _width]) {
        input.clear();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final marker = await widget.repository.get(_owner!, widget.markerId!);
      if (!_current) return;
      if (marker == null || marker.ownerId != _owner) {
        throw StateError('No encontramos este marcador en tu cuenta.');
      }
      setState(() {
        _marker = marker;
        _name.text = marker.name;
        _description.text = marker.description;
        _menuUrl.text = marker.menuUrl ?? '';
        _width.text = marker.widthCm.toString();
        _latitude = marker.latitude;
        _longitude = marker.longitude;
        _accuracy = marker.locationAccuracy;
        _locationExact = marker.locationExact;
        _active = marker.active;
        _existingImage = widget.repository.loadImage(_owner, marker);
      });
    } catch (error) {
      if (_current) {
        setState(() {
          _unavailable = true;
          _error = _message(error);
        });
      }
    } finally {
      if (_current) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_current || _busy) return;
    setState(() {
      _picking = true;
      _error = null;
      _saved = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (picked == null || !_current) return;
      if (await picked.length() > 10 * 1024 * 1024) {
        throw StateError('Elige una imagen de hasta 10 MB.');
      }
      final bytes = await compute(
        prepareMarkerImage,
        await picked.readAsBytes(),
      );
      if (!_current) return;
      setState(() {
        _draftImage = bytes;
        _active = false;
      });
    } catch (error) {
      if (_current) setState(() => _error = _message(error));
    } finally {
      if (_current) setState(() => _picking = false);
    }
  }

  Future<void> _locate() async {
    if (!_current || _busy) return;
    setState(() {
      _locating = true;
      _error = null;
      _saved = null;
    });
    try {
      final fix = await widget.locationService.current(
        requestPermission: true,
        isCurrent: () => _current,
      );
      if (!_current) return;
      if (!fix.latitude.isFinite ||
          !fix.longitude.isFinite ||
          fix.latitude < -90 ||
          fix.latitude > 90 ||
          fix.longitude < -180 ||
          fix.longitude > 180 ||
          !fix.accuracy.isFinite ||
          fix.accuracy < 0) {
        throw StateError('No pudimos obtener una ubicación válida.');
      }
      setState(() {
        _latitude = fix.latitude;
        _longitude = fix.longitude;
        _accuracy = fix.accuracy;
        _locationExact = fix.accuracy <= 20;
        _active = false;
      });
    } catch (error) {
      if (_current) setState(() => _error = _message(error));
    } finally {
      if (_current) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_current || _busy || !_form.currentState!.validate()) return;
    if (_draftImage == null && (_marker?.referencePath?.isEmpty ?? true)) {
      setState(() => _error = 'Elige la imagen que reconocerá la cámara.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saved = null;
    });
    try {
      final saved = await widget.repository.save(_owner!, {
        if (_marker != null) 'id': _marker!.id,
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'menu_url': _menuUrl.text.trim().isEmpty ? null : _menuUrl.text.trim(),
        'width_cm': _widthCm,
        'latitude': _latitude,
        'longitude': _longitude,
        'location_accuracy': _accuracy,
        'location_exact': _exactLocation,
        'active': _active && _tested && _exactLocation,
      }, imageBytes: _draftImage);
      if (!_current) return;
      if (saved.ownerId != _owner) {
        throw StateError('La respuesta no corresponde a tu cuenta.');
      }
      widget.controller.markersChanged();
      setState(() {
        if (_draftImage != null) _existingImage = Future.value(_draftImage!);
        _draftImage = null;
        _marker = saved;
        _active = saved.active;
        _saved = saved.isLocal
            ? 'Guardado en este dispositivo'
            : 'Borrador privado guardado en tu cuenta';
      });
    } catch (error) {
      if (_current) setState(() => _error = _message(error));
    } finally {
      if (_current) setState(() => _saving = false);
    }
  }

  String _message(Object error) => error is StateError
      ? error.message.toString()
      : error is DeviceLocationFailure
      ? error.message
      : AppFailureMapper.from(error).message;

  @override
  void dispose() {
    widget.controller.removeListener(_accountChanged);
    for (final input in [_name, _description, _menuUrl, _width]) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.markerId == null ? 'Añadir marcador' : 'Editar marcador',
      ),
    ),
    body: !_current
        ? Center(
            child: Text(
              _owner == null
                  ? 'Inicia sesión para guardar un marcador.'
                  : 'La cuenta cambió. Vuelve a abrir tus marcadores.',
            ),
          )
        : _loading
        ? const Center(child: CircularProgressIndicator())
        : _unavailable
        ? Center(child: Text(_error ?? 'No pudimos abrir el marcador.'))
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Elige una imagen física. Al reconocerla, la cámara mostrará la información de tu marcador.',
                    ),
                    const SizedBox(height: 16),
                    if (_draftImage != null)
                      Image.memory(
                        _draftImage!,
                        height: 180,
                        fit: BoxFit.contain,
                        cacheWidth: 720,
                      )
                    else if (_existingImage != null)
                      SizedBox(
                        height: 180,
                        child: FutureBuilder<Uint8List>(
                          future: _existingImage,
                          builder: (context, snapshot) => snapshot.hasData
                              ? Image.memory(
                                  snapshot.data!,
                                  height: 180,
                                  fit: BoxFit.contain,
                                  cacheWidth: 720,
                                  errorBuilder: (_, _, _) => const Text(
                                    'No pudimos mostrar la imagen guardada.',
                                  ),
                                )
                              : Text(
                                  snapshot.hasError
                                      ? 'No pudimos abrir la imagen guardada. Puedes elegir otra.'
                                      : 'Abriendo imagen…',
                                ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _picking
                            ? 'Preparando imagen…'
                            : _draftImage != null || _marker != null
                            ? 'Cambiar imagen'
                            : 'Elegir imagen',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('marker-name'),
                      controller: _name,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      maxLength: 100,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Escribe un nombre.'
                          : null,
                    ),
                    TextFormField(
                      key: const Key('marker-description'),
                      controller: _description,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Información del marcador',
                      ),
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 2000,
                    ),
                    TextFormField(
                      key: const Key('marker-menu-url'),
                      controller: _menuUrl,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Enlace al menú o información (opcional)',
                        hintText: 'https://…',
                      ),
                      maxLength: 2000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final uri = Uri.tryParse(value.trim());
                        return uri != null &&
                                (uri.scheme == 'https' ||
                                    uri.scheme == 'http') &&
                                uri.host.isNotEmpty &&
                                uri.userInfo.isEmpty
                            ? null
                            : 'Usa un enlace http:// o https:// válido.';
                      },
                    ),
                    TextFormField(
                      key: const Key('marker-width'),
                      controller: _width,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Ancho real de la imagen (cm)',
                        helperText: 'Mide la imagen física de borde a borde.',
                      ),
                      onChanged: (_) => setState(() => _active = false),
                      validator: (_) {
                        final width = _widthCm;
                        return width != null &&
                                width.isFinite &&
                                width >= 1 &&
                                width <= 1000
                            ? null
                            : 'Escribe un ancho de entre 1 y 1000 cm.';
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ubicación opcional',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Guárdala estando junto a la imagen para poder avisar a menos de 20 m.',
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _locate,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _locating
                            ? 'Obteniendo ubicación…'
                            : 'Usar mi ubicación',
                      ),
                    ),
                    if (_latitude != null && _longitude != null)
                      Text(
                        _exactLocation
                            ? 'Ubicación precisa guardada (±${_accuracy!.round()} m).'
                            : 'Ubicación aproximada. Se necesita una precisión de 20 m o menos para avisar cerca.',
                      ),
                    if (_marker?.isLocal != false)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notificar cerca'),
                        subtitle: Text(
                          _tested && _exactLocation
                              ? 'Avisar cuando el marcador esté a menos de 20 m.'
                              : 'Primero prueba el reconocimiento en RA y guarda una ubicación precisa.',
                        ),
                        value: _active && _tested && _exactLocation,
                        onChanged: !_busy && _tested && _exactLocation
                            ? (value) => setState(() => _active = value)
                            : null,
                      ),
                    if (_marker?.isLocal == false)
                      const Text(
                        'El marcador se guarda privado en tu cuenta. Su publicación y los avisos públicos requieren revisión.',
                      ),
                    if (_draftImage != null ||
                        (_marker != null && _widthCm != _marker!.widthCm))
                      const Text(
                        'Al cambiar la imagen o su ancho tendrás que probar de nuevo el reconocimiento.',
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_error!),
                      ),
                    if (_saved != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_saved!),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_saving ? 'Guardando…' : 'Guardar marcador'),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
