import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import '../data/tour_local_store.dart';
import '../models/tour_models.dart';
import 'tour_panorama.dart';
import 'tour_widgets.dart';

Uint8List _referenceJPEG(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) throw StateError('No pudimos leer la imagen.');
  final image = img.bakeOrientation(decoded);
  final resized = image.width > 1600 || image.height > 1600
      ? img.copyResize(
          image,
          width: image.width >= image.height ? 1600 : null,
          height: image.height > image.width ? 1600 : null,
        )
      : image;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
}

Uint8List _marker(String id) {
  final image = img.Image(width: 1024, height: 1024);
  img.fill(image, color: img.ColorRgb8(250, 249, 246));
  final random = math.Random(id.hashCode);
  for (var i = 0; i < 160; i++) {
    final x = 30 + random.nextInt(960), y = 30 + random.nextInt(960);
    final color = i % 3 == 0
        ? img.ColorRgb8(13, 67, 151)
        : i % 3 == 1
        ? img.ColorRgb8(11, 37, 94)
        : img.ColorRgb8(8, 127, 128);
    if (i.isEven) {
      img.drawCircle(
        image,
        x: x,
        y: y,
        radius: 5 + random.nextInt(36),
        color: color,
      );
    } else {
      img.drawLine(
        image,
        x1: x,
        y1: y,
        x2: (x + random.nextInt(160) - 80).clamp(10, 1014),
        y2: (y + random.nextInt(160) - 80).clamp(10, 1014),
        color: color,
        thickness: 4,
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 98));
}

class TourEditorScreen extends StatefulWidget {
  const TourEditorScreen({
    required this.controller,
    this.tourId,
    this.localStore,
    super.key,
  });
  final AppSessionController controller;
  final String? tourId;
  final TourLocalStore? localStore;
  @override
  State<TourEditorScreen> createState() => _TourEditorScreenState();
}

class _TourEditorScreenState extends State<TourEditorScreen> {
  final _title = TextEditingController(),
      _name = TextEditingController(),
      _location = TextEditingController(),
      _lat = TextEditingController(),
      _lng = TextEditingController(),
      _context = TextEditingController();
  late final _store = widget.localStore ?? TourLocalStore();
  TourDocument _doc = TourDocument.empty();
  Map<String, dynamic> _space = {};
  TourRecord? _record;
  String? _error, _saved;
  String? _creationId;
  bool _loading = true, _busy = false, _loaded = false, _offline = false;
  int _step = 0;
  Future<void> _localTail = Future.value();
  bool _dirty = false, _allowPop = false, _pendingSubmission = false;
  String? _localFailure;
  late final String _account = widget.controller.profile?.id ?? '';
  bool get _current => mounted && widget.controller.profile?.id == _account;
  String get _key => 'draft-${_record?.id ?? widget.tourId ?? 'new'}';
  @override
  void initState() {
    super.initState();
    _load();
    for (final c in [_title, _name, _location, _lat, _lng, _context]) {
      c.addListener(_changed);
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loaded = false;
        _error = null;
      });
    }
    try {
      final profile = widget.controller.profile;
      if (profile == null || profile.userType == UserType.general) {
        throw StateError(
          'Los recorridos se crean desde un perfil profesional.',
        );
      }
      // Read accepted local fields first: a failed RPC must never replace them
      // with an uninitialized form, including when the user immediately leaves.
      final local = await _store.read(
        _account,
        'draft-${widget.tourId ?? 'new'}',
      );
      if (!_current) return;
      _pendingSubmission = local?['pending_submission'] == true;
      _creationId = local?['pending'] == true || _pendingSubmission
          ? (local?['creation_id'] as String?)
          : null;
      final requestedId = widget.tourId ?? _creationId;
      _offline = false;
      if (requestedId != null) {
        try {
          _record = await widget.controller.tourRepository!.get(
            requestedId,
            edit: true,
          );
          if (!_current) return;
          if (_record == null) {
            throw StateError('Este borrador no está disponible.');
          }
        } catch (e) {
          if (local == null ||
              e is PostgrestException ||
              (e is StateError &&
                  e.message == 'Este borrador no está disponible.')) {
            rethrow;
          }
          final cached = local['record'];
          _record = cached is Map
              ? TourRecord.fromJson(cached)
              : TourRecord({
                  'id': requestedId,
                  'owner_id': _account,
                  'state': 'draft',
                  'title': local['title'],
                  'space': local['space'],
                  'document': local['document'],
                });
          if (_record!.ownerId != _account) {
            throw StateError('Este borrador pertenece a otra cuenta.');
          }
          _offline = true;
        }
      }
      if (!_current) return;
      _doc = _record?.document.copy() ?? TourDocument.empty();
      _space = Map<String, dynamic>.from(
        _record?.space ??
            {
              'name': profile.fullName,
              'location_label': profile.location ?? '',
              'latitude': profile.locationLatitude,
              'longitude': profile.locationLongitude,
              'context': '',
              'evidence_paths': <dynamic>[],
            },
      );
      _title.text = _record?.title ?? '';
      _dirty = local?['pending'] == true;
      if (local != null && (_dirty || _offline)) {
        _doc = TourDocument(jsonMap(local['document']));
        _space = jsonMap(local['space']);
        _title.text = local['title'] as String;
        _saved = _offline
            ? 'Borrador recuperado del dispositivo. Conecta para sincronizar.'
            : 'Hay cambios locales pendientes de sincronizar.';
      }
      _name.text = _space['name'] as String? ?? '';
      _location.text = _space['location_label'] as String? ?? '';
      _lat.text = '${_space['latitude'] ?? ''}';
      _lng.text = '${_space['longitude'] ?? ''}';
      _context.text = _space['context'] as String? ?? '';
      _loaded = true;
    } catch (e) {
      if (_current) _error = tourError(e);
    } finally {
      if (_current) setState(() => _loading = false);
    }
  }

  void _changed() {
    if (_loading || !_loaded || !_current) return;
    _saved = null;
    _local();
  }

  Map<String, dynamic> _spaceValues() => {
    ..._space,
    'name': _name.text.trim(),
    'location_label': _location.text.trim(),
    'latitude': double.tryParse(_lat.text),
    'longitude': double.tryParse(_lng.text),
    'context': _context.text.trim(),
  };
  Future<void> _local({bool changed = true}) {
    if (!_loaded) return Future.value();
    if (changed) _dirty = true;
    final key = _key;
    final payload =
        jsonDecode(
              jsonEncode({
                'title': _title.text,
                'space': _spaceValues(),
                'document': _doc.data,
                'pending': _dirty,
                'pending_submission': _pendingSubmission,
                'creation_id': _creationId,
                'record': _record?.data,
              }),
            )
            as Map<String, dynamic>;
    final operation = _localTail.then((_) async {
      await _store.write(_account, key, payload);
      if (widget.tourId == null &&
          key != 'draft-new' &&
          (payload['pending'] == true ||
              payload['pending_submission'] == true)) {
        await _store.write(_account, 'draft-new', payload);
      }
      _localFailure = null;
    });
    _localTail = operation.catchError((Object error) {
      _localFailure =
          'No pudimos guardar los últimos cambios en este dispositivo.';
    });
    return operation
        .then((_) {
          if (_current) setState(() => _saved = 'Guardado en este dispositivo');
        })
        .catchError((Object e) {
          if (_current) setState(() => _error = _localFailure);
        });
  }

  Future<void> _back() async {
    if (_busy || _loading || _allowPop) return;
    await _local(changed: false);
    if (!_current) return;
    if (_localFailure != null && mounted) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('No se guardaron los cambios'),
          content: const Text(
            'Puedes volver a intentarlo o salir y descartar los últimos cambios.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Volver a intentar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Descartar y salir'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!_current) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) leaveTour(context, '/tours');
    });
  }

  Future<bool> _save() async {
    if (_busy || !_loaded || !_current) return false;
    if (_title.text.trim().isEmpty || _name.text.trim().isEmpty) {
      setState(
        () => _error = 'Escribe el título del recorrido y el nombre del local.',
      );
      return false;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _creationId ??= _record?.id ?? widget.tourId ?? tourId();
      await _local(changed: false);
      if (_localFailure != null) throw StateError(_localFailure!);
      if (!_current) return false;
      if (_offline && _record != null) {
        final authorized = await widget.controller.tourRepository!.get(
          _record!.id,
          edit: true,
        );
        if (!_current) return false;
        if (authorized == null || authorized.ownerId != _account) {
          throw StateError(
            'Este borrador no está disponible para sincronizar.',
          );
        }
        _record = authorized;
        _offline = false;
      }
      final record = await widget.controller.tourRepository!.save(
        _record?.id ?? widget.tourId ?? _creationId,
        _title.text.trim(),
        _spaceValues(),
        _doc,
      );
      if (!_current) return false;
      setState(() {
        _record = record;
        _doc = record.document.copy();
        _space = record.space;
        _saved = 'Borrador sincronizado';
        _dirty = false;
        _pendingSubmission = false;
      });
      await _local(changed: false);
      if (widget.tourId == null) {
        await _store.write(_account, 'draft-new', {'pending': false});
      }
      return true;
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
      return false;
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _capture(TourScene scene, {bool import = false}) async {
    if (!await _save() || !mounted) return;
    await context.push(
      '/tours/${_record!.id}/capture?scene=${scene.id}${import ? '&import=true' : ''}',
    );
    if (!mounted || !_current) return;
    final updated = await widget.controller.tourRepository!.get(
      _record!.id,
      edit: true,
    );
    if (_current && updated != null) {
      setState(() {
        _record = updated;
        _doc = updated.document.copy();
      });
    }
  }

  Future<void> _addZone() async {
    final name = await tourTextDialog(
      context,
      'Nombre de zona',
      help: 'Por ejemplo: Entrada, Barra, Mural o Terraza.',
    );
    if (!mounted || !_current || name == null) return;
    setState(() => _doc.addZone(name));
    await _local();
  }

  Future<void> _addScene(TourZone zone) async {
    final name = await tourTextDialog(
      context,
      'Posición de captura',
      help:
          'Una zona puede tener varias posiciones. Por ejemplo: Frente a la barra.',
    );
    if (!mounted || !_current || name == null) return;
    setState(() => zone.addScene(name));
    await _local();
  }

  Future<void> _addPoint(TourScene scene) async {
    final name = await tourTextDialog(context, 'Nombre del punto');
    if (!mounted || !_current || name == null) return;
    final explanation = await tourTextDialog(context, 'Explicación del punto');
    if (!mounted || !_current || explanation == null) return;
    setState(() => scene.addPoint(name, explanation));
    await _local();
  }

  Future<void> _mark(TourScene scene, TourPoint point) async {
    final position = await pickPanoramaPosition(
      context,
      widget.controller.tourRepository!,
      scene,
    );
    if (!mounted || !_current || position == null) return;
    setState(
      () => point.data.addAll({
        'yaw': position.$1,
        'pitch': position.$2,
        'needs_review': false,
      }),
    );
    await _local();
  }

  Future<void> _link(TourPoint point) async {
    final query = await tourTextDialog(
      context,
      'Buscar contenido',
      help:
          'Obras, servicios, productos de emprendimientos, publicaciones o misiones.',
    );
    if (!mounted || !_current || query == null) return;
    try {
      final links = await widget.controller.tourRepository!.searchLinks(query);
      if (!mounted || !_current) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Vincular contenido'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (links.isEmpty)
                  const Text('No encontramos contenido disponible.'),
                for (final link in links)
                  ListTile(
                    title: Text(link['title'] as String? ?? ''),
                    subtitle: Text(
                      '${link['kind']} · ${link['owner_name'] ?? link['owner_id']}',
                    ),
                    onTap: () => Navigator.pop(c, link),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Volver'),
            ),
          ],
        ),
      );
      if (!mounted || !_current || selected == null) return;
      setState(() => point.data['link'] = selected);
      if (!await _save()) return;
      if (selected['owner_id'] != _account) {
        await widget.controller.tourRepository!.requestLink(
          _record!.id,
          point.id,
        );
        if (mounted && _current) {
          setState(() => _saved = 'Solicitud de vinculación enviada al autor');
        }
      }
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    }
  }

  Future<void> _prepareAR(TourPoint point, {bool marker = false}) async {
    if (!await _save()) return;
    try {
      final id = tourId();
      Uint8List bytes;
      if (marker) {
        bytes = await compute(_marker, id);
      } else {
        final photo = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (photo == null) return;
        bytes = await compute(_referenceJPEG, await photo.readAsBytes());
      }
      if (!mounted || !_current) return;
      final width = await tourTextDialog(
        context,
        'Ancho físico en centímetros',
        initial: marker ? '20' : '',
        help:
            'Mide la imagen instalada. Para el distintivo, imprime a este ancho y compruébalo con una regla.',
      );
      final cm = double.tryParse(width ?? '');
      if (cm == null || cm <= 0 || cm > 1000) return;
      final path = await widget.controller.tourRepository!.uploadReference(
        _account,
        id,
        bytes,
      );
      if (!mounted || !_current) return;
      setState(
        () => _doc.point(point.id)!.data['ar'] = {
          'reference_path': path,
          'width_cm': cm,
          'reference_version': id,
          'tested_version': null,
        },
      );
      if (marker) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'image/jpeg',
                name: 'activador-${point.id}.jpg',
              ),
            ],
            text:
                'Imprimir con ancho exacto de $cm cm, sin recortar. Medir antes de probar AR.',
          ),
        );
      }
      if (!jsonList(_doc.data['ar_order']).contains(point.id)) {
        jsonList(_doc.data['ar_order']).add(point.id);
      }
      await _save();
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    }
  }

  Future<void> _connect(TourScene scene) async {
    final targets = _doc.scenes.where((s) => s.id != scene.id).toList();
    if (targets.isEmpty) {
      setState(() => _error = 'Agrega otra posición para conectarla.');
      return;
    }
    final target = await showDialog<TourScene>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Conectar con'),
        children: [
          for (final t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, t),
              child: Text(t.name),
            ),
        ],
      ),
    );
    if (!mounted || !_current || target == null) return;
    final instruction = await tourTextDialog(
      context,
      'Cómo llegar',
      help: 'Por ejemplo: Camina hacia el mural junto a la barra.',
    );
    if (!mounted || !_current || instruction == null) return;
    final position = await pickPanoramaPosition(
      context,
      widget.controller.tourRepository!,
      scene,
    );
    if (!mounted || !_current || position == null) return;
    setState(
      () => jsonList(scene.data['connections']).add({
        'id': tourId(),
        'target_scene_id': target.id,
        'label': target.name,
        'instruction': instruction,
        'yaw': position.$1,
        'pitch': position.$2,
        'needs_review': false,
      }),
    );
    await _local();
  }

  void _move(List list, int index, int delta) {
    final destination = index + delta;
    if (destination < 0 || destination >= list.length) return;
    setState(() {
      final value = list.removeAt(index);
      list.insert(destination, value);
    });
    _local();
  }

  Future<DateTime?> _pickDateTime(String title) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      helpText: title,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || day == null) return null;
    final time = await showTimePicker(
      context: context,
      helpText: '$title · hora de este dispositivo',
      initialTime: TimeOfDay.now(),
    );
    return time == null
        ? null
        : DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _evidence() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !_current) return;
      final bytes = await compute(_referenceJPEG, await file.readAsBytes());
      final path = await widget.controller.tourRepository!.uploadReference(
        _account,
        tourId(),
        bytes,
      );
      if (!mounted || !_current) return;
      setState(() {
        (_space['evidence_paths'] as List? ??
                (_space['evidence_paths'] = <dynamic>[]))
            .add(path);
      });
      await _local();
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    }
  }

  Future<void> _submit() async {
    if (_busy || !_current) return;
    if ((_record == null || _dirty) && !await _save()) return;
    if (!_current) return;
    setState(() => _busy = true);
    try {
      // A lost response is reconciled before any attempt to create a new revision.
      if (!_dirty) {
        final current = await widget.controller.tourRepository!.get(
          _record!.id,
          edit: true,
        );
        if (!_current) return;
        if (current != null &&
            (current.state == 'submitted' || current.state == 'published')) {
          setState(() {
            _record = current;
            _pendingSubmission = false;
            _saved = tourStateLabel(current.state);
          });
          await _local(changed: false);
          return;
        }
      }
      _pendingSubmission = true;
      await _local(changed: false);
      if (_localFailure != null) throw StateError(_localFailure!);
      if (!_current) return;
      final record = await widget.controller.tourRepository!.submit(
        _record!.id,
      );
      if (_current) {
        setState(() {
          _record = record;
          _pendingSubmission = false;
          _saved = tourStateLabel(record.state);
        });
        await _local(changed: false);
      }
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _name, _location, _lat, _lng, _context]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop:
        _allowPop ||
        _loading ||
        !_current ||
        widget.controller.profile?.userType == UserType.general,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: TourBackButton(fallback: '/tours', onPressed: _back),
        title: const Text('Crear recorrido 360°'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_loaded
          ? Center(
              child: TourNotice(
                _error ?? 'No pudimos recuperar el borrador.',
                onRetry: _load,
              ),
            )
          : widget.controller.profile?.userType == UserType.general
          ? Center(
              child: TourNotice(_error ?? 'Necesitas un perfil profesional.'),
            )
          : AbsorbPointer(
              absorbing: _busy,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < 6; i++)
                        ChoiceChip(
                          label: Text(
                            [
                              'Local',
                              'Zonas',
                              'Puntos y AR',
                              'Conexiones',
                              'Vista previa',
                              'Publicación',
                            ][i],
                          ),
                          selected: _step == i,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _step = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) TourNotice(_error!),
                  if (_saved != null)
                    Text(
                      _saved!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 12),
                  if (_step == 0) ...[
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Título del recorrido',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del local',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación pública',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showCommunityLocationPicker(
                          context,
                          repository: widget.controller.locationRepository,
                        );
                        if (!mounted || !_current || selected == null) return;
                        setState(() {
                          _location.text = selected.label;
                          _lat.text = '${selected.coordinates.latitude}';
                          _lng.text = '${selected.coordinates.longitude}';
                          _space['location_precision'] =
                              selected.coordinates.precision.name;
                        });
                        await _local();
                      },
                      icon: const Icon(Icons.place_outlined),
                      label: const Text('Confirmar ubicación en el mapa'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _context,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Tu relación con el local',
                        helperText:
                            'El administrador revisará la responsabilidad del espacio. No incluyas documentos sensibles.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _evidence,
                      child: const Text('Añadir evidencia privada del local'),
                    ),
                    Text(
                      '${jsonList(_space['evidence_paths']).length} imágenes privadas para revisión',
                    ),
                    Text(
                      'Horarios: ${widget.controller.profile?.businessHours.values.whereType<String>().join(' · ') ?? ''}',
                    ),
                    Text(
                      'Contacto: ${widget.controller.profile?.contactUrl ?? ''}',
                    ),
                    TextButton(
                      onPressed: () => context.push('/profile/edit'),
                      child: const Text('Editar datos del perfil'),
                    ),
                  ],
                  if (_step == 1) ...[
                    const Text(
                      'Una zona agrupa posiciones 360°. Captura cada posición sin caminar durante las tomas.',
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _addZone,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar zona'),
                    ),
                    for (final z in _doc.zones)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                z.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final name = await tourTextDialog(
                                    context,
                                    'Editar zona',
                                    initial: z.name,
                                  );
                                  if (_current && name != null) {
                                    setState(() => z.data['name'] = name);
                                    _local();
                                  }
                                },
                                child: const Text('Editar nombre'),
                              ),
                              for (final s in z.scenes)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      s.panoramaPath == null
                                          ? 'Sin panorama listo'
                                          : 'Panorama listo',
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (!kIsWeb)
                                          TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _capture(s),
                                            child: const Text(
                                              'Capturar / retomar',
                                            ),
                                          ),
                                        TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _capture(s, import: true),
                                          child: const Text('Importar 360°'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              OutlinedButton(
                                onPressed: _busy ? null : () => _addScene(z),
                                child: const Text('Agregar posición'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (_step == 2) ...[
                    for (final s in _doc.scenes)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              for (final p in s.points) ...[
                                const Divider(),
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(p.description),
                                if (p.data['needs_review'] == true)
                                  const Text(
                                    'Revisa este punto después del cambio de panorama.',
                                  ),
                                if (p.link != null)
                                  Text(
                                    '${p.link!['title']} · ${p.link!['status'] ?? 'pendiente'}',
                                  ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: s.panoramaPath == null
                                          ? null
                                          : () => _mark(s, p),
                                      child: const Text('Marcar en 360°'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final text = await tourTextDialog(
                                          context,
                                          'Explicación',
                                          initial: p.description,
                                        );
                                        if (_current && text != null) {
                                          setState(
                                            () => p.data['description'] = text,
                                          );
                                          _local();
                                        }
                                      },
                                      child: const Text('Editar texto'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(
                                          () => p.data.addAll({
                                            'yaw': null,
                                            'pitch': null,
                                            'needs_review': false,
                                          }),
                                        );
                                        _local();
                                      },
                                      child: const Text('Solo en lista'),
                                    ),
                                    TextButton(
                                      onPressed: () => _link(p),
                                      child: const Text('Vincular contenido'),
                                    ),
                                    TextButton(
                                      onPressed: () => _prepareAR(p),
                                      child: const Text('Imagen para AR'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _prepareAR(p, marker: true),
                                      child: const Text(
                                        'Distintivo imprimible',
                                      ),
                                    ),
                                    if (p.ar != null)
                                      TextButton(
                                        onPressed: () async {
                                          if (await _save() &&
                                              context.mounted) {
                                            await context.push(
                                              '/tours/${_record!.id}/ar?preview=true&point=${p.id}',
                                            );
                                            if (mounted && _current) {
                                              final r = await widget
                                                  .controller
                                                  .tourRepository!
                                                  .get(_record!.id, edit: true);
                                              if (_current && r != null) {
                                                setState(
                                                  () =>
                                                      _doc = r.document.copy(),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Text(
                                          p.ar!['tested_version'] ==
                                                  p.ar!['reference_version']
                                              ? 'Volver a probar AR'
                                              : 'Probar AR en el local',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              OutlinedButton(
                                onPressed: () => _addPoint(s),
                                child: const Text('Agregar punto'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (_step == 3) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _doc.scene(_doc.startSceneId ?? '')?.id,
                      decoration: const InputDecoration(
                        labelText: 'Posición inicial',
                      ),
                      isExpanded: true,
                      items: [
                        for (final s in _doc.scenes)
                          DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ],
                      onChanged: (id) {
                        setState(() => _doc.data['start_scene_id'] = id);
                        _local();
                      },
                    ),
                    for (var i = 0; i < _doc.zones.length; i++)
                      ListTile(
                        title: Text(_doc.zones[i].name),
                        subtitle: const Text('Orden de zonas'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Subir zona',
                              onPressed: i == 0
                                  ? null
                                  : () => _move(
                                      _doc.data['zones'] as List,
                                      i,
                                      -1,
                                    ),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Bajar zona',
                              onPressed: i == _doc.zones.length - 1
                                  ? null
                                  : () =>
                                        _move(_doc.data['zones'] as List, i, 1),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                      ),
                    for (final s in _doc.scenes)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              for (final c in s.connections)
                                ListTile(
                                  title: Text(c['label'] as String? ?? ''),
                                  subtitle: Text(
                                    c['needs_review'] == true
                                        ? 'Revisa esta conexión'
                                        : c['instruction'] as String? ?? '',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Eliminar conexión',
                                    onPressed: () {
                                      setState(
                                        () => jsonList(s.data['connections'])
                                            .removeWhere(
                                              (v) => v['id'] == c['id'],
                                            ),
                                      );
                                      _local();
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                              TextButton(
                                onPressed: s.panoramaPath == null
                                    ? null
                                    : () => _connect(s),
                                child: const Text('Conectar otra posición'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Text('Paradas con cámara'),
                    for (final id in jsonList(_doc.data['ar_order']))
                      if (_doc.point(id as String) != null)
                        ListTile(
                          title: Text(_doc.point(id)!.name),
                          subtitle: const Text(
                            'Orden del recorrido presencial',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Subir parada',
                                onPressed: () => _move(
                                  _doc.data['ar_order'] as List,
                                  jsonList(_doc.data['ar_order']).indexOf(id),
                                  -1,
                                ),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: 'Bajar parada',
                                onPressed: () => _move(
                                  _doc.data['ar_order'] as List,
                                  jsonList(_doc.data['ar_order']).indexOf(id),
                                  1,
                                ),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                            ],
                          ),
                        ),
                  ],
                  if (_step == 4) ...[
                    const Text(
                      'Revisa el panorama, sus conexiones y sus puntos. Las pruebas AR se realizan en el local.',
                    ),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await _save() && context.mounted) {
                                await context.push(
                                  '/tours/${_record!.id}?preview=true',
                                );
                              }
                            },
                      child: const Text('Abrir vista previa privada'),
                    ),
                  ],
                  if (_step == 5) ...[
                    Text(
                      'Espacio: ${_space['verified'] == true ? 'autorizado' : 'pendiente de revisión'}',
                    ),
                    Text(
                      'Versión: ${tourStateLabel(_record?.state ?? 'draft')}',
                    ),
                    if (_record?.publicRevisionId != null)
                      const Text(
                        'La versión pública anterior seguirá disponible hasta aprobar estos cambios.',
                      ),
                    for (final issue in _doc.publicationProblems)
                      TourNotice(issue),
                    if (_doc.points.any(
                      (p) => p.link != null && p.link!['status'] != 'approved',
                    ))
                      const TourNotice(
                        'Los vínculos pendientes no aparecerán en la versión pública.',
                      ),
                    OutlinedButton(
                      onPressed: () async {
                        final start = await _pickDateTime('Inicio de vigencia');
                        if (!mounted || !_current || start == null) return;
                        final end = await _pickDateTime('Fin de vigencia');
                        if (!mounted || !_current || end == null) return;
                        if (!end.isAfter(start)) {
                          setState(
                            () =>
                                _error = 'El fin debe ser posterior al inicio.',
                          );
                          return;
                        }
                        setState(
                          () => _doc.data.addAll({
                            'starts_at': start.toUtc().toIso8601String(),
                            'ends_at': end.toUtc().toIso8601String(),
                          }),
                        );
                        _local();
                      },
                      child: const Text('Definir vigencia temporal'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(
                          () => _doc.data.addAll({
                            'starts_at': null,
                            'ends_at': null,
                          }),
                        );
                        _local();
                      },
                      child: const Text('Vigencia permanente'),
                    ),
                    FilledButton(
                      onPressed: _busy || _doc.publicationProblems.isNotEmpty
                          ? null
                          : _submit,
                      child: Text(
                        _space['verified'] == true
                            ? 'Publicar versión'
                            : 'Enviar a revisión',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? 'Guardando…' : 'Guardar borrador'),
                  ),
                  if (_step < 5)
                    TextButton(
                      onPressed: () => setState(() => _step++),
                      child: const Text('Continuar'),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    ),
  );
}
