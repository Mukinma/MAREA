import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
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

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
Uint8List _referenceJPEG(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) {
    throw StateError('No pudimos leer la imagen.');
  }
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
  bool _initialLoadStarted = false;
  String? _localFailure;
  late final String _account = widget.controller.profile?.id ?? '';
  bool get _current => mounted && widget.controller.profile?.id == _account;
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  String _editorError(Object error) =>
      error is StateError && error.message == 'No pudimos leer la imagen.'
      ? core_l10n.AppLocalizations.tr(_l10n.errorLeerImagen)
      : tourError(error, l10n: _l10n);
  String get _key => 'draft-${_record?.id ?? widget.tourId ?? 'new'}';
  String _stateLabel(String state) => switch (state) {
    'published' => core_l10n.AppLocalizations.tr(_l10n.estadoPublicado),
    'paused' => core_l10n.AppLocalizations.tr(_l10n.estadoPausado),
    'in_review' || 'submitted' => core_l10n.AppLocalizations.tr(_l10n.estadoEnRevision),
    'changes_requested' ||
    'needs_changes' ||
    'rejected' => core_l10n.AppLocalizations.tr(_l10n.estadoRequiereCambios),
    'expired' => core_l10n.AppLocalizations.tr(_l10n.estadoFinalizado),
    _ => core_l10n.AppLocalizations.tr(_l10n.estadoBorrador),
  };
  String _linkStatusLabel(dynamic status) => switch (status) {
    'approved' => core_l10n.AppLocalizations.tr(_l10n.estadoAprobado),
    'pending' => core_l10n.AppLocalizations.tr(_l10n.pendiente),
    _ => status?.toString() ?? core_l10n.AppLocalizations.tr(_l10n.pendiente),
  };
  String _publicationProblemLabel(String issue) => switch (issue) {
    'Agrega una posición 360°' => core_l10n.AppLocalizations.tr(_l10n.problemaAgregarPosicion360),
    'Elige una posición inicial' => core_l10n.AppLocalizations.tr(_l10n.problemaElegirPosicionInicial),
    'Espera a que todos los panoramas estén listos' =>
      core_l10n.AppLocalizations.tr(_l10n.problemaPanoramasPendientes),
    'Revisa los puntos de panoramas reemplazados' =>
      core_l10n.AppLocalizations.tr(_l10n.problemaRevisarPuntosPanoramas),
    'Revisa las conexiones de panoramas reemplazados' =>
      core_l10n.AppLocalizations.tr(_l10n.problemaRevisarConexionesPanoramas),
    _ => issue,
  };
  @override
  void initState() {
    super.initState();
    for (final c in [_title, _name, _location, _lat, _lng, _context]) {
      c.addListener(_changed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      _load();
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
        throw StateError(core_l10n.AppLocalizations.tr(_l10n.perfilProfesionalRecorridos));
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
            throw StateError(core_l10n.AppLocalizations.tr(_l10n.borradorNoDisponible));
          }
        } catch (e) {
          if (local == null ||
              e is PostgrestException ||
              (e is StateError && e.message == core_l10n.AppLocalizations.tr(_l10n.borradorNoDisponible))) {
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
            throw StateError(core_l10n.AppLocalizations.tr(_l10n.borradorOtraCuenta));
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
            ? core_l10n.AppLocalizations.tr(_l10n.borradorRecuperado)
            : core_l10n.AppLocalizations.tr(_l10n.cambiosLocalesPendientes);
      }
      _name.text = _space['name'] as String? ?? '';
      _location.text = _space['location_label'] as String? ?? '';
      _lat.text = '${_space['latitude'] ?? ''}';
      _lng.text = '${_space['longitude'] ?? ''}';
      _context.text = _space['context'] as String? ?? '';
      _loaded = true;
    } catch (e) {
      if (_current) _error = _editorError(e);
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
      _localFailure = core_l10n.AppLocalizations.tr(_l10n.errorGuardarCambiosLocal);
    });
    return operation
        .then((_) {
          if (_current) setState(() => _saved = core_l10n.AppLocalizations.tr(_l10n.guardadoDispositivo));
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
          title: Text(core_l10n.AppLocalizations.tr(_l10n.noSeGuardaronCambios)),
          content: Text(core_l10n.AppLocalizations.tr(_l10n.volverIntentarCambios)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(core_l10n.AppLocalizations.tr(_l10n.volverIntentar)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(core_l10n.AppLocalizations.tr(_l10n.descartarSalir)),
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
      setState(() => _error = core_l10n.AppLocalizations.tr(_l10n.errorTituloNombreLocal));
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
          throw StateError(core_l10n.AppLocalizations.tr(_l10n.borradorNoDisponibleSincronizar));
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
        _saved = core_l10n.AppLocalizations.tr(_l10n.borradorSincronizado);
        _dirty = false;
        _pendingSubmission = false;
      });
      await _local(changed: false);
      if (widget.tourId == null) {
        await _store.write(_account, 'draft-new', {'pending': false});
      }
      return true;
    } catch (e) {
      if (_current) setState(() => _error = _editorError(e));
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
      core_l10n.AppLocalizations.tr(_l10n.nombreZona),
      help: core_l10n.AppLocalizations.tr(_l10n.ejemploZonas),
    );
    if (!mounted || !_current || name == null) return;
    setState(() => _doc.addZone(name));
    await _local();
  }

  Future<void> _addScene(TourZone zone) async {
    final name = await tourTextDialog(
      context,
      core_l10n.AppLocalizations.tr(_l10n.posicionCaptura),
      help: core_l10n.AppLocalizations.tr(_l10n.ejemploPosiciones),
    );
    if (!mounted || !_current || name == null) return;
    setState(() => zone.addScene(name));
    await _local();
  }

  Future<void> _addPoint(TourScene scene) async {
    final name = await tourTextDialog(context, core_l10n.AppLocalizations.tr(_l10n.nombrePunto));
    if (!mounted || !_current || name == null) return;
    final explanation = await tourTextDialog(context, core_l10n.AppLocalizations.tr(_l10n.explicacionPunto));
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
      core_l10n.AppLocalizations.tr(_l10n.buscarContenido),
      help: core_l10n.AppLocalizations.tr(_l10n.tiposContenidoVinculable),
    );
    if (!mounted || !_current || query == null) return;
    try {
      final links = await widget.controller.tourRepository!.searchLinks(query);
      if (!mounted || !_current) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(core_l10n.AppLocalizations.tr(_l10n.vincularContenidoTitulo)),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (links.isEmpty) Text(core_l10n.AppLocalizations.tr(_l10n.sinContenidoDisponible)),
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
              child: Text(core_l10n.AppLocalizations.tr(_l10n.volver)),
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
          setState(() => _saved = core_l10n.AppLocalizations.tr(_l10n.solicitudVinculacionEnviada));
        }
      }
    } catch (e) {
      if (_current) setState(() => _error = _editorError(e));
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
        core_l10n.AppLocalizations.tr(_l10n.anchoFisicoCentimetros),
        initial: marker ? '20' : '',
        help: core_l10n.AppLocalizations.tr(_l10n.medirImagenInstalada),
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
            text: core_l10n.AppLocalizations.tr(
              _l10n.imprimirAnchoExacto(cm),
            ),
          ),
        );
      }
      if (!jsonList(_doc.data['ar_order']).contains(point.id)) {
        jsonList(_doc.data['ar_order']).add(point.id);
      }
      await _save();
    } catch (e) {
      if (_current) setState(() => _error = _editorError(e));
    }
  }

  Future<void> _connect(TourScene scene) async {
    final targets = _doc.scenes.where((s) => s.id != scene.id).toList();
    if (targets.isEmpty) {
      setState(() => _error = core_l10n.AppLocalizations.tr(_l10n.agregaPosicionConectar));
      return;
    }
    final target = await showDialog<TourScene>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(core_l10n.AppLocalizations.tr(_l10n.conectarCon)),
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
      core_l10n.AppLocalizations.tr(_l10n.comoLlegar),
      help: core_l10n.AppLocalizations.tr(_l10n.ejemploIndicacion),
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
      helpText: core_l10n.AppLocalizations.tr(
        _l10n.horaDispositivo(title),
      ),
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
      if (_current) setState(() => _error = _editorError(e));
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
            _saved = _stateLabel(current.state);
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
          _saved = _stateLabel(record.state);
        });
        await _local(changed: false);
      }
    } catch (e) {
      if (_current) setState(() => _error = _editorError(e));
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return PopScope(
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
          title: Text(core_l10n.AppLocalizations.tr(l10n.crearRecorrido360)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_loaded
            ? Center(
                child: TourNotice(
                  _error ?? core_l10n.AppLocalizations.tr(l10n.borradorNoRecuperado),
                  onRetry: _load,
                ),
              )
            : widget.controller.profile?.userType == UserType.general
            ? Center(
                child: TourNotice(_error ?? core_l10n.AppLocalizations.tr(l10n.necesitasPerfilProfesional)),
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
                                core_l10n.AppLocalizations.tr(l10n.pasoLocal),
                                core_l10n.AppLocalizations.tr(l10n.pasoZonas),
                                core_l10n.AppLocalizations.tr(l10n.pasoPuntosAr),
                                core_l10n.AppLocalizations.tr(l10n.pasoConexiones),
                                core_l10n.AppLocalizations.tr(l10n.pasoVistaPrevia),
                                core_l10n.AppLocalizations.tr(l10n.pasoPublicacion),
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
                        decoration: InputDecoration(
                          labelText: core_l10n.AppLocalizations.tr(l10n.tituloRecorrido),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: core_l10n.AppLocalizations.tr(l10n.nombreLocal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _location,
                        decoration: InputDecoration(
                          labelText: core_l10n.AppLocalizations.tr(l10n.ubicacionPublica),
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
                        label: Text(core_l10n.AppLocalizations.tr(l10n.confirmarUbicacionMapa)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _context,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: core_l10n.AppLocalizations.tr(l10n.relacionLocal),
                          helperText: core_l10n.AppLocalizations.tr(l10n.revisaraResponsabilidad),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _evidence,
                        child: Text(core_l10n.AppLocalizations.tr(l10n.anadirEvidenciaPrivada)),
                      ),
                      Text(
                        core_l10n.AppLocalizations.tr(
                          l10n.imagenesPrivadasRevision(
                            jsonList(_space['evidence_paths']).length,
                          ),
                        ),
                      ),
                      Text(
                        core_l10n.AppLocalizations.tr(
                          l10n.horarios(
                            widget.controller.profile?.businessHours.values
                                    .whereType<String>()
                                    .join(' · ') ??
                                '',
                          ),
                        ),
                      ),
                      Text(
                        core_l10n.AppLocalizations.tr(
                          l10n.contacto(
                            widget.controller.profile?.contactUrl ?? '',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/profile/edit'),
                        child: Text(core_l10n.AppLocalizations.tr(l10n.editarDatosPerfil)),
                      ),
                    ],
                    if (_step == 1) ...[
                      Text(core_l10n.AppLocalizations.tr(l10n.zonaAgrupaPosiciones)),
                      FilledButton.icon(
                        onPressed: _busy ? null : _addZone,
                        icon: const Icon(Icons.add),
                        label: Text(core_l10n.AppLocalizations.tr(l10n.agregarZona)),
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
                                      core_l10n.AppLocalizations.tr(l10n.editarZona),
                                      initial: z.name,
                                    );
                                    if (_current && name != null) {
                                      setState(() => z.data['name'] = name);
                                      _local();
                                    }
                                  },
                                  child: Text(core_l10n.AppLocalizations.tr(l10n.editarNombre)),
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
                                            ? core_l10n.AppLocalizations.tr(l10n.sinPanoramaListo)
                                            : core_l10n.AppLocalizations.tr(l10n.panoramaListo),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          if (!kIsWeb)
                                            TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _capture(s),
                                              child: Text(core_l10n.AppLocalizations.tr(l10n.capturarRetomar)),
                                            ),
                                          TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () =>
                                                      _capture(s, import: true),
                                            child: Text(core_l10n.AppLocalizations.tr(l10n.importar360)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                OutlinedButton(
                                  onPressed: _busy ? null : () => _addScene(z),
                                  child: Text(core_l10n.AppLocalizations.tr(l10n.agregarPosicion)),
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
                                    Text(core_l10n.AppLocalizations.tr(l10n.revisarPuntoCambioPanorama)),
                                  if (p.link != null)
                                    Text(
                                      '${p.link!['title']} · ${_linkStatusLabel(p.link!['status'])}',
                                    ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: s.panoramaPath == null
                                            ? null
                                            : () => _mark(s, p),
                                        child: Text(core_l10n.AppLocalizations.tr(l10n.marcarEn360)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final text = await tourTextDialog(
                                            context,
                                            core_l10n.AppLocalizations.tr(l10n.explicacion),
                                            initial: p.description,
                                          );
                                          if (_current && text != null) {
                                            setState(
                                              () =>
                                                  p.data['description'] = text,
                                            );
                                            _local();
                                          }
                                        },
                                        child: Text(core_l10n.AppLocalizations.tr(l10n.editarTexto)),
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
                                        child: Text(core_l10n.AppLocalizations.tr(l10n.soloEnLista)),
                                      ),
                                      TextButton(
                                        onPressed: () => _link(p),
                                        child: Text(
                                          core_l10n.AppLocalizations.tr(l10n.vincularContenidoTitulo),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _prepareAR(p),
                                        child: Text(core_l10n.AppLocalizations.tr(l10n.imagenParaAr)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _prepareAR(p, marker: true),
                                        child: Text(core_l10n.AppLocalizations.tr(l10n.distintivoImprimible)),
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
                                                    .get(
                                                      _record!.id,
                                                      edit: true,
                                                    );
                                                if (_current && r != null) {
                                                  setState(
                                                    () => _doc = r.document
                                                        .copy(),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          child: Text(
                                            p.ar!['tested_version'] ==
                                                    p.ar!['reference_version']
                                                ? core_l10n.AppLocalizations.tr(l10n.volverProbarAr)
                                                : core_l10n.AppLocalizations.tr(l10n.probarArEnLocal),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                OutlinedButton(
                                  onPressed: () => _addPoint(s),
                                  child: Text(core_l10n.AppLocalizations.tr(l10n.agregarPunto)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    if (_step == 3) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _doc.scene(_doc.startSceneId ?? '')?.id,
                        decoration: InputDecoration(
                          labelText: core_l10n.AppLocalizations.tr(l10n.posicionInicial),
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
                          subtitle: Text(core_l10n.AppLocalizations.tr(l10n.ordenZonas)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: core_l10n.AppLocalizations.tr(l10n.subirZona),
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
                                tooltip: core_l10n.AppLocalizations.tr(l10n.bajarZona),
                                onPressed: i == _doc.zones.length - 1
                                    ? null
                                    : () => _move(
                                        _doc.data['zones'] as List,
                                        i,
                                        1,
                                      ),
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
                                          ? core_l10n.AppLocalizations.tr(l10n.revisarConexion)
                                          : c['instruction'] as String? ?? '',
                                    ),
                                    trailing: IconButton(
                                      tooltip: core_l10n.AppLocalizations.tr(l10n.eliminarConexion),
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
                                  child: Text(core_l10n.AppLocalizations.tr(l10n.conectarOtraPosicion)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(core_l10n.AppLocalizations.tr(l10n.paradasConCamara)),
                      for (final id in jsonList(_doc.data['ar_order']))
                        if (_doc.point(id as String) != null)
                          ListTile(
                            title: Text(_doc.point(id)!.name),
                            subtitle: Text(core_l10n.AppLocalizations.tr(l10n.ordenRecorridoPresencial)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: core_l10n.AppLocalizations.tr(l10n.subirParada),
                                  onPressed: () => _move(
                                    _doc.data['ar_order'] as List,
                                    jsonList(_doc.data['ar_order']).indexOf(id),
                                    -1,
                                  ),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: core_l10n.AppLocalizations.tr(l10n.bajarParada),
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
                      Text(core_l10n.AppLocalizations.tr(l10n.revisarAntesVistaPrevia)),
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
                        child: Text(core_l10n.AppLocalizations.tr(l10n.abrirVistaPreviaPrivada)),
                      ),
                    ],
                    if (_step == 5) ...[
                      Text(
                        _space['verified'] == true
                            ? core_l10n.AppLocalizations.tr(l10n.espacioAutorizado)
                            : core_l10n.AppLocalizations.tr(l10n.espacioPendienteRevision),
                      ),
                      Text(
                        core_l10n.AppLocalizations.tr(
                          l10n.version(_stateLabel(_record?.state ?? 'draft')),
                        ),
                      ),
                      if (_record?.publicRevisionId != null)
                        Text(core_l10n.AppLocalizations.tr(l10n.versionPublicaDisponible)),
                      for (final issue in _doc.publicationProblems)
                        TourNotice(_publicationProblemLabel(issue)),
                      if (_doc.points.any(
                        (p) =>
                            p.link != null && p.link!['status'] != 'approved',
                      ))
                        TourNotice(core_l10n.AppLocalizations.tr(l10n.vinculosPendientes)),
                      OutlinedButton(
                        onPressed: () async {
                          final start = await _pickDateTime(
                            core_l10n.AppLocalizations.tr(l10n.inicioVigencia),
                          );
                          if (!mounted || !_current || start == null) return;
                          final end = await _pickDateTime(core_l10n.AppLocalizations.tr(l10n.finVigencia));
                          if (!mounted || !_current || end == null) return;
                          if (!end.isAfter(start)) {
                            setState(() => _error = core_l10n.AppLocalizations.tr(l10n.finPosteriorInicio));
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
                        child: Text(core_l10n.AppLocalizations.tr(l10n.definirVigenciaTemporal)),
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
                        child: Text(core_l10n.AppLocalizations.tr(l10n.vigenciaPermanente)),
                      ),
                      FilledButton(
                        onPressed: _busy || _doc.publicationProblems.isNotEmpty
                            ? null
                            : _submit,
                        child: Text(
                          _space['verified'] == true
                              ? core_l10n.AppLocalizations.tr(l10n.publicarVersion)
                              : core_l10n.AppLocalizations.tr(l10n.enviarRevision),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(
                        _busy ? core_l10n.AppLocalizations.tr(l10n.guardando) : core_l10n.AppLocalizations.tr(l10n.guardarBorrador),
                      ),
                    ),
                    if (_step < 5)
                      TextButton(
                        onPressed: () => setState(() => _step++),
                        child: Text(core_l10n.AppLocalizations.tr(l10n.continuarPaso)),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
