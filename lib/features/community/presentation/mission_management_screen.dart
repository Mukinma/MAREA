import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_application_screen.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/shared/widgets/profile_image.dart';

class MissionManagementScreen extends StatefulWidget {
  const MissionManagementScreen({
    super.key,
    required this.controller,
    required this.missionId,
  });
  final AppSessionController controller;
  final String missionId;
  @override
  State<MissionManagementScreen> createState() =>
      _MissionManagementScreenState();
}

class _MissionManagementScreenState extends State<MissionManagementScreen> {
  Mission? _mission;
  List<MissionApplication> _applications = [];
  Map<String, CommunityProfile> _profiles = {};
  Set<String> _finalists = {}, _selection = {};
  String _filter = 'pending';
  bool _loading = true, _busy = false;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MissionManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missionId != widget.missionId ||
        oldWidget.controller != widget.controller) {
      _mission = null;
      _applications = [];
      _profiles = {};
      _finalists = {};
      _selection = {};
      _filter = 'pending';
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final repo = widget.controller.communityRepository,
        viewer = widget.controller.profile;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (repo == null || viewer == null) {
        setState(() => _error = 'Inicia sesión para gestionar tus misiones.');
        return;
      }
      final mission = await repo.mission(widget.missionId);
      if (!mounted || generation != _generation) return;
      if (mission == null || mission.authorId != viewer.id) {
        setState(() {
          _mission = null;
          _applications = [];
          _error = mission == null
              ? 'Esta misión ya no está disponible.'
              : 'Solo el organizador puede gestionar esta misión.';
        });
        return;
      }
      final applications = (await repo.applications(
        missionId: mission.id,
      )).where((a) => a.missionId == mission.id).toList();
      final finalists = await repo.missionFinalists(mission.id);
      final profiles = applications.isEmpty
          ? <CommunityProfile>[]
          : await repo.profiles(
              ids: applications.map((a) => a.applicantId).toSet().toList(),
            );
      if (!mounted || generation != _generation) return;
      setState(() {
        _mission = mission;
        _applications = applications;
        _finalists = finalists;
        _profiles = {for (final p in profiles) p.id: p};
        _selection = _selection.intersection(
          applications
              .where((a) => a.status == 'pending')
              .map((a) => a.id)
              .toSet(),
        );
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(error));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _action(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  bool get _canReview =>
      _mission != null &&
      !_mission!.isTerminal &&
      !_mission!.hidden &&
      !_mission!.isExpired;
  String _name(MissionApplication a) =>
      _profiles[a.applicantId]?.fullName ?? 'Participante';
  Future<void> _confirmSelection() async {
    final mission = _mission;
    if (_busy || !_canReview || mission == null || _selection.isEmpty) return;
    final selected = _applications
        .where((a) => _selection.contains(a.id) && a.status == 'pending')
        .toList();
    if (selected.length > mission.availableSeats) {
      setState(
        () => _error =
            'Solo quedan ${mission.availableSeats} lugares disponibles. Ajusta tu selección.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Revisar selección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmarás ${selected.length} participantes para «${mission.title}».',
              ),
              const SizedBox(height: 16),
              for (final a in selected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• ${_name(a)}'),
                ),
              const SizedBox(height: 12),
              const Text(
                'La convocatoria conservará su estado. Las otras candidaturas seguirán pendientes.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar participantes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _action(() async {
      await widget.controller.communityRepository!.confirmMissionSelection(
        mission.id,
        selected.map((a) => a.id).toList(),
      );
      if (mounted) setState(() => _selection.clear());
    }, 'Participantes confirmados.');
  }

  Future<void> _changeStatus(String status) async {
    final mission = _mission;
    if (mission == null || _busy) return;
    String? reason;
    if (status == 'cancelled') {
      reason = await askCommunityText(
        context,
        title: 'Cancelar misión',
        label: 'Motivo de cancelación (visible para la comunidad)',
        maxLength: 500,
      );
      if (!mounted || reason == null) return;
    }
    final title = switch (status) {
      'closed' => '¿Cerrar convocatoria?',
      'open' => '¿Reabrir convocatoria?',
      'cancelled' => '¿Cancelar definitivamente?',
      _ => '¿Finalizar misión?',
    };
    final description = switch (status) {
      'closed' =>
        'No llegarán nuevas candidaturas. Podrás revisar las recibidas y reabrir antes de la fecha de inicio.',
      'open' => 'La comunidad podrá volver a presentar candidaturas.',
      'cancelled' => 'La misión quedará en el historial y no podrá reabrirse.',
      _ => 'La misión quedará en el historial y ya no se podrá modificar.',
    };
    if (!await _confirm(title, description, 'Confirmar') || !mounted) return;
    await _action(
      () => widget.controller.communityRepository!.setMissionStatus(
        mission.id,
        status,
        reason: reason,
      ),
      'Misión actualizada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = _mission;
    final visible = _applications
        .where(
          (a) =>
              _filter == 'all' ||
              (_filter == 'finalists'
                  ? _finalists.contains(a.id) && a.status == 'pending'
                  : a.status == _filter),
        )
        .toList();
    int count(String status) =>
        _applications.where((a) => a.status == status).length;
    return MissionFlowScaffold(
      title: 'Candidaturas',
      actions: mission == null || mission.isTerminal || mission.hidden
          ? []
          : [
              PopupMenuButton<String>(
                tooltip: 'Opciones de misión',
                onSelected: (value) async {
                  if (value == 'edit') {
                    await context.push('/missions/${mission.id}/edit');
                    if (mounted) _load();
                  } else {
                    await _changeStatus(value);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar misión'),
                  ),
                  if (mission.status == 'open')
                    const PopupMenuItem(
                      value: 'closed',
                      child: Text('Cerrar convocatoria'),
                    )
                  else if (!mission.isExpired)
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Reabrir convocatoria'),
                    ),
                  if (mission.isExpired)
                    const PopupMenuItem(
                      value: 'completed',
                      child: Text('Finalizar misión'),
                    ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelar misión'),
                  ),
                ],
              ),
            ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null) ...[
                    CommunityNotice(message: _error!, onRetry: _load),
                    const SizedBox(height: 16),
                  ],
                  if (mission != null) ...[
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandNavy,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            mission.isTerminal ? Icons.history : Icons.circle,
                            color: AppColors.success,
                            size: 12,
                          ),
                          label: Text(mission.statusLabel),
                        ),
                        Text('Inicio · ${missionDate(mission.startsAt)}'),
                      ],
                    ),
                    if (mission.hidden)
                      const MissionHint(
                        icon: Icons.visibility_off_outlined,
                        text:
                            'Esta misión fue ocultada. Sus acciones de gestión están suspendidas.',
                      ),
                    if (mission.cancellationReason != null)
                      MissionHint(
                        icon: Icons.info_outline,
                        text:
                            'Motivo de cancelación: ${mission.cancellationReason}',
                      ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Metric(
                            number: '${_applications.length}',
                            label: 'Candidaturas',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            number: '${count('accepted')}',
                            label: 'Confirmadas',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            number:
                                '${mission.availableSeats}/${mission.capacity}',
                            label: 'Disponibles',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final filter in const {
                          'pending': 'Pendientes',
                          'finalists': 'Finalistas',
                          'accepted': 'Aceptadas',
                          'rejected': 'No seleccionadas',
                          'withdrawn': 'Retiradas',
                          'all': 'Todas',
                        }.entries)
                          ChoiceChip(
                            label: Text(
                              '${filter.value} ${filter.key == 'all'
                                  ? _applications.length
                                  : filter.key == 'finalists'
                                  ? _applications.where((a) => a.status == 'pending' && _finalists.contains(a.id)).length
                                  : count(filter.key)}',
                            ),
                            selected: _filter == filter.key,
                            onSelected: (_) =>
                                setState(() => _filter = filter.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (visible.isEmpty)
                      const CommunityNotice(
                        message: 'No hay candidaturas en este grupo.',
                        icon: Icons.inbox_outlined,
                      ),
                    for (final a in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _card(a, mission),
                      ),
                    if (_selection.isNotEmpty && !_canReview)
                      const MissionHint(
                        icon: Icons.info_outline,
                        text:
                            'Esta misión ya no permite confirmar participantes.',
                      ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
      footer: !_canReview || mission == null
          ? null
          : FilledButton.icon(
              onPressed: _busy || _selection.isEmpty ? null : _confirmSelection,
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text('Confirmar selección (${_selection.length})'),
            ),
    );
  }

  Widget _card(MissionApplication application, Mission mission) {
    final profile = _profiles[application.applicantId];
    final selected = _selection.contains(application.id),
        finalist = _finalists.contains(application.id);
    final pending = application.status == 'pending';
    final status = switch (application.status) {
      'accepted' => 'Aceptada',
      'rejected' => 'No seleccionada',
      'withdrawn' => 'Retirada',
      _ => finalist ? 'Finalista' : 'Pendiente',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.mint : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? AppColors.success
              : finalist
              ? AppColors.actionBlue
              : AppColors.border,
          width: selected || finalist ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.push('/people/${application.applicantId}'),
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipOval(
                    child: ProfileImage(
                      path: profile?.avatarPath,
                      repository: widget.controller.mediaRepository,
                      fallback: CircleAvatar(
                        backgroundColor: AppColors.mist,
                        child: Text(
                          profile?.initials ?? 'M',
                          style: const TextStyle(color: AppColors.brandNavy),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      context.push('/people/${application.applicantId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name(application),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      if (profile != null)
                        Text(
                          profile.userType.databaseValue,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (pending && _canReview)
                Checkbox(
                  value: selected,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          v == true
                              ? _selection.add(application.id)
                              : _selection.remove(application.id);
                        }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(label: Text(status), visualDensity: VisualDensity.compact),
              if (application.availabilityConfirmed == true)
                const Chip(
                  avatar: Icon(Icons.event_available, size: 16),
                  label: Text('Disponible'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(application.message),
          if (application.availabilityConfirmed != true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                application.availabilityConfirmed == null
                    ? 'Esta candidatura anterior no registró disponibilidad.'
                    : 'Disponibilidad sin confirmar.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (application.evidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Muestras de trabajo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            for (final sample in application.evidence)
              MissionEvidenceTile(
                controller: widget.controller,
                evidence: sample,
                applicantId: application.applicantId,
              ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/people/${application.applicantId}'),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Ver perfil'),
              ),
              if (pending && _canReview) ...[
                IconButton.filledTonal(
                  tooltip: finalist ? 'Quitar finalista' : 'Marcar finalista',
                  onPressed: _busy
                      ? null
                      : () => _action(
                          () => widget.controller.communityRepository!
                              .setMissionFinalist(
                                mission.id,
                                application.id,
                                !finalist,
                              ),
                          finalist
                              ? 'Finalista retirado.'
                              : 'Candidatura marcada como finalista.',
                        ),
                  icon: Icon(
                    finalist ? Icons.star_rounded : Icons.star_outline_rounded,
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (!await _confirm(
                                '¿No seleccionar esta candidatura?',
                                'El participante recibirá la respuesta.',
                                'No seleccionar',
                              ) ||
                              !mounted) {
                            return;
                          }
                          await _action(
                            () => widget.controller.communityRepository!.review(
                              application.id,
                              'rejected',
                            ),
                            'Candidatura revisada.',
                          );
                        },
                  child: const Text('No seleccionar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.number, required this.label});
  final String number, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
