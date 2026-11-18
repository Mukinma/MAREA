import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/features/home_feed/presentation/story_moderation.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final _reports = <ContentReport>[];
  bool _loading = true, _more = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (widget.controller.profile?.role != ProfileRole.admin) return;
    final repo = widget.controller.communityRepository;
    if (repo == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await repo.reports(offset: reset ? 0 : _reports.length);
      if (!mounted) return;
      setState(() {
        if (reset) _reports.clear();
        _reports.addAll(reports);
        _more = reports.length == 30;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = communityError(error);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.tr('Moderación'))),
    body:
        widget.controller.profile?.role != ProfileRole.admin ||
            widget.controller.communityRepository == null
        ? CommunityNotice(
            message: AppLocalizations.tr(
              'Esta sección está reservada para administradores.',
            ),
          )
        : CommunityPage(
            title: AppLocalizations.tr('Reportes de la comunidad'),
            subtitle: AppLocalizations.tr(
              'Revisa el contenido antes de ocultarlo. Los reportes revisados se conservan para poder restaurarlo.',
            ),
            onRefresh: _loading ? null : () => _load(reset: true),
            children: [
              if (widget.controller.storiesRepository != null)
                StoryModeration(
                  repository: widget.controller.storiesRepository!,
                ),
              if (widget.controller.tourRepository != null)
                ListTile(
                  leading: const Icon(Icons.view_in_ar_outlined),
                  title: Text(AppLocalizations.tr('Espacios y recorridos')),
                  subtitle: Text(
                    AppLocalizations.tr(
                      'Acreditar responsables y revisar versiones enviadas.',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tours/requests'),
                ),

              if (_reports.isEmpty && !_loading && _error == null)
                CommunityNotice(
                  message: AppLocalizations.tr('No hay reportes para revisar.'),
                ),
              for (final report in _reports)
                _ReportCard(
                  key: ValueKey(report.id),
                  report: report,
                  controller: widget.controller,
                  onChanged: () => _load(reset: true),
                ),
              if (_error != null)
                CommunityNotice(message: _error!, onRetry: () => _load()),
              if (_loading)
                const Center(child: MareaSkeleton(kind: SkeletonKind.list)),
              if (_more && !_loading && _error == null)
                TextButton(
                  onPressed: _load,
                  child: Text(AppLocalizations.tr('Cargar más reportes')),
                ),
            ],
          ),
  );
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.report,
    required this.controller,
    required this.onChanged,
    super.key,
  });
  final ContentReport report;
  final AppSessionController controller;
  final Future<void> Function() onChanged;
  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final repo = widget.controller.communityRepository!;
    final isMission = report.missionId != null;
    return MareaCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.tr(
                report.state == 'open' ? 'Pendiente de revisión' : 'Revisado',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.trTemplate('Motivo: {reason}', {
                'reason': report.reason,
              }),
            ),
            const Divider(height: 32),
            CommunityLoad<Object?>(
              load: () async => report.showcaseId != null
                  ? await widget.controller.showcaseRepository?.item(
                      report.showcaseId!,
                    )
                  : isMission
                  ? await repo.mission(report.missionId!)
                  : await repo.post(report.postId!),
              builder: (content, reload) {
                if (content == null) {
                  return Text(
                    AppLocalizations.tr('El contenido fue eliminado.'),
                  );
                }
                final title = content is ShowcaseItem
                    ? content.title
                    : content is Mission
                    ? content.title
                    : (content as CommunityPost).title;
                final body = content is ShowcaseItem
                    ? content.body
                    : content is Mission
                    ? content.body
                    : (content as CommunityPost).body;
                final hidden = content is ShowcaseItem
                    ? content.hidden
                    : content is Mission
                    ? content.hidden
                    : (content as CommunityPost).hidden;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SelectableText(body),
                    const SizedBox(height: 12),
                    if (content is ShowcaseItem) ...[
                      Text(
                        AppLocalizations.trTemplate('{kind} · {status}', {
                          'kind': content.kind.label,
                          'status': content.status.label,
                        }),
                      ),
                      for (final path in content.imagePaths)
                        ShowcasePhoto(
                          path: path,
                          repository: widget.controller.showcaseRepository!,
                        ),
                    ],
                    if (content is CommunityPost) ...[
                      Text(
                        '${AppLocalizations.tr(content.kind.label)} · ${missionCategoryLabel(content.category)}',
                      ),
                      if (content.location != null)
                        Text(
                          AppLocalizations.trTemplate('Ubicación: {location}', {
                            'location': content.location.toString(),
                          }),
                        ),
                      if (content.price != null)
                        Text(
                          AppLocalizations.trTemplate('Precio: {price} MXN', {
                            'price': '\$${content.price!.toStringAsFixed(2)}',
                          }),
                        ),
                      if (content.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: CommunityLoad<String>(
                            key: ValueKey(content.imagePath),
                            load: () => repo.imageUrl(content.imagePath!),
                            builder: (url, _) => Image.network(
                              url,
                              height: 320,
                              fit: BoxFit.contain,
                              semanticLabel: AppLocalizations.tr(
                                'Imagen de la publicación reportada',
                              ),
                              errorBuilder: (_, _, _) => CommunityNotice(
                                message: AppLocalizations.tr(
                                  'No pudimos cargar la fotografía reportada.',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (content is Mission) ...[
                      if (content.imagePath != null)
                        MissionCover(
                          path: content.imagePath,
                          repository: repo,
                          height: 240,
                        ),
                      if (content.requirements != null)
                        Text(content.requirements!),
                      if (content.conditions != null) Text(content.conditions!),
                      if (content.cancellationReason != null)
                        Text(
                          AppLocalizations.trTemplate('Cancelación: {reason}', {
                            'reason': '${content.cancellationReason}',
                          }),
                        ),
                      Text(
                        AppLocalizations.trTemplate('Categoría: {category}', {
                          'category': missionCategoryLabel(content.category),
                        }),
                      ),
                      Text(
                        AppLocalizations.trTemplate('Ubicación: {location}', {
                          'location': content.location.toString(),
                        }),
                      ),
                      Text(
                        AppLocalizations.trTemplate('Fecha: {date}', {
                          'date': content.startsAt.toLocal().toString(),
                        }),
                      ),
                      Text(
                        AppLocalizations.trTemplate(
                          'Cupo: {capacity} · {status}',
                          {
                            'capacity': '${content.capacity}',
                            'status': AppLocalizations.tr(content.statusLabel),
                          },
                        ),
                      ),
                      Text(
                        AppLocalizations.trTemplate('Dirigida a: {target}', {
                          'target': missionTargetLabel(content.targetType),
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.tr(
                        hidden
                            ? 'Oculto para la comunidad'
                            : 'Visible para la comunidad',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              final ok = await runCommunityAction(
                                context,
                                () => report.showcaseId != null
                                    ? widget.controller.showcaseRepository!
                                          .moderate(report.showcaseId!, !hidden)
                                    : repo.moderate(
                                        report.missionId ?? report.postId!,
                                        mission: isMission,
                                        hide: !hidden,
                                      ),
                                success: AppLocalizations.tr(
                                  hidden
                                      ? 'Contenido restaurado.'
                                      : 'Contenido ocultado.',
                                ),
                              );
                              if (mounted) setState(() => _busy = false);
                              if (ok && mounted) {
                                await reload();
                                if (!mounted) return;
                                await widget.onChanged();
                              }
                            },
                      icon: Icon(
                        hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      label: Text(
                        AppLocalizations.tr(
                          hidden ? 'Restaurar contenido' : 'Ocultar contenido',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
