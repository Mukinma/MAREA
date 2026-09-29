import 'package:marea/shared/widgets/marea_tabs.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
export 'mission_composer_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';

String _date(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} · ${two(local.hour)}:${two(local.minute)}';
}

void _backToMissions(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/missions');
  }
}

String _applicationStatus(String status) => switch (status) {
  'accepted' => 'Aceptada',
  'rejected' => 'No seleccionada',
  'withdrawn' => 'Retirada',
  _ => 'Pendiente',
};

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({
    super.key,
    required this.controller,
    this.initialSection,
  });
  final AppSessionController controller;
  final String? initialSection;
  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  int _tab = 0, _offset = 0, _generation = 0;
  String _query = '';
  final _search = TextEditingController();
  String? _category;
  UserType? _target;
  String? _applicationFilter;
  bool _history = false;
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _loading = true, _more = false, _withdrawing = false;
  String? _error;
  List<Mission> _missions = [];
  List<MissionApplication> _applications = [];
  Map<String, Mission?> _appliedMissions = {};
  @override
  void initState() {
    super.initState();
    _tab = widget.initialSection == 'own'
        ? 1
        : widget.initialSection == 'applications'
        ? 2
        : 0;
    if (widget.initialSection == 'compatible') {
      _target = widget.controller.profile?.userType;
    }
    _load();
  }

  Future<void> _load({bool append = false}) async {
    final repo = widget.controller.communityRepository;
    final viewer = widget.controller.profile;
    final generation = ++_generation;
    if (repo == null || viewer == null) {
      setState(() {
        _loading = false;
        _error = 'Las misiones aún no están disponibles.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      if (!append) {
        _offset = 0;
        _missions = [];
        _applications = [];
        _appliedMissions = {};
      }
    });
    try {
      if (_tab == 2) {
        final applications = (await repo.applications())
            .where((a) => a.applicantId == viewer.id)
            .toList();
        final ids = applications.map((a) => a.missionId).toSet();
        final entries = await Future.wait(
          ids.map((id) async => MapEntry(id, await repo.mission(id))),
        );
        if (!mounted || generation != _generation) return;
        setState(() {
          _applications = applications;
          _appliedMissions = Map.fromEntries(entries);
          _more = false;
        });
      } else {
        final page = await repo.missions(
          authorId: _tab == 1 ? viewer.id : null,
          query: _tab == 0 ? _query : '',
          category: _tab == 0 ? _category : null,
          targetType: _tab == 0 ? _target : null,
          scope: _tab == 0
              ? 'discover'
              : _history
              ? 'history'
              : 'active',
          offset: _offset,
        );
        if (!mounted || generation != _generation) return;
        setState(() {
          _offset += page.length;
          _missions = [..._missions, ...page];
          _more = page.length == 30;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = error is AppFailure
              ? error.message
              : 'No pudimos cargar las misiones. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _withdraw(MissionApplication application) async {
    final repo = widget.controller.communityRepository;
    if (_withdrawing || repo == null) return;
    setState(() => _withdrawing = true);
    final ok = await runCommunityAction(
      context,
      () => repo.withdraw(application.id),
      success: 'Postulación retirada.',
    );
    if (!mounted) return;
    setState(() => _withdrawing = false);
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _missions;
    final viewer = widget.controller.profile;
    final applications = _applications
        .where(
          (a) => _applicationFilter == null || a.status == _applicationFilter,
        )
        .toList();
    return CommunityPage(
      title: 'Misiones',
      onRefresh: () => _load(),
      action: FilledButton.icon(
        onPressed: () async {
          final id = await context.push<String>('/missions/new');
          if (!mounted) return;
          await _load();
          if (!context.mounted || id == null) return;
          await context.push('/missions/$id');
          if (mounted) await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear misión'),
      ),
      children: [
        MareaTabs(
          options: const {
            '0': 'Explorar',
            '1': 'Mis misiones',
            '2': 'Mis postulaciones',
          },
          value: '$_tab',
          onChanged: (value) {
            final tab = int.parse(value);
            if (_tab == tab) return;
            setState(() => _tab = tab);
            _load();
          },
        ),
        const SizedBox(height: 20),
        if (_tab == 0) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _target == null,
                onSelected: (_) {
                  setState(() => _target = null);
                  _load();
                },
              ),
              if (viewer != null)
                ChoiceChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Para mi perfil'),
                  selected: _target == viewer.userType,
                  onSelected: (_) {
                    setState(() => _target = viewer.userType);
                    _load();
                  },
                ),
            ],
          ),
          if (_target == viewer?.userType && viewer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Para ${viewer.userType.databaseValue} y convocatorias para todos.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Buscar misiones',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _query = value;
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 350),
                () => _load(),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    for (final e in communityCategories.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    setState(() => _category = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<UserType?>(
                  key: ValueKey(_target),
                  initialValue: _target,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Perfil buscado',
                  ),
                  items: [
                    const DropdownMenuItem<UserType?>(
                      value: null,
                      child: Text('Cualquier perfil'),
                    ),
                    for (final t in UserType.values)
                      DropdownMenuItem(value: t, child: Text(t.databaseValue)),
                  ],
                  onChanged: (v) {
                    setState(() => _target = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (_tab == 1) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final h in [false, true])
                ChoiceChip(
                  label: Text(h ? 'Historial' : 'Convocatorias activas'),
                  selected: _history == h,
                  onSelected: (_) {
                    setState(() => _history = h);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (_error != null)
          CommunityNotice(message: _error!, onRetry: () => _load()),
        if (_tab == 2) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in const <String?, String>{
                null: 'Todas',
                'pending': 'Pendientes',
                'accepted': 'Aceptadas',
                'rejected': 'No seleccionadas',
                'withdrawn': 'Retiradas',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _applicationFilter == entry.key,
                  onSelected: (_) =>
                      setState(() => _applicationFilter = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_tab == 2)
          for (final application in applications)
            MareaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text(
                      _appliedMissions[application.missionId]?.title ??
                          'Misión no disponible',
                    ),
                    subtitle: Text(
                      'Postulación ${_applicationStatus(application.status).toLowerCase()} · ${_appliedMissions[application.missionId]?.statusLabel ?? 'Misión no disponible'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context
                        .push('/missions/${application.missionId}')
                        .then((_) {
                          if (mounted) _load();
                        }),
                  ),
                  if ((application.status == 'pending' ||
                          application.status == 'accepted') &&
                      _appliedMissions[application.missionId] != null &&
                      !_appliedMissions[application.missionId]!.isTerminal &&
                      !_appliedMissions[application.missionId]!.isExpired)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _withdrawing
                              ? null
                              : () => _withdraw(application),
                          icon: const Icon(Icons.close),
                          label: const Text('Retirar postulación'),
                        ),
                      ),
                    ),
                ],
              ),
            )
        else
          for (final mission in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MissionSummary(
                mission: mission,
                viewerType: viewer?.userType,
                viewerId: viewer?.id,
                repository: widget.controller.communityRepository,
                owner: _tab == 1,
                onTap: () async {
                  await context.push('/missions/${mission.id}');
                  if (mounted) _load();
                },
              ),
            ),
        if (!_loading &&
            _error == null &&
            (_tab == 2 ? applications.isEmpty : visible.isEmpty))
          CommunityNotice(
            message: switch (_tab) {
              1 =>
                'Aún no has creado misiones. Invita a la comunidad a colaborar.',
              2 =>
                _applicationFilter == null
                    ? 'Tus postulaciones y sus respuestas aparecerán aquí.'
                    : 'No tienes postulaciones en este estado.',
              _ =>
                'No hay misiones abiertas en esta página. Vuelve pronto o crea la primera.',
            },
            icon: Icons.explore_outlined,
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_more && !_loading)
          TextButton(
            onPressed: () => _load(append: true),
            child: const Text('Cargar más misiones'),
          ),
      ],
    );
  }
}

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({
    super.key,
    required this.controller,
    required this.missionId,
  });
  final AppSessionController controller;
  final String missionId;
  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  bool _loading = true, _busy = false;
  int _generation = 0;
  String? _error;
  Mission? _mission;
  List<MissionApplication> _applications = [];
  Map<String, CommunityProfile> _profiles = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MissionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missionId != widget.missionId ||
        oldWidget.controller != widget.controller) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final missionId = widget.missionId;
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = 'Las misiones aún no están disponibles.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mission = await repo.mission(missionId);
      final applications = mission == null
          ? <MissionApplication>[]
          : await repo.applications(missionId: missionId);
      final profiles = mission == null
          ? <CommunityProfile>[]
          : await repo.profiles(
              ids: {
                mission.authorId,
                ...applications.map((a) => a.applicantId),
              }.toList(),
            );
      if (!mounted || generation != _generation) return;
      setState(() {
        _mission = mission;
        _applications = applications;
        _profiles = {for (final profile in profiles) profile.id: profile};
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = error is AppFailure
              ? error.message
              : 'No pudimos cargar esta misión.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _action(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await runCommunityAction(context, action, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) await _load();
  }

  Future<void> _apply() async {
    final message = await askCommunityText(
      context,
      title: 'Postularme a la misión',
      label: 'Cuéntanos cómo te gustaría colaborar',
      maxLength: 1000,
    );
    if (!mounted || message == null) return;
    await _action(() async {
      await widget.controller.communityRepository!.apply(
        widget.missionId,
        message,
      );
    }, 'Tu postulación fue enviada.');
  }

  Future<void> _report() async {
    final reason = await askCommunityText(
      context,
      title: 'Reportar misión',
      label: 'Motivo del reporte',
      maxLength: 500,
    );
    if (!mounted || !context.mounted || reason == null) return;
    await _action(() async {
      await widget.controller.communityRepository!.report(
        missionId: widget.missionId,
        reason: reason,
      );
    }, 'Recibimos tu reporte.');
  }

  @override
  Widget build(BuildContext context) {
    final mission = _mission;
    final viewer = widget.controller.profile;
    final owner = mission?.authorId == viewer?.id;
    final own = _applications
        .where((a) => a.applicantId == viewer?.id)
        .firstOrNull;
    final accepted = mission?.acceptedCount ?? 0;
    final restriction = mission == null || viewer == null
        ? 'Inicia sesión para postularte.'
        : mission.applicationRestriction(
            viewerId: viewer.id,
            viewerType: viewer.userType,
          );
    final eligible = restriction == null;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Misión'),
        leading: IconButton(
          tooltip: 'Volver a misiones',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _backToMissions(context),
        ),
      ),
      body: CommunityPage(
        title: 'Misión',
        onRefresh: _load,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _backToMissions(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Misiones'),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            CommunityNotice(message: _error!, onRetry: _load)
          else if (mission == null)
            const CommunityNotice(message: 'Esta misión ya no está disponible.')
          else ...[
            if (mission.imagePath != null) ...[
              MissionCover(
                path: mission.imagePath,
                repository: widget.controller.communityRepository,
                height: 280,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              mission.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(
                    ProfilePreferences.interests[mission.category] ?? 'Otros',
                  ),
                ),
                Chip(label: Text(mission.statusLabel)),
                Chip(
                  label: Text(
                    mission.targetType?.databaseValue ?? 'Todos los perfiles',
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/people/${mission.authorId}'),
              icon: const Icon(Icons.person_outline),
              label: Text(
                _profiles[mission.authorId]?.fullName ?? 'Ver organizador',
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(mission.body),
            const SizedBox(height: 20),
            Text('Dónde: ${mission.location}'),
            if (mission.coordinates != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showPostLocationViewer(
                    context,
                    label: mission.location,
                    coordinates: mission.coordinates!,
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver ubicación'),
                ),
              ),
            if (mission.requirements != null) ...[
              const SizedBox(height: 16),
              Text(
                'Requisitos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectableText(mission.requirements!),
            ],
            if (mission.conditions != null) ...[
              const SizedBox(height: 16),
              Text(
                'Qué ofrecemos y condiciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectableText(mission.conditions!),
            ],
            if (mission.cancellationReason != null)
              CommunityNotice(
                message: 'Motivo de cancelación: ${mission.cancellationReason}',
              ),
            const SizedBox(height: 8),
            Text('Cuándo: ${_date(mission.startsAt)}'),
            const SizedBox(height: 8),
            Text(
              owner
                  ? '$accepted de ${mission.capacity} lugares confirmados'
                  : '${mission.availableSeats} de ${mission.capacity} lugares disponibles',
            ),
            const SizedBox(height: 24),
            if (owner) ...[
              if (!mission.isTerminal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    mission.conditionsLocked
                        ? 'Organizas esta misión. Ya recibió postulaciones: fecha, lugar y perfil solicitado quedan fijos; puedes mejorar el texto y aumentar el cupo.'
                        : 'Organizas esta misión. Puedes editarla y seleccionar participantes. La fecha, el lugar y el perfil solicitado quedan fijos desde la primera postulación.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (!mission.isTerminal)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy || mission.hidden
                          ? null
                          : () async {
                              await context.push(
                                '/missions/${mission.id}/edit',
                              );
                              if (mounted) _load();
                            },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar misión'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _busy ||
                              mission.hidden ||
                              (!mission.startsAt.isAfter(DateTime.now()) &&
                                  mission.status != 'open')
                          ? null
                          : () => _action(
                              () async {
                                await widget.controller.communityRepository!
                                    .setMissionStatus(
                                      mission.id,
                                      mission.status == 'open'
                                          ? 'closed'
                                          : 'open',
                                    );
                              },
                              mission.status == 'open'
                                  ? 'Misión cerrada.'
                                  : 'Misión abierta.',
                            ),
                      icon: Icon(
                        mission.status == 'open'
                            ? Icons.lock_outline
                            : Icons.lock_open,
                      ),
                      label: Text(
                        mission.status == 'open'
                            ? 'Cerrar misión'
                            : 'Reabrir misión',
                      ),
                    ),
                  ],
                ),
              if (!mission.isTerminal)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              final reason = await askCommunityText(
                                context,
                                title: 'Cancelar misión',
                                label:
                                    'Motivo de cancelación (visible para la comunidad)',
                                maxLength: 500,
                              );
                              if (!mounted ||
                                  !context.mounted ||
                                  reason == null) {
                                return;
                              }
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text(
                                    '¿Cancelar definitivamente?',
                                  ),
                                  content: const Text(
                                    'La misión permanecerá en el historial y no podrá reabrirse.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Volver'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Cancelar misión'),
                                    ),
                                  ],
                                ),
                              );
                              if (!mounted || confirm != true) return;
                              _action(
                                () => widget.controller.communityRepository!
                                    .setMissionStatus(
                                      mission.id,
                                      'cancelled',
                                      reason: reason,
                                    ),
                                'Misión cancelada.',
                              );
                            },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar misión'),
                    ),
                    if (mission.isExpired)
                      FilledButton.icon(
                        onPressed: _busy || mission.hidden
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('¿Finalizar misión?'),
                                    content: const Text(
                                      'Se guardará en el historial y ya no se podrá modificar.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Volver'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Finalizar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (mounted && confirm == true) {
                                  _action(
                                    () => widget.controller.communityRepository!
                                        .setMissionStatus(
                                          mission.id,
                                          'completed',
                                        ),
                                    'Misión finalizada.',
                                  );
                                }
                              },
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Finalizar misión'),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'Postulaciones (${_applications.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_applications.isEmpty)
                const CommunityNotice(
                  message:
                      'Las personas interesadas en colaborar aparecerán aquí.',
                ),
              for (final application in _applications)
                MareaCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () => context.push(
                            '/people/${application.applicantId}',
                          ),
                          child: Text(
                            _profiles[application.applicantId]?.fullName ??
                                'Ver perfil',
                          ),
                        ),
                        Text(application.message),
                        const SizedBox(height: 8),
                        Text(_applicationStatus(application.status)),
                        if (application.status == 'pending' &&
                            !mission.isTerminal &&
                            !mission.hidden &&
                            mission.startsAt.isAfter(DateTime.now()))
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: _busy || mission.isFull
                                    ? null
                                    : () => _action(() async {
                                        await widget
                                            .controller
                                            .communityRepository!
                                            .review(application.id, 'accepted');
                                      }, 'Postulación aceptada.'),
                                child: const Text('Aceptar'),
                              ),
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _action(() async {
                                        await widget
                                            .controller
                                            .communityRepository!
                                            .review(application.id, 'rejected');
                                      }, 'Postulación revisada.'),
                                child: const Text('No seleccionar'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              if (own != null) ...[
                CommunityNotice(
                  message:
                      'Tu postulación: ${_applicationStatus(own.status).toLowerCase()}.',
                  icon: Icons.task_alt,
                ),
                if ((own.status == 'pending' || own.status == 'accepted') &&
                    !mission.isTerminal &&
                    !mission.isExpired)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _action(() async {
                            await widget.controller.communityRepository!
                                .withdraw(own.id);
                          }, 'Postulación retirada.'),
                    child: const Text('Retirar postulación'),
                  ),
              ],
              if (eligible && (own == null || own.status == 'withdrawn'))
                FilledButton.icon(
                  onPressed: _busy ? null : _apply,
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Postularme'),
                )
              else if (own == null || own.status == 'withdrawn')
                CommunityNotice(message: restriction!),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _busy ? null : _report,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Reportar misión'),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
