import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/profile/presentation/profile_identity.dart';
import 'package:marea/features/profile/presentation/profile_tools_sheet.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/marea_tabs.dart';

class ProfileExperience extends StatefulWidget {
  const ProfileExperience({
    required this.controller,
    required this.profile,
    required this.owner,
    required this.onRefresh,
    this.admin = false,
    this.feedback,
    super.key,
  });
  final AppSessionController controller;
  final CommunityProfile profile;
  final bool owner, admin;
  final Future<void> Function() onRefresh;
  final Widget? feedback;
  @override
  State<ProfileExperience> createState() => _ProfileExperienceState();
}

class _ProfileExperienceState extends State<ProfileExperience> {
  final _scroll = ScrollController();
  final _offsets = <String, double>{};
  late String _section = widget.profile.userType.showcaseKinds.isEmpty
      ? 'posts'
      : 'showcase';
  int _revision = 0;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String value) {
    if (value == _section) return;
    if (_scroll.hasClients) _offsets[_section] = _scroll.offset;
    setState(() => _section = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(
          (_offsets[value] ?? 0).clamp(0, _scroll.position.maxScrollExtent),
        );
      }
    });
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (mounted) setState(() => _revision++);
  }

  Future<void> _open(String route) async {
    final result = await context.push<Object?>(route);
    if (!mounted) return;
    if (route == '/missions/new' && result is String) {
      await context.push('/missions/$result');
    }
    if (mounted) setState(() => _revision++);
  }

  Widget _shortcuts(bool wide) {
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.dashboard_customize_outlined,
        'Herramientas',
        () async {
          final route = await showProfileTools(
            context,
            profile: widget.profile,
            controller: widget.controller,
            admin: widget.admin,
          );
          if (!mounted || route == null) return;
          if (route.startsWith('/missions?') || route.startsWith('/explore?')) {
            context.go(route);
          } else {
            await _open(route);
          }
        },
      ),
      (
        Icons.bookmark_border,
        'Guardados',
        () => context.go('/explore?section=saved'),
      ),
      (
        Icons.flag_outlined,
        'Mis misiones',
        () => context.go('/missions?section=own'),
      ),
      (
        Icons.assignment_outlined,
        'Mis postulaciones',
        () => context.go('/missions?section=applications'),
      ),
      if (widget.admin)
        (Icons.shield_outlined, 'Moderación', () => _open('/moderation')),
    ];
    return MareaSurface(
      radius: 20,
      padding: const EdgeInsets.all(6),
      child: wide
          ? Column(
              children: [
                for (final a in actions)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: Icon(a.$1, size: 20),
                    title: Text(a.$2, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: a.$3,
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in actions)
                  Expanded(
                    child: TextButton(
                      onPressed: a.$3,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.$1, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            a.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _content() {
    final profile = widget.profile;
    final kinds = profile.userType.showcaseKinds;
    final options = <String, String>{
      if (kinds.isNotEmpty) 'showcase': profile.userType.showcaseLabel,
      'posts': 'Publicaciones',
      if (!widget.owner) 'missions': 'Misiones',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (options.length > 1)
          MareaTabs(options: options, value: _section, onChanged: _select)
        else
          Text('Publicaciones', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (kinds.isNotEmpty)
          Visibility(
            maintainState: true,
            visible: _section == 'showcase',
            child: TickerMode(
              enabled: _section == 'showcase',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.owner) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kind in kinds)
                          FilledButton.icon(
                            onPressed: () =>
                                _open('/showcase/new?kind=${kind.name}'),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(kind.action),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  ShowcaseList(
                    key: ValueKey('showcase:${profile.id}:$_revision'),
                    controller: widget.controller,
                    ownerId: profile.id,
                    management: widget.owner,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        Visibility(
          maintainState: true,
          visible: _section == 'posts',
          child: TickerMode(
            enabled: _section == 'posts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.owner) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _open('/posts/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar publicación'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.controller.communityRepository != null)
                  PostsFeed(
                    key: ValueKey('posts:${profile.id}:$_revision'),
                    controller: widget.controller,
                    authorId: profile.id,
                    showHeading: false,
                  ),
              ],
            ),
          ),
        ),
        if (!widget.owner && widget.controller.communityRepository != null)
          Visibility(
            maintainState: true,
            visible: _section == 'missions',
            child: CommunityLoad<List<Mission>>(
              key: ValueKey('missions:${profile.id}:$_revision'),
              load: () => widget.controller.communityRepository!.missions(
                authorId: profile.id,
              ),
              builder: (missions, reload) => Column(
                children: [
                  if (missions.isEmpty)
                    const CommunityNotice(
                      message: 'Aún no ha publicado misiones.',
                    ),
                  for (final mission in missions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MissionSummary(
                        mission: mission,
                        repository: widget.controller.communityRepository!,
                        onTap: () async {
                          await context.push('/missions/${mission.id}');
                          if (mounted) reload();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: MareaRefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1024;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileIdentity(
                profile: widget.profile,
                controller: widget.controller,
                wide: wide,
                onSettings: widget.owner ? () => _open('/settings') : null,
                editAction: widget.owner
                    ? TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => _open('/profile/edit'),
                        label: const Text('Editar perfil'),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(48, 48),
                        ),
                      )
                    : null,
              ),
              if (widget.owner) ...[
                const SizedBox(height: 12),
                _shortcuts(wide),
              ],
            ],
          );
          return SingleChildScrollView(
            key: const Key('profile-scroll'),
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              wide ? 24 : 16,
              wide ? 24 : 12,
              wide ? 24 : 16,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.feedback != null) ...[
                      widget.feedback!,
                      const SizedBox(height: 12),
                    ],
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: identity),
                          const SizedBox(width: 24),
                          Expanded(child: _content()),
                        ],
                      )
                    else ...[
                      identity,
                      const SizedBox(height: 12),
                      _content(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
