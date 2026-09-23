import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';

class MissionComposerScreen extends StatefulWidget {
  const MissionComposerScreen({
    super.key,
    required this.controller,
    this.missionId,
  });
  final AppSessionController controller;
  final String? missionId;
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
      _conditions = TextEditingController();
  final _dateKey = GlobalKey<FormFieldState<DateTime>>();
  final _scroll = ScrollController();
  String _category = 'otros';
  UserType? _target;
  DateTime? _date;
  TimeOfDay? _time;
  PostCoordinates? _coordinates;
  Uint8List? _image;
  String? _imagePath, _error;
  Mission? _original;
  bool _busy = false,
      _loading = false,
      _dirty = false,
      _allowExit = false,
      _confirming = false;
  bool _scheduleChanged = false;
  bool get _locked => _original?.conditionsLocked ?? false;
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

  @override
  void initState() {
    super.initState();
    if (widget.missionId != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final m = await widget.controller.communityRepository!.mission(
        widget.missionId!,
      );
      if (!mounted) return;
      if (m == null ||
          m.authorId != widget.controller.profile?.id ||
          m.isTerminal ||
          m.hidden) {
        throw StateError('not_editable');
      }
      _original = m;
      _title.text = m.title;
      _body.text = m.body;
      _location.text = m.location;
      _capacity.text = '${m.capacity}';
      _requirements.text = m.requirements ?? '';
      _conditions.text = m.conditions ?? '';
      _category = m.category;
      _target = m.targetType;
      _imagePath = m.imagePath;
      _coordinates = m.coordinates;
      _date = m.startsAt.toLocal();
      _time = TimeOfDay.fromDateTime(_date!);
    } catch (error) {
      if (mounted) {
        _error = error is StateError
            ? 'Esta misión no está disponible para editar.'
            : communityError(error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _dirty = true);

  Future<void> _leave() async {
    if (_busy || _confirming) return;
    _confirming = true;
    final leave =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('¿Salir sin guardar?'),
                content: const Text('Los cambios de esta misión se perderán.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Seguir editando'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Salir sin guardar'),
                  ),
                ],
              ),
            ) ==
            true;
    _confirming = false;
    if (!mounted || !leave) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/missions');
      }
    });
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
    final initial = _date == null || _date!.isBefore(today) ? today : _date!;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
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

  MissionInput _input(String? path) => MissionInput(
    title: _title.text,
    body: _body.text,
    category: _category,
    location: _location.text,
    startsAt: _start!,
    capacity: int.tryParse(_capacity.text) ?? 0,
    targetType: _target,
    coordinates: _coordinates,
    imagePath: path,
    requirements: _requirements.text,
    conditions: _conditions.text,
  );
  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      await Scrollable.ensureVisible(
        field.context,
        duration: const Duration(milliseconds: 250),
        alignment: .2,
      );
      if (mounted && field.mounted) {
        FocusNode? node;
        void find(Element e) {
          if (node != null) return;
          final w = e.widget;
          if (w is EditableText) {
            node = w.focusNode;
          } else {
            e.visitChildren(find);
          }
        }

        (field.context as Element).visitChildren(find);
        node?.requestFocus();
      }
      return;
    }
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      setState(() => _error = 'No pudimos conectar. Inténtalo de nuevo.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? uploaded;
    bool persisted = false;
    try {
      if (_image != null) uploaded = await repo.uploadMissionImage(_image!);
      final input = _input(uploaded ?? _imagePath);
      final String id;
      if (widget.missionId == null) {
        id = await repo.createMission(input);
      } else {
        id = widget.missionId!;
        await repo.updateMission(id, input);
      }
      persisted = true;
      final old = _original?.imagePath;
      if (old != null && old != input.imagePath) {
        try {
          await repo.removeMissionImage(old);
        } catch (_) {
          /* The saved mission remains valid; account cleanup retries orphan removal. */
        }
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _allowExit = true;
        _busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (context.canPop()) {
          context.pop(widget.missionId == null ? id : true);
        } else {
          context.go('/missions/$id');
        }
      });
    } catch (error) {
      if (uploaded != null && !persisted) {
        try {
          await repo.removeMissionImage(uploaded);
        } catch (_) {}
      }
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Mission get _preview => Mission(
    id: 'preview',
    authorId: widget.controller.profile?.id ?? '',
    title: _title.text.trim().isEmpty
        ? 'El comienzo de una gran idea'
        : _title.text.trim(),
    body: _body.text.trim().isEmpty
        ? 'Cuenta qué quieres hacer y cómo puede sumarse la comunidad.'
        : _body.text.trim(),
    category: _category,
    location: _location.text.trim().isEmpty
        ? 'Lugar por definir'
        : _location.text.trim(),
    startsAt: _start ?? DateTime.now().add(const Duration(days: 1)),
    capacity: (int.tryParse(_capacity.text) ?? 5).clamp(1, 100),
    createdAt: DateTime.now(),
    targetType: _target,
    imagePath: _imagePath,
    organizerName: widget.controller.profile?.fullName,
    requirements: _requirements.text.trim().isEmpty
        ? null
        : _requirements.text.trim(),
    conditions: _conditions.text.trim().isEmpty
        ? null
        : _conditions.text.trim(),
  );
  Widget _previewWidget() => MissionSummary(
    mission: _preview,
    repository: widget.controller.communityRepository,
    bytes: _image,
    preview: true,
    dateLabel: _start == null ? 'Fecha y hora por definir' : null,
  );
  void _showPreview() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Cerrar vista previa',
              onPressed: () => Navigator.pop(c),
              icon: const Icon(Icons.close),
            ),
          ),
          _previewWidget(),
          const SizedBox(height: 20),
          if (_requirements.text.isNotEmpty)
            Text('Requisitos\n${_requirements.text}'),
          if (_conditions.text.isNotEmpty)
            Text('Condiciones\n${_conditions.text}'),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit || (!_dirty && !_busy),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: IconButton(
          tooltip: 'Volver a misiones',
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : _leave,
        ),
        title: Text(
          widget.missionId == null ? 'Crear misión' : 'Editar misión',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.missionId != null && _original == null
          ? Center(
              child: CommunityNotice(
                message: _error ?? 'Misión no disponible',
                onRetry: _load,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                return SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 16,
                    20,
                    wide ? 32 : 16,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.missionId == null
                                ? 'Las buenas ideas se hacen en equipo.'
                                : 'Dale forma a tu convocatoria.',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandNavy,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Comparte una oportunidad clara y encuentra personas con quienes hacerla realidad.',
                          ),
                          const SizedBox(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    children: [
                                      if (_error != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: CommunityNotice(
                                            message: _error!,
                                          ),
                                        ),
                                      if (_locked)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 16),
                                          child: CommunityNotice(
                                            message:
                                                'Ya recibiste postulaciones. La fecha, el lugar y el perfil buscado quedan fijos. Puedes corregir los textos y aumentar el cupo.',
                                            icon: Icons.lock_outline,
                                          ),
                                        ),
                                      _section(
                                        '01',
                                        'La oportunidad',
                                        'Una idea que invite a participar.',
                                        [
                                          _text(
                                            _title,
                                            'Título de la misión',
                                            'Ej. Un mural para nuestro barrio',
                                            max: 100,
                                            min: 3,
                                          ),
                                          const SizedBox(height: 18),
                                          DropdownButtonFormField<String>(
                                            initialValue: _category,
                                            isExpanded: true,
                                            decoration: _decoration(
                                              'Categoría',
                                            ),
                                            items: [
                                              for (final e
                                                  in communityCategories
                                                      .entries)
                                                DropdownMenuItem(
                                                  value: e.key,
                                                  child: Text(e.value),
                                                ),
                                            ],
                                            onChanged: _busy
                                                ? null
                                                : (v) => setState(() {
                                                    _category = v!;
                                                    _dirty = true;
                                                  }),
                                          ),
                                          const SizedBox(height: 18),
                                          _text(
                                            _body,
                                            'Descripción',
                                            '¿Qué haremos y por qué vale la pena sumarse?',
                                            max: 3000,
                                            min: 1,
                                            lines: 5,
                                          ),
                                          const SizedBox(height: 18),
                                          if (_image != null ||
                                              _imagePath != null) ...[
                                            MissionCover(
                                              path: _imagePath,
                                              bytes: _image,
                                              repository: widget
                                                  .controller
                                                  .communityRepository,
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _busy
                                                    ? null
                                                    : _pickImage,
                                                icon: const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                ),
                                                label: Text(
                                                  _image == null &&
                                                          _imagePath == null
                                                      ? 'Agregar fotografía'
                                                      : 'Cambiar fotografía',
                                                ),
                                              ),
                                              if (_image != null ||
                                                  _imagePath != null)
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
                                          const Text(
                                            'Portada opcional · JPG, PNG o WebP · hasta 10 MB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _section(
                                        '02',
                                        'Qué buscamos y ofrecemos',
                                        'Define cómo será la colaboración.',
                                        [
                                          DropdownButtonFormField<UserType?>(
                                            initialValue: _target,
                                            isExpanded: true,
                                            decoration: _decoration(
                                              'Perfil participante',
                                            ),
                                            items: [
                                              const DropdownMenuItem<UserType?>(
                                                value: null,
                                                child: Text(
                                                  'Todos los perfiles',
                                                ),
                                              ),
                                              for (final t in UserType.values)
                                                DropdownMenuItem(
                                                  value: t,
                                                  child: Text(t.databaseValue),
                                                ),
                                            ],
                                            onChanged: _busy || _locked
                                                ? null
                                                : (v) => setState(() {
                                                    _target = v;
                                                    _dirty = true;
                                                  }),
                                          ),
                                          const SizedBox(height: 18),
                                          _text(
                                            _capacity,
                                            'Cupo',
                                            'Número de participantes',
                                            max: 3,
                                            number: true,
                                            validator: (v) {
                                              final n = int.tryParse(v ?? '');
                                              if (n == null ||
                                                  n < 1 ||
                                                  n > 100) {
                                                return 'Elige entre 1 y 100 personas.';
                                              }
                                              if (_locked &&
                                                  n < _original!.capacity) {
                                                return 'El cupo solo puede aumentar (mínimo ${_original!.capacity}).';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),
                                          _text(
                                            _requirements,
                                            'Requisitos (opcional)',
                                            'Experiencia, materiales o habilidades necesarias',
                                            max: 3000,
                                            lines: 3,
                                          ),
                                          const SizedBox(height: 18),
                                          _text(
                                            _conditions,
                                            'Qué ofrecemos y condiciones (opcional)',
                                            'Recursos, acuerdos y detalles de la participación',
                                            max: 3000,
                                            lines: 3,
                                          ),
                                        ],
                                      ),
                                      _section(
                                        '03',
                                        'Dónde y cuándo',
                                        'Que todas las personas sepan cómo llegar.',
                                        [
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
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: _busy || _locked
                                                  ? null
                                                  : _pickPlace,
                                              icon: const Icon(
                                                Icons.map_outlined,
                                              ),
                                              label: Text(
                                                _coordinates == null
                                                    ? 'Ubicar en el mapa (opcional)'
                                                    : 'Cambiar punto del mapa',
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            'Puedes escribir el lugar sin usar el mapa ni compartir tu ubicación.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          FormField<DateTime>(
                                            key: _dateKey,
                                            validator: (_) {
                                              if (_start == null) {
                                                return 'Selecciona la fecha y la hora.';
                                              }
                                              if (_original == null &&
                                                  !_start!.isAfter(
                                                    DateTime.now(),
                                                  )) {
                                                return 'Elige una fecha y hora futuras.';
                                              }
                                              if (_original != null &&
                                                  _start !=
                                                      _original!.startsAt
                                                          .toLocal() &&
                                                  !_start!.isAfter(
                                                    DateTime.now(),
                                                  )) {
                                                return 'Elige una fecha y hora futuras.';
                                              }
                                              return null;
                                            },
                                            builder: (state) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 10,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed:
                                                          _busy || _locked
                                                          ? null
                                                          : _pickDate,
                                                      icon: const Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                      ),
                                                      label: Text(
                                                        _date == null
                                                            ? 'Seleccionar fecha'
                                                            : '${_date!.day}/${_date!.month}/${_date!.year}',
                                                      ),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed:
                                                          _busy || _locked
                                                          ? null
                                                          : _pickTime,
                                                      icon: const Icon(
                                                        Icons.schedule,
                                                      ),
                                                      label: Text(
                                                        _time == null
                                                            ? 'Seleccionar hora'
                                                            : _time!.format(
                                                                context,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (state.hasError)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Text(
                                                      state.errorText!,
                                                      style: const TextStyle(
                                                        color: AppColors.error,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      _section(
                                        '04',
                                        'Revisión',
                                        'Todo listo para dar el siguiente paso.',
                                        [
                                          Text(
                                            _title.text.isEmpty
                                                ? 'Tu misión comenzará aquí.'
                                                : _title.text,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_target?.databaseValue ?? 'Todos los perfiles'} · ${_capacity.text} lugares',
                                          ),
                                          Text(
                                            _start == null
                                                ? 'Completa el lugar, la fecha y la hora.'
                                                : '${_location.text} · ${missionDate(_start!)}',
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Las postulaciones son privadas. Podrás revisar cada perfil y elegir a tus participantes.',
                                          ),
                                          if (!wide)
                                            TextButton.icon(
                                              onPressed: _showPreview,
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                              ),
                                              label: const Text(
                                                'Ver vista previa',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (wide) ...[
                                const SizedBox(width: 28),
                                Expanded(flex: 4, child: _previewWidget()),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.softBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : _leave,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FilledButton.icon(
                  onPressed:
                      _busy ||
                          _loading ||
                          (widget.missionId != null && _original == null)
                      ? null
                      : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _busy
                        ? 'Guardando…'
                        : widget.missionId == null
                        ? 'Publicar misión'
                        : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  InputDecoration _decoration(String label, [String? hint]) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.paper,
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.softBorder),
    ),
  );
  Widget _text(
    TextEditingController c,
    String label,
    String hint, {
    required int max,
    int min = 0,
    int lines = 1,
    bool number = false,
    bool enabled = true,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: c,
    enabled: enabled && !_busy,
    decoration: _decoration(label, hint),
    maxLength: max,
    maxLines: lines,
    keyboardType: number
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
  Widget _section(
    String number,
    String title,
    String subtitle,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: MissionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.aquaDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    ),
  );
}
