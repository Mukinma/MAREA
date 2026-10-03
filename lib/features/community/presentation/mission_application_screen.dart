import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Shared framing keeps the actions above the keyboard and limits reading width.
class MissionFlowScaffold extends StatelessWidget {
  const MissionFlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.onBack,
    this.actions = const [],
  });
  final String title;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onBack;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        chipTheme: theme.chipTheme.copyWith(
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'NunitoSans',
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.actionBlue, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: theme.filledButtonTheme.style?.copyWith(
            shape: const WidgetStatePropertyAll(StadiumBorder()),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.copyWith(
            shape: const WidgetStatePropertyAll(StadiumBorder()),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            tooltip: 'Volver a misiones',
            onPressed:
                onBack ??
                () =>
                    context.canPop() ? context.pop() : context.go('/missions'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: actions,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: body,
            ),
          ),
        ),
        bottomNavigationBar: footer == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    12 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: footer!,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class MissionApplicationScreen extends StatefulWidget {
  const MissionApplicationScreen({
    super.key,
    required this.controller,
    required this.missionId,
  });
  final AppSessionController controller;
  final String missionId;
  @override
  State<MissionApplicationScreen> createState() =>
      _MissionApplicationScreenState();
}

class _MissionApplicationScreenState extends State<MissionApplicationScreen> {
  final _message = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _operationId = const Uuid().v4();
  final _samples = <MissionEvidence>[];
  Mission? _mission;
  MissionApplication? _own;
  List<ShowcaseItem> _works = [];
  int _step = 0, _generation = 0, _workOffset = 0;
  bool _workMore = false, _workBusy = false;
  bool _loading = true,
      _busy = false,
      _available = false,
      _validation = false,
      _allowExit = false;
  String? _error, _workError;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MissionApplicationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missionId != widget.missionId ||
        oldWidget.controller != widget.controller) {
      _message.clear();
      _samples.clear();
      _works = [];
      _workOffset = 0;
      _workMore = false;
      _workBusy = false;
      _mission = null;
      _own = null;
      _operationId = const Uuid().v4();
      _available = false;
      _step = 0;
      _validation = false;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final repo = widget.controller.communityRepository;
    final viewer = widget.controller.profile;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (repo == null || viewer == null) {
        throw StateError('Inicia sesión para participar.');
      }
      final mission = await repo.mission(widget.missionId);
      final applications = mission == null
          ? <MissionApplication>[]
          : await repo.applications(missionId: widget.missionId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _mission = mission;
        _own = applications
            .where(
              (a) =>
                  a.missionId == widget.missionId &&
                  a.applicantId == viewer.id &&
                  a.status != 'withdrawn',
            )
            .firstOrNull;
      });
      await _loadWorks();
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

  Future<void> _loadWorks({bool append = false}) async {
    final showcase = widget.controller.showcaseRepository;
    final viewer = widget.controller.profile;
    final generation = _generation;
    if (showcase == null || viewer == null || _workBusy) return;
    setState(() {
      _workBusy = true;
      _workError = null;
    });
    try {
      final page = await showcase.items(
        ownerId: viewer.id,
        offset: append ? _workOffset : 0,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        final valid = page
            .where(
              (w) =>
                  w.ownerId == viewer.id &&
                  w.status == ShowcaseStatus.published &&
                  w.available &&
                  !w.hidden,
            )
            .toList();
        _works = append ? [..._works, ...valid] : valid;
        _workOffset = (append ? _workOffset : 0) + page.length;
        _workMore = page.length == 30;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _workError =
              'No pudimos cargar tus fichas. Puedes adjuntar un enlace o reintentar.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _workBusy = false);
      }
    }
  }

  String? get _restriction {
    final viewer = widget.controller.profile, mission = _mission;
    if (viewer == null) return 'Inicia sesión para participar.';
    if (mission == null) return 'Esta misión ya no está disponible.';
    return mission.applicationRestriction(
      viewerId: viewer.id,
      viewerType: viewer.userType,
    );
  }

  Future<void> _leave() async {
    if (_busy) return;
    final dirty =
        _message.text.trim().isNotEmpty || _samples.isNotEmpty || _available;
    if (dirty) {
      final exit = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Salir de tu candidatura?'),
          content: const Text(
            'Los datos de esta candidatura todavía no se han enviado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Descartar y salir'),
            ),
          ],
        ),
      );
      if (!mounted || exit != true) return;
    }
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.canPop()
            ? context.pop()
            : context.go('/missions/${widget.missionId}');
      }
    });
  }

  void _next() {
    if (_step == 1) {
      setState(() => _validation = true);
      if (!(_form.currentState?.validate() ?? false) || !_available) return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step++;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final input = MissionApplicationInput(
      message: _message.text,
      availabilityConfirmed: _available,
      evidence: List.of(_samples),
      operationId: _operationId,
    );
    final error = input.validate();
    if (error != null) {
      setState(() {
        _step = 1;
        _error = error;
        _validation = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.controller.communityRepository!.submitApplication(
        widget.missionId,
        input,
      );
      if (!mounted) return;
      setState(() => _allowExit = true);
      context.go(
        '/missions/${widget.missionId}/sent?application=${Uri.encodeQueryComponent(id)}',
      );
    } catch (error) {
      // The transaction may have committed before its response was lost.
      try {
        final applications = await widget.controller.communityRepository!
            .applications(missionId: widget.missionId);
        final recovered = applications
            .where(
              (a) =>
                  a.missionId == widget.missionId &&
                  a.applicantId == widget.controller.profile?.id &&
                  a.status != 'withdrawn',
            )
            .firstOrNull;
        if (mounted && recovered != null) {
          final matches =
              recovered.message == input.message.trim() &&
              recovered.availabilityConfirmed == input.availabilityConfirmed &&
              _sameEvidence(recovered.evidence, input.evidence);
          if (matches) {
            setState(() => _allowExit = true);
            context.go(
              '/missions/${widget.missionId}/sent?application=${Uri.encodeQueryComponent(recovered.id)}',
            );
          } else {
            setState(() {
              _own = recovered;
              _error =
                  'Tu candidatura ya fue enviada. Los cambios posteriores no se enviaron.';
            });
          }
          return;
        }
      } catch (_) {
        /* Keep the original failure and the complete form for retry. */
      }
      try {
        final current = await widget.controller.communityRepository!.mission(
          widget.missionId,
        );
        if (mounted) setState(() => _mission = current);
      } catch (_) {
        // Keep the complete candidature while connectivity is unavailable.
      }
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _sameEvidence(List<MissionEvidence> left, List<MissionEvidence> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].title.trim() != right[i].title.trim() ||
          left[i].showcaseId != right[i].showcaseId ||
          left[i].url?.trim() != right[i].url?.trim()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _addLink() async {
    if (_samples.length >= 3) return;
    final evidence = await showDialog<MissionEvidence>(
      context: context,
      builder: (_) => const _EvidenceLinkDialog(),
    );
    if (!mounted || evidence == null) return;
    if (_samples.any((e) => e.url == evidence.url)) {
      setState(() => _error = 'Este enlace ya está en tu candidatura.');
      return;
    }
    setState(() {
      _samples.add(evidence);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mission = _mission;
    final restricted = _restriction;
    final canApply =
        !_loading && mission != null && restricted == null && _own == null;
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: MissionFlowScaffold(
        title: 'Tu candidatura',
        onBack: _leave,
        actions: [
          IconButton(
            tooltip: 'Cerrar candidatura',
            onPressed: _busy ? null : _leave,
            icon: const Icon(Icons.close),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: ValueKey(_step),
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) ...[
                    CommunityNotice(
                      message: _error!,
                      onRetry: _busy ? null : _load,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (mission == null && _error == null)
                    const CommunityNotice(
                      message: 'Esta misión ya no está disponible.',
                    )
                  else if (_own != null) ...[
                    const CommunityNotice(
                      message:
                          'Ya tienes una candidatura para esta misión. Puedes seguir su estado en Mis candidaturas.',
                      icon: Icons.task_alt,
                    ),
                    const SizedBox(height: 16),
                    MissionSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Candidatura enviada',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(_own!.message),
                          const SizedBox(height: 12),
                          MissionFact(
                            icon: Icons.event_available,
                            text: _own!.availabilityConfirmed == true
                                ? 'Disponibilidad confirmada'
                                : 'Disponibilidad no registrada',
                          ),
                          for (final sample in _own!.evidence)
                            MissionEvidenceTile(
                              controller: widget.controller,
                              evidence: sample,
                              applicantId: _own!.applicantId,
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go('/missions?section=applications'),
                      child: const Text('Ver mis candidaturas'),
                    ),
                  ] else if (restricted != null)
                    CommunityNotice(message: restricted)
                  else if (mission != null) ...[
                    Row(
                      children: List.generate(
                        3,
                        (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? AppColors.aqua
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'PASO ${_step + 1} DE 3',
                      style: const TextStyle(
                        color: AppColors.aquaDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        'Antes de sumarte',
                        'Haz que tu trabajo hable',
                        'Tu candidatura, lista para salir',
                      ][_step],
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandNavy,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        'Revisa lo que haremos juntos y las condiciones de la misión.',
                        'Cuéntanos qué puedes aportar. Las muestras de trabajo son opcionales.',
                        'Comprueba tus datos antes de compartirlos con el organizador.',
                      ][_step],
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (_step == 0) ...[
                      MissionSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(mission.body),
                            const SizedBox(height: 16),
                            MissionFact(
                              icon: Icons.calendar_today_outlined,
                              text: missionDate(mission.startsAt),
                            ),
                            MissionFact(
                              icon: Icons.place_outlined,
                              text: mission.location,
                            ),
                            MissionFact(
                              icon: Icons.people_outline,
                              text:
                                  mission.targetType?.databaseValue ??
                                  'Todos los perfiles',
                            ),
                            MissionFact(
                              icon: Icons.payments_outlined,
                              text: mission.compensationLabel,
                            ),
                            if (mission.requirements?.isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Lo que necesitas',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(mission.requirements!),
                            ],
                            if (mission.conditions?.isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Condiciones de colaboración',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(mission.conditions!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const MissionHint(
                        icon: Icons.handshake_outlined,
                        text:
                            'Enviar una candidatura expresa tu interés. El organizador revisará tu propuesta y podrás consultar la respuesta en MAREA.',
                      ),
                    ],
                    if (_step == 1) ...[
                      if (_works.isNotEmpty) ...[
                        const Text(
                          'Elige hasta 3 muestras relevantes',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final work in _works)
                              SizedBox(
                                width: 138,
                                child: _WorkChoice(
                                  controller: widget.controller,
                                  work: work,
                                  selected: _samples.any(
                                    (e) => e.showcaseId == work.id,
                                  ),
                                  onTap: () {
                                    final index = _samples.indexWhere(
                                      (e) => e.showcaseId == work.id,
                                    );
                                    if (index < 0 && _samples.length >= 3) {
                                      setState(
                                        () => _error =
                                            'Puedes incluir hasta tres muestras.',
                                      );
                                      return;
                                    }
                                    setState(() {
                                      index >= 0
                                          ? _samples.removeAt(index)
                                          : _samples.add(
                                              MissionEvidence(
                                                title: work.title,
                                                showcaseId: work.id,
                                              ),
                                            );
                                      _error = null;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_workMore) ...[
                        TextButton(
                          onPressed: _workBusy
                              ? null
                              : () => _loadWorks(append: true),
                          child: Text(
                            _workBusy
                                ? 'Cargando fichas…'
                                : 'Cargar más fichas',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_workError != null) ...[
                        CommunityNotice(
                          message: _workError!,
                          onRetry: () => _loadWorks(append: _workOffset > 0),
                        ),
                        const SizedBox(height: 12),
                      ],
                      for (final sample in _samples.where((s) => s.url != null))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.link),
                          title: Text(sample.title),
                          subtitle: Text(
                            sample.url!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Quitar muestra',
                            onPressed: () =>
                                setState(() => _samples.remove(sample)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _samples.length >= 3 ? null : _addLink,
                        icon: const Icon(Icons.add_link),
                        label: Text('Añadir enlace · ${_samples.length}/3'),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _message,
                          minLines: 4,
                          maxLines: 7,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            labelText: 'Cuéntanos por qué encajas',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Cuéntanos por qué encajas.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const MissionHint(
                        icon: Icons.lightbulb_outline,
                        text:
                            'Cuenta qué puedes aportar de forma concreta. Una candidatura personal ayuda a conocer tu propuesta.',
                      ),
                      const SizedBox(height: 18),
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        value: _available,
                        onChanged: (v) =>
                            setState(() => _available = v ?? false),
                        title: const Text('Confirmo mi disponibilidad'),
                        subtitle: Text(missionDate(mission.startsAt)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_validation && !_available)
                        const Text(
                          'Confirma tu disponibilidad para la fecha de la misión.',
                          style: TextStyle(color: AppColors.error),
                        ),
                    ],
                    if (_step == 2) ...[
                      MissionSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            MissionFact(
                              icon: Icons.event_available,
                              text:
                                  'Disponibilidad confirmada · ${missionDate(mission.startsAt)}',
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tu propuesta',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(_message.text.trim()),
                            if (_samples.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text(
                                'Tus muestras',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              for (final sample in _samples)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: MissionFact(
                                    icon: sample.url == null
                                        ? Icons.collections_outlined
                                        : Icons.link,
                                    text: sample.title,
                                  ),
                                ),
                            ],
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _step = 1),
                                child: const Text('Editar candidatura'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const MissionHint(
                        icon: Icons.lock_outline,
                        text:
                            'Tu candidatura y tus muestras solo serán visibles para ti y para el organizador.',
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ],
              ),
        footer: !canApply
            ? null
            : Row(
                children: [
                  if (_step > 0) ...[
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _step--;
                              _error = null;
                            }),
                      child: const Text('Atrás'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : _step == 2
                          ? _submit
                          : _next,
                      icon: Icon(
                        _step == 2 ? Icons.send_outlined : Icons.arrow_forward,
                      ),
                      label: Text(
                        _busy
                            ? 'Enviando…'
                            : [
                                'Continuar',
                                'Revisar candidatura',
                                'Enviar candidatura',
                              ][_step],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MissionFact extends StatelessWidget {
  const MissionFact({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.actionBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text),
          ),
        ),
      ],
    ),
  );
}

class MissionHint extends StatelessWidget {
  const MissionHint({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.actionBlue),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _WorkChoice extends StatelessWidget {
  const _WorkChoice({
    required this.controller,
    required this.work,
    required this.selected,
    required this.onTap,
  });
  final AppSessionController controller;
  final ShowcaseItem work;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 102,
                width: 138,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.actionBlue : AppColors.border,
                    width: selected ? 3 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: work.imagePaths.isEmpty
                    ? const Icon(
                        Icons.collections_outlined,
                        color: AppColors.actionBlue,
                      )
                    : FutureBuilder<String>(
                        future: controller.showcaseRepository!.imageUrl(
                          work.imagePaths.first,
                        ),
                        builder: (_, s) => s.hasData
                            ? Image.network(
                                s.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.collections_outlined),
                              )
                            : const Icon(Icons.collections_outlined),
                      ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? AppColors.actionBlue
                      : Colors.white,
                  child: Icon(
                    selected ? Icons.check : Icons.add,
                    size: 18,
                    color: selected ? Colors.white : AppColors.actionBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            work.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _EvidenceLinkDialog extends StatefulWidget {
  const _EvidenceLinkDialog();
  @override
  State<_EvidenceLinkDialog> createState() => _EvidenceLinkDialogState();
}

class _EvidenceLinkDialogState extends State<_EvidenceLinkDialog> {
  final _title = TextEditingController(), _url = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Añadir una muestra'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Título de la muestra',
                ),
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : 'Escribe un título.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Enlace HTTPS'),
                validator: (_) => MissionEvidence(
                  title: _title.text,
                  url: _url.text.trim(),
                ).validate(),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              MissionEvidence(title: _title.text.trim(), url: _url.text.trim()),
            );
          }
        },
        child: const Text('Añadir muestra'),
      ),
    ],
  );
}

/// Resolves fiche visibility again: removed or hidden work is never leaked.
class MissionEvidenceTile extends StatefulWidget {
  const MissionEvidenceTile({
    super.key,
    required this.controller,
    required this.evidence,
    required this.applicantId,
  });
  final AppSessionController controller;
  final MissionEvidence evidence;
  final String applicantId;
  @override
  State<MissionEvidenceTile> createState() => _MissionEvidenceTileState();
}

class _MissionEvidenceTileState extends State<MissionEvidenceTile> {
  late Future<ShowcaseItem?> _item = _load();
  Future<ShowcaseItem?> _load() async {
    final id = widget.evidence.showcaseId;
    if (id == null || widget.controller.showcaseRepository == null) return null;
    try {
      return await widget.controller.showcaseRepository!.item(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant MissionEvidenceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidence.showcaseId != widget.evidence.showcaseId) {
      _item = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final evidence = widget.evidence;
    if (evidence.url != null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.link, color: AppColors.actionBlue),
        title: Text(evidence.title),
        subtitle: Text(
          evidence.url!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () async {
          if (evidence.validate() != null) return;
          try {
            final opened = await launchUrl(
              Uri.parse(evidence.url!),
              mode: LaunchMode.externalApplication,
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No pudimos abrir el enlace.')),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No pudimos abrir el enlace.')),
              );
            }
          }
        },
      );
    }
    return FutureBuilder<ShowcaseItem?>(
      future: _item,
      builder: (_, snapshot) {
        final item = snapshot.data;
        final visible =
            item != null &&
            item.ownerId == widget.applicantId &&
            item.status == ShowcaseStatus.published &&
            item.available &&
            !item.hidden;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.collections_outlined,
            color: AppColors.actionBlue,
          ),
          title: Text(
            visible
                ? item.title
                : snapshot.connectionState == ConnectionState.done
                ? 'Muestra no disponible'
                : 'Cargando muestra…',
          ),
          trailing: visible ? const Icon(Icons.chevron_right) : null,
          onTap: visible ? () => context.push('/showcase/${item.id}') : null,
        );
      },
    );
  }
}

class MissionApplicationSentScreen extends StatefulWidget {
  const MissionApplicationSentScreen({
    super.key,
    required this.controller,
    required this.missionId,
    this.applicationId,
  });
  final AppSessionController controller;
  final String missionId;
  final String? applicationId;
  @override
  State<MissionApplicationSentScreen> createState() =>
      _MissionApplicationSentScreenState();
}

class _MissionApplicationSentScreenState
    extends State<MissionApplicationSentScreen> {
  late Future<(Mission?, MissionApplication?)> _future = _load();
  Future<(Mission?, MissionApplication?)> _load() async {
    final repo = widget.controller.communityRepository,
        viewer = widget.controller.profile;
    if (repo == null || viewer == null) return (null, null);
    final mission = await repo.mission(widget.missionId);
    final applications = await repo.applications(missionId: widget.missionId);
    final own = applications
        .where(
          (a) =>
              a.applicantId == viewer.id &&
              a.missionId == widget.missionId &&
              (widget.applicationId == null || a.id == widget.applicationId),
        )
        .firstOrNull;
    return (mission, own);
  }

  @override
  void didUpdateWidget(covariant MissionApplicationSentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missionId != widget.missionId ||
        oldWidget.applicationId != widget.applicationId ||
        oldWidget.controller != widget.controller) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => MissionFlowScaffold(
    title: 'Candidatura',
    onBack: () => context.go('/missions?section=applications'),
    body: FutureBuilder<(Mission?, MissionApplication?)>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return CommunityNotice(
            message: communityError(snapshot.error!),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final (mission, application) = snapshot.data!;
        if (application == null) {
          return const CommunityNotice(
            message: 'No encontramos una candidatura tuya para esta misión.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.success,
                    child: Icon(
                      Icons.check_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              '¡Tu candidatura ya está en movimiento!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brandNavy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission == null
                  ? 'Tu candidatura se guardó. La misión ya no está disponible; puedes consultar tu historial.'
                  : 'Hemos enviado tu candidatura para «${mission.title}». Puedes seguir su estado en Mis candidaturas.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const MissionHint(
              icon: Icons.notifications_none_rounded,
              text:
                  '¿Qué pasa ahora? El organizador revisará tu propuesta. Cuando haya una respuesta, aparecerá en tus notificaciones de MAREA.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go('/missions?section=applications'),
              child: const Text('Ver mis candidaturas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/missions'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Seguir explorando'),
            ),
          ],
        );
      },
    ),
  );
}
