import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/l10n/app_localizations.dart' as gen;
import 'package:marea/l10n/app_localizations_es.dart' as gen;

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
class ShowcaseDetailScreen extends StatefulWidget {
  const ShowcaseDetailScreen({
    required this.controller,
    required this.itemId,
    super.key,
  });
  final AppSessionController controller;
  final String itemId;
  @override
  State<ShowcaseDetailScreen> createState() => _ShowcaseDetailScreenState();
}

class _ShowcaseDetailScreenState extends State<ShowcaseDetailScreen> {
  ShowcaseItem? _item;
  CommunityProfile? _owner;
  bool _loading = true, _busy = false, _saved = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = widget.controller.showcaseRepository;
      if (repo == null) throw StateError('repository unavailable');
      final item = await repo.item(widget.itemId);
      CommunityProfile? owner;
      if (item != null) {
        if (item.ownerId == widget.controller.profile?.id) {
          owner = CommunityProfile.fromJson(
            widget.controller.profile!.toJson(),
          );
        } else {
          final owners = await widget.controller.communityRepository?.profiles(
            ids: [item.ownerId],
          );
          if (owners?.isNotEmpty == true) owner = owners!.first;
        }
      }
      final saved = await repo.savedIds();
      if (mounted) {
        setState(() {
          _item = item;
          _owner = owner;
          _saved = saved.contains(widget.itemId);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = communityError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await runCommunityAction(context, action, success: success);
    if (mounted) setState(() => _busy = false);
    if (ok && mounted) await _load();
  }

  Future<void> _delete() async {
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(core_l10n.AppLocalizations.tr(l10n.eliminarEstaFicha)),
        content: Text(core_l10n.AppLocalizations.tr(l10n.eliminarFichaAdvertencia)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(core_l10n.AppLocalizations.tr(l10n.cancelar)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(core_l10n.AppLocalizations.tr(l10n.eliminar)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await runCommunityAction(
      context,
      () => widget.controller.showcaseRepository!.delete(_item!),
      success: (gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs())
          .fichaEliminada,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.canPop() ? context.pop() : context.go('/profile');
  }

  Future<void> _edit() async {
    if (_busy) return;
    await context.push('/showcase/${widget.itemId}/edit');
    if (mounted) await _load();
  }

  Widget _details(ShowcaseItem item, bool owner) {
    final repo = widget.controller.showcaseRepository!;
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    return ProfileFormSection(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              core_l10n.AppLocalizations.tr(
                l10n.fichaTipoCategoria(
                  localizedShowcaseKindLabel(context, item.kind),
                  localizedShowcaseCategoryLabel(context, item.category),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(item.body),
            const SizedBox(height: 20),
            if (item.kind != ShowcaseKind.project)
              Text(
                item.price == null
                    ? core_l10n.AppLocalizations.tr(l10n.consultarPrecio)
                    : '\$${item.price!.toStringAsFixed(2)} MXN',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (_owner != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_owner!.fullName),
                subtitle: Text('@${_owner!.username}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/people/${item.ownerId}'),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (item.status == ShowcaseStatus.published &&
                    item.available &&
                    !item.hidden)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _action(() => repo.setSaved(item.id, !_saved)),
                    icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(_saved ? core_l10n.AppLocalizations.tr(l10n.quitarDeGuardados) : core_l10n.AppLocalizations.tr(l10n.guardar)),
                  ),
                if (item.projectUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => runCommunityAction(context, () async {
                      if (!await launchUrl(
                        Uri.parse(item.projectUrl!),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw StateError('link unavailable');
                      }
                    }),
                    icon: const Icon(Icons.link),
                    label: Text(core_l10n.AppLocalizations.tr(l10n.verProyectoFicha)),
                  ),
                if (!owner &&
                    item.status == ShowcaseStatus.published &&
                    !item.hidden)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            final reason = await askCommunityText(
                              context,
                              title: core_l10n.AppLocalizations.tr(l10n.reportarFicha),
                              label: core_l10n.AppLocalizations.tr(l10n.motivoReporteFicha),
                              maxLength: 500,
                            );
                            if (reason != null && mounted) {
                              await _action(
                                () => repo.report(item.id, reason),
                                success: core_l10n.AppLocalizations.tr(l10n.reporteFichaEnviado),
                              );
                            }
                          },
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(core_l10n.AppLocalizations.tr(l10n.reportar)),
                  ),
              ],
            ),
            if (owner) ...[
              const Divider(height: 40),
              Text(
                core_l10n.AppLocalizations.tr(
                  l10n.administrarFichaEstado(
                    localizedShowcaseStatusLabel(context, item.status),
                  ),
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!item.available) Text(core_l10n.AppLocalizations.tr(l10n.noDisponibleSoloAdministracion)),
              if (item.hidden) Text(core_l10n.AppLocalizations.tr(l10n.ocultaPorModeracion)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _action(() async {
                            await repo.save(
                              ShowcaseInput(
                                kind: item.kind,
                                title: item.title,
                                body: item.body,
                                category: item.category,
                                status: item.status == ShowcaseStatus.archived
                                    ? ShowcaseStatus.draft
                                    : ShowcaseStatus.archived,
                                available: item.available,
                                price: item.price,
                                projectUrl: item.projectUrl,
                                imagePaths: item.imagePaths,
                              ),
                              id: item.id,
                            );
                          }),
                    icon: const Icon(Icons.archive_outlined),
                    label: Text(
                      item.status == ShowcaseStatus.archived
                          ? core_l10n.AppLocalizations.tr(l10n.volverABorrador)
                          : core_l10n.AppLocalizations.tr(l10n.archivarFicha),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(core_l10n.AppLocalizations.tr(l10n.eliminarFicha)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _detailBody(ShowcaseItem item, bool owner) => MareaRefreshIndicator(
    onRefresh: () async {
      if (!_busy) await _load();
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1024;
        final gallery = item.imagePaths.isEmpty
            ? null
            : ShowcaseGallery(
                key: ValueKey(item.id),
                item: item,
                controller: widget.controller,
                height: wide ? 420 : 280,
              );
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: wide && gallery != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: gallery),
                        const SizedBox(width: 24),
                        Expanded(child: _details(item, owner)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (gallery != null) ...[
                          gallery,
                          const SizedBox(height: 20),
                        ],
                        _details(item, owner),
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    final item = _item;
    final repo = widget.controller.showcaseRepository;
    final owner = item?.ownerId == widget.controller.profile?.id;
    return Scaffold(
      appBar: AppBar(
        leading: const ProfileBackButton(),
        title: Text(
          item == null
              ? core_l10n.AppLocalizations.tr(l10n.ficha)
              : localizedShowcaseKindLabel(context, item.kind),
        ),
      ),
      body: _loading && item == null
          ? const Center(child: MareaSkeleton(kind: SkeletonKind.detail))
          : _error != null
          ? CommunityNotice(message: _error!, onRetry: _load)
          : item == null || repo == null
          ? CommunityNotice(message: core_l10n.AppLocalizations.tr(l10n.estaFichaNoDisponible))
          : _detailBody(item, owner),
      bottomNavigationBar:
          (_loading && item == null) ||
              _error != null ||
              item == null ||
              repo == null
          ? null
          : owner
          ? ProfileActionBar(
              child: FilledButton.icon(
                onPressed: _busy ? null : _edit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(core_l10n.AppLocalizations.tr(l10n.editarFicha)),
              ),
            )
          : _owner?.contactUrl != null &&
                ProfilePreferences.websiteError(_owner!.contactUrl) == null
          ? ProfileActionBar(
              child: FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => runCommunityAction(context, () async {
                        if (!await launchUrl(
                          Uri.parse(_owner!.contactUrl!),
                          mode: LaunchMode.externalApplication,
                        )) {
                          throw StateError('link unavailable');
                        }
                      }),
                icon: const Icon(Icons.open_in_new),
                label: Text(core_l10n.AppLocalizations.tr(l10n.contactar)),
              ),
            )
          : null,
    );
  }
}

class ShowcaseGallery extends StatefulWidget {
  const ShowcaseGallery({
    required this.item,
    required this.controller,
    required this.height,
    super.key,
  });
  final ShowcaseItem item;
  final AppSessionController controller;
  final double height;
  @override
  State<ShowcaseGallery> createState() => _ShowcaseGalleryState();
}

class _ShowcaseGalleryState extends State<ShowcaseGallery> {
  final _pages = PageController();
  int _index = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int delta) => _pages.animateToPage(
    _index + delta,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) {
    final l10n = gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
    return MareaSurface(
      radius: 24,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView(
              controller: _pages,
              onPageChanged: (value) => setState(() => _index = value),
              children: [
                for (final path in widget.item.imagePaths)
                  ShowcasePhoto(
                    path: path,
                    repository: widget.controller.showcaseRepository!,
                    height: widget.height,
                  ),
              ],
            ),
          ),
          if (widget.item.imagePaths.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: core_l10n.AppLocalizations.tr(l10n.fotografiaAnterior),
                    onPressed: _index == 0 ? null : () => _move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '${_index + 1} / ${widget.item.imagePaths.length}',
                    ),
                  ),
                  IconButton(
                    tooltip: core_l10n.AppLocalizations.tr(l10n.fotografiaSiguiente),
                    onPressed: _index == widget.item.imagePaths.length - 1
                        ? null
                        : () => _move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
