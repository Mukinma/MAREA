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
import 'package:marea/shared/widgets/profile_image.dart';

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
  bool _history = false, _draftView = false, _savedOnly = false;
  final _scroll = ScrollController();
  List<MissionDraft> _drafts = [];
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
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
      }
    });
    try {
      if (_tab == 1 && _draftView) {
        final drafts = await repo.missionDrafts();
        if (!mounted || generation != _generation) return;
        setState(() {
          _drafts = drafts;
          _more = false;
        });
      } else if (_tab == 2) {
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
        final page = _tab == 0 && _savedOnly
            ? await repo.savedMissions(
                query: _query,
                category: _category,
                targetType: _target,
                offset: _offset,
              )
            : await repo.missions(
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
          _missions = append ? [..._missions, ...page] : page;
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

  Future<void> _filters() async {
    var target = _target;
    final result = await showModalBottomSheet<Map<String, UserType?>>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (c, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtrar misiones',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<UserType?>(
                  initialValue: target,
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
                  onChanged: (v) => setSheet(() => target = v),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(c, {'target': target}),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _target = result['target']);
    await _load();
  }

  Future<void> _deleteDraft(MissionDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar borrador?'),
        content: Text(draft.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar borrador'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final ok = await runCommunityAction(
      context,
      () => widget.controller.communityRepository!.deleteMissionDraft(draft.id),
      success: 'Borrador eliminado.',
    );
    if (mounted && ok) await _load();
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
    return Theme(
      data: Theme.of(context).copyWith(
        chipTheme: Theme.of(context).chipTheme.copyWith(
          labelStyle: const TextStyle(
            fontFamily: 'NunitoSans',
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: ColoredBox(
        color: AppColors.canvas,
        child: CommunityPage(
          scrollController: _scroll,
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
                '2': 'Mis candidaturas',
              },
              value: '$_tab',
              onChanged: (value) {
                final tab = int.parse(value);
                if (_tab == tab) return;
                setState(() {
                  _tab = tab;
                  _missions = [];
                  _applications = [];
                  _drafts = [];
                });
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  avatar: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text('Guardadas'),
                  selected: _savedOnly,
                  onSelected: (v) {
                    setState(() => _savedOnly = v);
                    _load();
                  },
                ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
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
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Más filtros',
                    onPressed: _filters,
                    icon: const Icon(Icons.tune),
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
                      selected: !_draftView && _history == h,
                      onSelected: (_) {
                        setState(() {
                          _history = h;
                          _draftView = false;
                        });
                        _load();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ChoiceChip(
                  label: const Text('Borradores'),
                  selected: _draftView,
                  onSelected: (_) {
                    setState(() => _draftView = true);
                    _load();
                  },
                ),
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
                          !_appliedMissions[application.missionId]!
                              .isTerminal &&
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
            else if (_tab == 1 && _draftView)
              for (final draft in _drafts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MissionSurface(
                    padding: 16,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.edit_note,
                        color: AppColors.aquaDark,
                      ),
                      title: Text(draft.title),
                      subtitle: Text(
                        'Borrador · ${missionDate(draft.updatedAt)}',
                      ),
                      onTap: () async {
                        await context.push('/missions/drafts/${draft.id}/edit');
                        if (mounted) _load();
                      },
                      trailing: IconButton(
                        tooltip: 'Eliminar borrador',
                        onPressed: () => _deleteDraft(draft),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
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
                      await context.push(
                        '/missions/${mission.id}${_tab == 1 ? '/manage' : ''}',
                      );
                      if (mounted) _load();
                    },
                  ),
                ),
            if (!_loading &&
                _error == null &&
                (_tab == 2
                    ? applications.isEmpty
                    : _tab == 1 && _draftView
                    ? _drafts.isEmpty
                    : visible.isEmpty))
              CommunityNotice(
                message: switch (_tab) {
                  1 =>
                    _draftView
                        ? 'Tus ideas guardadas aparecerán aquí.'
                        : 'Aún no has creado misiones. Invita a la comunidad a colaborar.',
                  2 =>
                    _applicationFilter == null
                        ? 'Tus postulaciones y sus respuestas aparecerán aquí.'
                        : 'No tienes postulaciones en este estado.',
                  _ =>
                    _savedOnly
                        ? 'Aún no has guardado misiones.'
                        : 'No hay misiones abiertas en esta página. Vuelve pronto o crea la primera.',
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
        ),
      ),
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
  bool _loading = true, _busy = false, _saved = false;
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
      final applications =
          mission == null || mission.authorId == widget.controller.profile?.id
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
      final saved = await repo.savedMissionIds();
      if (!mounted || generation != _generation) return;
      setState(() {
        _saved = saved.contains(missionId);
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
    await context.push('/missions/${widget.missionId}/apply');
    if (mounted) await _load();
  }

  Future<void> _toggleSaved() async {
    if (_busy) return;
    final next = !_saved;
    await _action(
      () => widget.controller.communityRepository!.setMissionSaved(
        widget.missionId,
        next,
      ),
      next ? 'Misión guardada.' : 'Misión retirada de guardadas.',
    );
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
    final restriction = mission == null || viewer == null
        ? 'Inicia sesión para postularte.'
        : mission.applicationRestriction(
            viewerId: viewer.id,
            viewerType: viewer.userType,
          );
    final canApply =
        restriction == null && (own == null || own.status == 'withdrawn');
    final organizer = mission == null ? null : _profiles[mission.authorId];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Misión'),
        leading: IconButton(
          tooltip: 'Volver a misiones',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _backToMissions(context),
        ),
        actions: [
          if (mission != null)
            IconButton(
              tooltip: _saved ? 'Quitar de guardadas' : 'Guardar misión',
              onPressed: _busy ? null : _toggleSaved,
              icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
            ),
          if (mission != null && !owner)
            IconButton(
              tooltip: 'Reportar misión',
              onPressed: _busy ? null : _report,
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
      body: _loading && mission == null
          ? const Center(child: CircularProgressIndicator())
          : mission == null
          ? Center(
              child: CommunityNotice(
                message: _error ?? 'Esta misión ya no está disponible.',
                onRetry: _error == null ? null : _load,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null)
                            CommunityNotice(message: _error!, onRetry: _load),
                          if (mission.imagePath != null) ...[
                            MissionCover(
                              path: mission.imagePath,
                              repository: widget.controller.communityRepository,
                              height: MediaQuery.sizeOf(context).width < 600
                                  ? 260
                                  : 360,
                            ),
                            const SizedBox(height: 20),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _badge(
                                communityCategories[mission.category] ??
                                    'Otros',
                                AppColors.mint,
                              ),
                              _badge(mission.statusLabel, AppColors.mist),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            mission.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 18,
                                color: AppColors.aquaDark,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  mission.location,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          MissionSurface(
                            padding: 12,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipOval(
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: ProfileImage(
                                    path: organizer?.avatarPath,
                                    repository:
                                        widget.controller.mediaRepository,
                                    fallback: Container(
                                      color: AppColors.mint,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: AppColors.brandNavy,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                organizer?.fullName ??
                                    mission.organizerName ??
                                    'Ver organizador',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                organizer == null
                                    ? 'Organizador'
                                    : '@${organizer.username} · ${organizer.userType.databaseValue}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/people/${mission.authorId}'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          MissionSurface(
                            padding: 16,
                            child: Column(
                              children: [
                                _fact(
                                  Icons.event_outlined,
                                  'Fecha y hora',
                                  missionDate(mission.startsAt),
                                ),
                                const Divider(height: 24),
                                _fact(
                                  Icons.payments_outlined,
                                  'Compensación',
                                  mission.compensationLabel,
                                ),
                                const Divider(height: 24),
                                _fact(
                                  Icons.people_outline,
                                  'Participantes',
                                  '${mission.availableSeats} de ${mission.capacity} lugares disponibles',
                                ),
                                const Divider(height: 24),
                                _fact(
                                  Icons.account_circle_outlined,
                                  'Perfil solicitado',
                                  mission.targetType?.databaseValue ??
                                      'Todos los perfiles',
                                ),
                              ],
                            ),
                          ),
                          _section(context, 'La misión', mission.body),
                          if (mission.requirements != null)
                            _section(
                              context,
                              'Lo que necesitas',
                              mission.requirements!,
                            ),
                          if (mission.conditions != null)
                            _section(
                              context,
                              'Qué ofrecemos y condiciones',
                              mission.conditions!,
                            ),
                          if (mission.coordinates != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: OutlinedButton.icon(
                                onPressed: () => showPostLocationViewer(
                                  context,
                                  label: mission.location,
                                  coordinates: mission.coordinates!,
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Ver ubicación'),
                              ),
                            ),
                          if (mission.cancellationReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: CommunityNotice(
                                message:
                                    'Motivo de cancelación: ${mission.cancellationReason}',
                              ),
                            ),
                          if (!owner && own != null) ...[
                            const SizedBox(height: 24),
                            MissionSurface(
                              padding: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu postulación: ${_applicationStatus(own.status).toLowerCase()}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(own.message),
                                  if (own.availabilityConfirmed == true)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Disponibilidad confirmada'),
                                    ),
                                  if ((own.status == 'pending' ||
                                          own.status == 'accepted') &&
                                      !mission.isTerminal &&
                                      !mission.isExpired)
                                    TextButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _action(
                                              () => widget
                                                  .controller
                                                  .communityRepository!
                                                  .withdraw(own.id),
                                              'Postulación retirada.',
                                            ),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Retirar postulación'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (!owner &&
                              !canApply &&
                              (own == null || own.status == 'withdrawn') &&
                              restriction != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: CommunityNotice(message: restriction),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: mission == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _busy
                            ? null
                            : owner
                            ? () async {
                                await context.push(
                                  '/missions/${mission.id}/manage',
                                );
                                if (mounted) _load();
                              }
                            : canApply
                            ? _apply
                            : null,
                        icon: Icon(
                          owner
                              ? Icons.dashboard_outlined
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          owner
                              ? 'Gestionar misión'
                              : canApply
                              ? 'Quiero participar'
                              : own != null && own.status != 'withdrawn'
                              ? 'Candidatura ${_applicationStatus(own.status).toLowerCase()}'
                              : 'Participación no disponible',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 12,
        color: AppColors.brandNavy,
      ),
    ),
  );
  Widget _fact(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.actionBlue),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SelectableText(body),
      ],
    ),
  );
}
