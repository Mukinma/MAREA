import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:uuid/uuid.dart';

class MissionComposerScreen extends StatefulWidget {
  const MissionComposerScreen({
    super.key,
    required this.controller,
    this.missionId,
    this.draftId,
  }) : assert(missionId == null || draftId == null);

  final AppSessionController controller;
  final String? missionId;
  final String? draftId;

  @override
  State<MissionComposerScreen> createState() => _MissionComposerScreenState();
}

class _MissionComposerScreenState extends State<MissionComposerScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _body = TextEditingController(),
      _location = TextEditingController(),
      _capacity = TextEditingController(text: '5'),
      _requirements = TextEditingController(),
      _conditions = TextEditingController(),
      _amount = TextEditingController();
  final _dateKey = GlobalKey<FormFieldState<DateTime>>();
  final _scroll = ScrollController();
  late final String _draftId;
  String _category = 'otros';
  String? _compensation = 'negotiable';
  UserType? _target;
  DateTime? _date;
  TimeOfDay? _time;
  PostCoordinates? _coordinates;
  Uint8List? _image;
  String? _imagePath, _savedDraftImage, _error;
  Mission? _original;
  String? _publishedId;
  int _step = 0;
  bool _busy = false,
      _loading = false,
      _dirty = false,
      _allowExit = false,
      _confirming = false,
      _draftSaved = false,
      _draftSaveAttempted = false,
      _publishStarted = false,
      _scheduleChanged = false;

  bool get _editing => widget.missionId != null;
  bool get _locked => _original?.conditionsLocked ?? false;
  bool get _unavailable => (_editing || widget.draftId != null) && !_loaded;
  bool _loaded = false;

  // Text edits must never round the original timestamp to a whole minute.
  DateTime? get _start => _original != null && !_scheduleChanged
      ? _original!.startsAt.toLocal()
      : _date == null || _time == null
      ? null
      : DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        );

  int? get _amountCents {
    final raw = _amount.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(raw)) return null;
    final parts = raw.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  @override
  void initState() {
    super.initState();
    _draftId = widget.draftId ?? const Uuid().v4();
    if (_editing || widget.draftId != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = widget.controller.communityRepository;
      if (repo == null || widget.controller.profile == null) {
        throw StateError('unavailable');
      }
      if (_editing) {
        final m = await repo.mission(widget.missionId!);
        if (m == null ||
            m.authorId != widget.controller.profile!.id ||
            m.isTerminal ||
            m.hidden) {
          throw StateError('not_editable');
        }
        if (!mounted) return;
        _original = m;
        _restore({
          'title': m.title,
          'body': m.body,
          'category': m.category,
          'location': m.location,
          'capacity': m.capacity,
          'requirements': m.requirements,
          'conditions': m.conditions,
          'target_type': m.targetType?.databaseValue,
          'image_path': m.imagePath,
          'starts_at': m.startsAt.toIso8601String(),
          'compensation_type': m.compensationType,
          'compensation_amount_cents': m.compensationAmountCents,
          ...?m.coordinates?.toJson(),
        });
      } else {
        final draft = await repo.missionDraft(_draftId);
        if (draft == null) throw StateError('missing_draft');
        if (!mounted) return;
        if (draft.publishedMissionId != null) {
          context.go('/missions/${draft.publishedMissionId}');
          return;
        }
        if (draft.isPublished) throw StateError('published_mission_removed');
        _restore(draft.data);
        _savedDraftImage = _imagePath;
        _draftSaved = true;
      }
      _loaded = true;
    } catch (error) {
      if (mounted) {
        _error = error is StateError
            ? (_editing
                  ? 'Esta misión no está disponible para editar.'
                  : 'Este borrador no está disponible.')
            : communityError(error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restore(Map<String, dynamic> data) {
    _title.text = data['title'] as String? ?? '';
    _body.text = data['body'] as String? ?? '';
    _location.text = data['location'] as String? ?? '';
    _capacity.text =
        data['capacity_text'] as String? ?? '${data['capacity'] ?? ''}';
    _requirements.text = data['requirements'] as String? ?? '';
    _conditions.text = data['conditions'] as String? ?? '';
    final category = data['category'] as String?;
    _category = communityCategories.containsKey(category) ? category! : 'otros';
    final type = data['target_type'] as String?;
    _target = type == null ? null : UserType.fromDatabase(type);
    _imagePath = data['image_path'] as String?;
    _coordinates = PostCoordinates.fromJson(data);
    _compensation = data['compensation_type'] as String?;
    final cents = (data['compensation_amount_cents'] as num?)?.toInt();
    _amount.text =
        data['compensation_amount_text'] as String? ??
        (cents == null ? '' : (cents / 100).toStringAsFixed(2));
    final start = DateTime.tryParse(
      data['starts_at'] as String? ?? '',
    )?.toLocal();
    _date = start ?? DateTime.tryParse(data['starts_date'] as String? ?? '');
    _time = start != null
        ? TimeOfDay.fromDateTime(start)
        : data['starts_hour'] is int && data['starts_minute'] is int
        ? TimeOfDay(
            hour: data['starts_hour'] as int,
            minute: data['starts_minute'] as int,
          )
        : null;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _body,
      _location,
      _capacity,
      _requirements,
      _conditions,
      _amount,
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _dirty = true);

  void _exit([String? missionId]) {
    setState(() {
      _allowExit = true;
      _dirty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(missionId ?? (_editing ? true : null));
      } else {
        context.go(missionId == null ? '/missions' : '/missions/$missionId');
      }
    });
  }

  Future<void> _leave() async {
    if (_busy || _confirming) return;
    if (_publishedId != null) {
      _exit(_publishedId);
      return;
    }
    if (!_dirty) {
      _exit();
      return;
    }
    _confirming = true;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          _editing ? '¿Salir sin guardar?' : '¿Qué hacemos con tu idea?',
        ),
        content: Text(
          _editing
              ? 'Tienes cambios que todavía no has guardado.'
              : 'Puedes guardar lo que llevas y continuar después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Descartar cambios'),
          ),
          if (!_editing)
            FilledButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: const Text('Guardar borrador'),
            ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted || choice == null) return;
    if (choice == 'save') {
      if (await _saveDraft()) {
        if (mounted) _exit();
      }
    } else {
      // Discard means removing a saved draft too, never silently deleting on Back.
      if (!_editing && (_draftSaved || _draftSaveAttempted)) {
        setState(() {
          _busy = true;
          _error = null;
        });
        try {
          final repo = widget.controller.communityRepository!;
          final draft = await repo.missionDraft(_draftId);
          if (draft?.isPublished == true) {
            _showPublished(draft!);
            return;
          }
          if (draft != null) await repo.deleteMissionDraft(_draftId);
          if (_imagePath != null) {
            try {
              await repo.removeMissionImage(_imagePath!);
            } catch (_) {
              /* Already removed or still referenced. */
            }
          }
        } catch (error) {
          if (mounted) setState(() => _error = communityError(error));
          return;
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      }
      if (mounted) _exit();
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await ProfileImagePicker.pick(avatar: false);
      if (mounted && bytes != null) {
        setState(() {
          _image = bytes;
          _dirty = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPlace() async {
    final result = await showCommunityLocationPicker(
      context,
      initial: _coordinates == null
          ? null
          : PostLocationSelection(
              label: _location.text,
              coordinates: _coordinates!,
            ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _coordinates = result.coordinates;
      _location.text = result.label;
      _dirty = true;
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date == null || _date!.isBefore(today) ? today : _date!,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
      helpText: 'Fecha de la misión',
      locale: const Locale('es', 'MX'),
    );
    if (!mounted || d == null) return;
    setState(() {
      _date = d;
      _scheduleChanged = true;
      _dirty = true;
    });
    _dateKey.currentState?.didChange(_start);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Hora de inicio',
    );
    if (!mounted || t == null) return;
    setState(() {
      _time = t;
      _scheduleChanged = true;
      _dirty = true;
    });
    _dateKey.currentState?.didChange(_start);
  }

  Map<String, dynamic> get _draftData => {
    'title': _title.text,
    'body': _body.text,
    'category': _category,
    'target_type': _target?.databaseValue,
    'capacity': int.tryParse(_capacity.text),
    'capacity_text': _capacity.text,
    'requirements': _requirements.text,
    'conditions': _conditions.text,
    'location': _location.text,
    'starts_at': _start?.toUtc().toIso8601String(),
    'starts_date': _date == null
        ? null
        : DateUtils.dateOnly(_date!).toIso8601String(),
    'starts_hour': _time?.hour,
    'starts_minute': _time?.minute,
    'image_path': _imagePath,
    'location_latitude': _coordinates?.latitude,
    'location_longitude': _coordinates?.longitude,
    'location_precision': _coordinates?.precision.name,
    'compensation_type': _compensation,
    'compensation_amount_cents': _compensation == 'paid' ? _amountCents : null,
    'compensation_amount_text': _amount.text,
  };

  // Keep the uploaded path after a failed RPC: its response may have been lost.
  // A retry then uses the same image and operation ID instead of creating orphans.
  Future<void> _uploadImage() async {
    if (_image == null) return;
    final path = await widget.controller.communityRepository!
        .uploadMissionImage(_image!);
    _imagePath = path;
    _image = null;
  }

  Future<void> _cleanOldDraftImage() async {
    final previous = _savedDraftImage;
    _savedDraftImage = _imagePath;
    if (previous != null && previous != _imagePath) {
      try {
        await widget.controller.communityRepository!.removeMissionImage(
          previous,
        );
      } catch (_) {
        /* Account cleanup can retry. */
      }
    }
  }

  Future<bool> _saveDraft() async {
    if (_busy || _editing) return false;
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      setState(() => _error = 'No pudimos conectar. Inténtalo de nuevo.');
      return false;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_publishStarted && await _recoverPublished(repo)) return false;
      await _uploadImage();
      _draftSaveAttempted = true;
      await repo.saveMissionDraft(_draftData, id: _draftId);
      _draftSaved = true;
      await _cleanOldDraftImage();
      if (!mounted) return true;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrador guardado. Puedes retomarlo en Mis misiones.'),
        ),
      );
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPublished(MissionDraft draft) {
    setState(() {
      _publishedId = draft.publishedMissionId;
      if (_publishedId == null) _dirty = false;
      _error = _publishedId == null
          ? 'Esta misión ya fue publicada y ya no está disponible.'
          : 'Tu misión ya fue publicada. Los cambios posteriores no se publicaron.';
    });
  }

  Future<bool> _recoverPublished(CommunityRepository repo) async {
    final draft = await repo.missionDraft(_draftId);
    if (draft?.isPublished != true) return false;
    if (draft!.publishedMissionId != null &&
        _image == null &&
        _start != null &&
        mapEquals(_input().toJson(), draft.data)) {
      if (mounted) _exit(draft.publishedMissionId);
    } else if (mounted) {
      _showPublished(draft);
    }
    return true;
  }

  MissionInput _input() => MissionInput(
    title: _title.text,
    body: _body.text,
    category: _category,
    location: _location.text,
    startsAt: _start!,
    capacity: int.tryParse(_capacity.text) ?? 0,
    targetType: _target,
    coordinates: _coordinates,
    imagePath: _imagePath,
    requirements: _requirements.text,
    conditions: _conditions.text,
    compensationType: _compensation,
    compensationAmountCents: _compensation == 'paid' ? _amountCents : null,
  );

  String? _invalidStep(int step) {
    if (step == 0) {
      if (_title.text.trim().length < 3 || _title.text.trim().length > 100) {
        return 'Revisa el título de la misión.';
      }
      if (_body.text.trim().isEmpty || _body.text.trim().length > 3000) {
        return 'Completa la descripción de la misión.';
      }
    } else if (step == 1) {
      final capacity = int.tryParse(_capacity.text);
      if (capacity == null ||
          capacity < 1 ||
          capacity > 100 ||
          (_locked && capacity < _original!.capacity)) {
        return 'Revisa el cupo de la misión.';
      }
      if (_requirements.text.trim().length > 3000 ||
          _conditions.text.trim().length > 3000) {
        return 'Revisa los requisitos y condiciones.';
      }
      if ((!_editing && _compensation == null) ||
          validateMissionCompensation(
                _compensation,
                _compensation == 'paid' ? _amountCents : null,
              ) !=
              null) {
        return 'Revisa la compensación de la misión.';
      }
    } else if (step == 2) {
      if (_location.text.trim().isEmpty || _location.text.trim().length > 180) {
        return 'Completa el lugar de la misión.';
      }
      if (_start == null) return 'Selecciona la fecha y la hora.';
      if ((_original == null || _start != _original!.startsAt.toLocal()) &&
          !_start!.isAfter(DateTime.now())) {
        return 'Elige una fecha y hora futuras.';
      }
      if (_coordinates != null && !_coordinates!.isValid) {
        return 'La ubicación seleccionada no es válida.';
      }
    }
    return null;
  }

  Future<bool> _validateVisible() async {
    FocusScope.of(context).unfocus();
    final invalid = _form.currentState?.validateGranularly() ?? {};
    if (invalid.isEmpty) return _invalidStep(_step) == null;
    final field = invalid.first;
    await Scrollable.ensureVisible(
      field.context,
      duration: const Duration(milliseconds: 180),
      alignment: .2,
    );
    if (!mounted || !field.mounted) return false;
    FocusNode? focus;
    void find(Element e) {
      if (focus != null) return;
      if (e.widget is EditableText) {
        focus = (e.widget as EditableText).focusNode;
      } else {
        e.visitChildren(find);
      }
    }

    (field.context as Element).visitChildren(find);
    focus?.requestFocus();
    return false;
  }

  void _jump(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _continue() async {
    if (_busy) return;
    if (await _validateVisible() && mounted) _jump(_step + 1);
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_publishedId != null) {
      _exit(_publishedId);
      return;
    }
    for (var step = 0; step < 3; step++) {
      final error = _invalidStep(step);
      if (error != null) {
        _jump(step);
        setState(() => _error = error);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _validateVisible();
        });
        return;
      }
    }
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      setState(() => _error = 'No pudimos conectar. Inténtalo de nuevo.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_editing && _publishStarted && await _recoverPublished(repo)) return;
      await _uploadImage();
      final input = _input();
      final String id;
      if (_editing) {
        id = widget.missionId!;
        await repo.updateMission(id, input);
        final old = _original?.imagePath;
        if (old != null && old != input.imagePath) {
          try {
            await repo.removeMissionImage(old);
          } catch (_) {
            /* The saved mission stays valid. */
          }
        }
      } else {
        {
          _draftSaveAttempted = true;
          await repo.saveMissionDraft(_draftData, id: _draftId);
          _draftSaved = true;
          await _cleanOldDraftImage();
          _publishStarted = true;
        }
        id = await repo.publishMissionDraft(_draftId, input);
      }
      if (mounted) _exit(id);
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _titles = [
    '¿Qué quieres hacer posible?',
    'Demos forma a la colaboración',
    'Un lugar y un momento',
    'Revisa tu misión',
  ];
  static const _names = [
    'La idea',
    'La colaboración',
    'Lugar y fecha',
    'Revisar',
  ];
  static const _subtitles = [
    'Una idea clara invita a más personas a sumarse.',
    'Cuenta qué necesitas y qué ofreces a quienes participen.',
    'Ayuda a las personas a organizarse y llegar.',
    'Así se verá tu convocatoria. Puedes corregir cada sección.',
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit || (!_dirty && !_busy),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Volver a misiones',
          onPressed: _busy ? null : _leave,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _editing ? 'Editar misión' : 'Nueva misión',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _busy ? null : _leave,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _unavailable
          ? Center(
              child: CommunityNotice(
                message: _error ?? 'Misión no disponible',
                onRetry: _load,
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Paso ${_step + 1} de 4: ${_names[_step]}',
                        child: Row(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i <= _step
                                        ? AppColors.aqua
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'PASO ${_step + 1} DE 4 · ${_names[_step].toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.aquaDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _titles[_step],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandNavy,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitles[_step],
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CommunityNotice(message: _error!),
                        ),
                      if (_locked && (_step == 1 || _step == 2))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CommunityNotice(
                            message:
                                'Ya recibiste candidaturas: el perfil, la fecha, el lugar y la compensación quedan fijos. Puedes corregir los textos y aumentar el cupo.',
                            icon: Icons.lock_outline,
                          ),
                        ),
                      Form(
                        key: _form,
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: switch (_step) {
                            0 => _idea(),
                            1 => _collaboration(),
                            2 => _placeDate(),
                            _ => _review(),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _loading || _unavailable ? null : _footer(),
    ),
  );

  Widget _idea() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _text(
        _title,
        'Título de la misión',
        'Ej. Retrata la vida de nuestro mercado',
        max: 100,
        min: 3,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _category,
        isExpanded: true,
        decoration: _decoration('Categoría'),
        items: [
          for (final e in communityCategories.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: _busy
            ? null
            : (v) => setState(() {
                _category = v!;
                _dirty = true;
              }),
      ),
      const SizedBox(height: 20),
      _text(
        _body,
        'Descripción',
        '¿Qué haremos y por qué vale la pena sumarse?',
        max: 3000,
        min: 1,
        lines: 5,
      ),
      const SizedBox(height: 16),
      const Text(
        'Imagen de portada',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.brandNavy,
        ),
      ),
      const SizedBox(height: 10),
      if (_image != null || _imagePath != null) ...[
        MissionCover(
          path: _imagePath,
          bytes: _image,
          repository: widget.controller.communityRepository,
          height: 170,
        ),
        const SizedBox(height: 10),
      ],
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _image == null && _imagePath == null
                        ? 'Agregar fotografía'
                        : 'Cambiar fotografía',
                  ),
                ),
                if (_image != null || _imagePath != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _image = null;
                            _imagePath = null;
                            _dirty = true;
                          }),
                    child: const Text('Quitar'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Opcional · JPG, PNG o WebP · hasta 10 MB',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _collaboration() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<UserType?>(
        initialValue: _target,
        isExpanded: true,
        decoration: _decoration('Perfil participante'),
        items: [
          const DropdownMenuItem<UserType?>(
            value: null,
            child: Text('Todos los perfiles'),
          ),
          for (final t in UserType.values)
            DropdownMenuItem(value: t, child: Text(t.databaseValue)),
        ],
        onChanged: _busy || _locked
            ? null
            : (v) => setState(() {
                _target = v;
                _dirty = true;
              }),
      ),
      const SizedBox(height: 20),
      _text(
        _capacity,
        'Cupo',
        'Número de participantes',
        max: 3,
        number: true,
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null || n < 1 || n > 100) {
            return 'Elige entre 1 y 100 personas.';
          }
          if (_locked && n < _original!.capacity) {
            return 'El cupo solo puede aumentar (mínimo ${_original!.capacity}).';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      const Text(
        'Compensación',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.brandNavy,
        ),
      ),
      const SizedBox(height: 8),
      FormField<String>(
        initialValue: _compensation,
        validator: (_) => !_editing && _compensation == null
            ? 'Elige una compensación.'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in const {
                  'unpaid': 'Sin pago',
                  'negotiable': 'Por acordar',
                  'paid': 'Importe fijo',
                }.entries)
                  ChoiceChip(
                    labelStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
                    label: Text(e.value),
                    selected: _compensation == e.key,
                    onSelected: _busy || _locked
                        ? null
                        : (_) => setState(() {
                            _compensation = e.key;
                            state.didChange(e.key);
                            _dirty = true;
                          }),
                  ),
              ],
            ),
            if (_compensation == null && _editing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Compensación no indicada en la misión original.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
      if (_compensation == 'paid') ...[
        const SizedBox(height: 16),
        _text(
          _amount,
          'Importe por participante (MXN)',
          'Ej. 250.50',
          max: 11,
          decimal: true,
          enabled: !_locked,
          validator: (_) {
            if (_amountCents == null ||
                _amountCents! <= 0 ||
                _amountCents! > 9999999900) {
              return 'Introduce un importe positivo con hasta dos decimales.';
            }
            return null;
          },
        ),
      ],
      const SizedBox(height: 20),
      _text(
        _requirements,
        'Requisitos (opcional)',
        'Experiencia, materiales o habilidades necesarias',
        max: 3000,
        lines: 3,
      ),
      const SizedBox(height: 16),
      _text(
        _conditions,
        'Qué ofrecemos y condiciones (opcional)',
        'Recursos, acuerdos y detalles de la participación',
        max: 3000,
        lines: 3,
      ),
    ],
  );

  Widget _placeDate() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _text(
        _location,
        'Lugar',
        'Ej. Casa de la Cultura, Manzanillo',
        max: 180,
        min: 1,
        enabled: !_locked,
        onChanged: (_) {
          _coordinates = null;
        },
      ),
      TextButton.icon(
        onPressed: _busy || _locked ? null : _pickPlace,
        icon: const Icon(Icons.map_outlined),
        label: Text(
          _coordinates == null
              ? 'Ubicar en el mapa (opcional)'
              : 'Cambiar punto del mapa',
        ),
      ),
      const Text(
        'Puedes escribir el lugar sin usar el mapa ni compartir tu ubicación.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      if (_coordinates != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _coordinates!.isApproximate
                ? 'Punto aproximado guardado'
                : 'Punto del mapa guardado',
            style: const TextStyle(color: AppColors.aquaDark),
          ),
        ),
      const SizedBox(height: 24),
      const Text(
        'Fecha y hora',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.brandNavy,
        ),
      ),
      const SizedBox(height: 12),
      FormField<DateTime>(
        key: _dateKey,
        validator: (_) {
          if (_start == null) return 'Selecciona la fecha y la hora.';
          if ((_original == null || _start != _original!.startsAt.toLocal()) &&
              !_start!.isAfter(DateTime.now())) {
            return 'Elige una fecha y hora futuras.';
          }
          return null;
        },
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || _locked ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _date == null
                        ? 'Seleccionar fecha'
                        : '${_date!.day}/${_date!.month}/${_date!.year}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _locked ? null : _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _time == null ? 'Seleccionar hora' : _time!.format(context),
                  ),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _card(
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.aquaDark),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Las personas podrán enviar su candidatura hasta el inicio de la misión.',
              ),
            ),
          ],
        ),
        color: AppColors.mist,
      ),
    ],
  );

  Widget _review() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_image != null || _imagePath != null) ...[
        MissionCover(
          path: _imagePath,
          bytes: _image,
          repository: widget.controller.communityRepository,
          height: 210,
        ),
        const SizedBox(height: 16),
      ],
      _reviewSection('La idea', 0, [
        Text(
          communityCategories[_category] ?? _category,
          style: const TextStyle(
            color: AppColors.aquaDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _title.text.trim(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(_body.text.trim()),
      ]),
      _reviewSection('La colaboración', 1, [
        _summaryRow(
          Icons.people_outline,
          '${_target?.databaseValue ?? 'Todos los perfiles'} · ${_capacity.text} lugares',
        ),
        _summaryRow(
          Icons.payments_outlined,
          missionCompensationLabel(
            _compensation,
            _compensation == 'paid' ? _amountCents : null,
          ),
        ),
        const SizedBox(height: 12),
        const Text('Requisitos', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          _requirements.text.trim().isEmpty
              ? 'Sin requisitos adicionales.'
              : _requirements.text.trim(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Condiciones',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _conditions.text.trim().isEmpty
              ? 'Sin condiciones adicionales.'
              : _conditions.text.trim(),
        ),
      ]),
      _reviewSection('Lugar y fecha', 2, [
        _summaryRow(Icons.location_on_outlined, _location.text.trim()),
        if (_coordinates != null)
          Text(
            _coordinates!.isApproximate
                ? 'Ubicación aproximada en el mapa'
                : 'Punto del mapa incluido',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        _summaryRow(
          Icons.calendar_today_outlined,
          _start == null ? 'Fecha y hora por definir' : missionDate(_start!),
        ),
      ]),
      _card(
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.aquaDark),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Las candidaturas son privadas. Podrás revisarlas y elegir a las personas participantes desde la gestión de tu misión.',
              ),
            ),
          ],
        ),
        color: AppColors.mist,
      ),
    ],
  );

  Widget _summaryRow(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.aquaDark),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    ),
  );

  Widget _reviewSection(String title, int step, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandNavy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _jump(step),
                    child: Text('Editar ${_names[step].toLowerCase()}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _card(Widget child, {Color color = Colors.white}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  Widget _footer() {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final secondary = OutlinedButton(
      onPressed: _busy || _publishedId != null
          ? null
          : _step == 0
          ? (_editing
                ? _leave
                : () {
                    _saveDraft();
                  })
          : () => _jump(_step - 1),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: const StadiumBorder(),
      ),
      child: Text(
        _step == 0 ? (_editing ? 'Cancelar' : 'Guardar borrador') : 'Atrás',
        textAlign: TextAlign.center,
      ),
    );
    final primary = FilledButton.icon(
      onPressed: _busy
          ? null
          : _publishedId != null || _step == 3
          ? _submit
          : _continue,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.actionBlue,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
      ),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_rounded, size: 20),
      label: Text(
        _busy
            ? 'Guardando…'
            : _publishedId != null
            ? 'Ver misión publicada'
            : _step == 3
            ? (_editing ? 'Guardar cambios' : 'Publicar misión')
            : 'Continuar',
        textAlign: TextAlign.center,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stack =
                      constraints.maxWidth < 600 &&
                      MediaQuery.textScalerOf(context).scale(15) > 19;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stack) ...[
                        SizedBox(width: double.infinity, child: primary),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: secondary),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              flex: _step == 0 ? 1 : 2,
                              child: secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(flex: _step == 0 ? 1 : 3, child: primary),
                          ],
                        ),
                      if (!_editing &&
                          _publishedId == null &&
                          _step > 0 &&
                          keyboard == 0)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  _saveDraft();
                                },
                          child: const Text('Guardar borrador'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, [String? hint]) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  Widget _text(
    TextEditingController controller,
    String label,
    String hint, {
    required int max,
    int min = 0,
    int lines = 1,
    bool number = false,
    bool decimal = false,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    enabled: enabled && !_busy,
    decoration: _decoration(label, hint),
    maxLength: max,
    maxLines: lines,
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : number
        ? TextInputType.number
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    onChanged: (v) {
      onChanged?.call(v);
      _changed();
    },
    validator:
        validator ??
        (v) {
          final n = v?.trim().length ?? 0;
          if (n < min) {
            return min == 1
                ? 'Completa este campo.'
                : 'Escribe al menos $min caracteres.';
          }
          if (n > max) return 'Usa hasta $max caracteres.';
          return null;
        },
  );
}
