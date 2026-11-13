import 'package:marea/features/home_feed/presentation/follow_button.dart';
import 'package:marea/features/tours/presentation/tour_management_screen.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/notifications_panel.dart';
import 'package:marea/features/profile/presentation/profile_identity.dart';
import 'package:marea/features/profile/presentation/profile_tools_sheet.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/profile/presentation/profile_content_sections.dart';

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
  final _postsKey = GlobalKey();
  bool get _owner =>
      widget.owner && widget.controller.profile?.id == widget.profile.id;
  int _chatGeneration = 0;
  int _revision = 0;
  String? _conversationId;
  String? _conversationStatus;
  bool _conversationIsIncoming = false;
  bool _chatBusy = false;

  @override
  void initState() {
    super.initState();
    _loadIncomingRequest();
  }

  @override
  void didUpdateWidget(ProfileExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.controller != widget.controller) {
      _conversationId = null;
      _conversationStatus = null;
      _conversationIsIncoming = false;
      _chatBusy = false;
      _loadIncomingRequest();
    }
  }

  Future<void> _loadIncomingRequest() async {
    final generation = ++_chatGeneration;
    final repository = widget.controller.chatRepository;
    if (repository == null || _owner) return;
    try {
      final conversations = await repository.conversations();
      if (mounted && generation == _chatGeneration) {
        final conversation = conversations
            .where(
              (conversation) =>
                  (conversation.requesterId == widget.profile.id &&
                      conversation.recipientId ==
                          widget.controller.profile?.id) ||
                  (conversation.recipientId == widget.profile.id &&
                      conversation.requesterId ==
                          widget.controller.profile?.id),
            )
            .firstOrNull;
        setState(() {
          _conversationId = conversation?.id;
          _conversationStatus = conversation?.status;
          _conversationIsIncoming =
              conversation?.requesterId == widget.profile.id &&
              conversation?.recipientId == widget.controller.profile?.id;
        });
      }
    } catch (_) {
      // The profile remains usable when chat status cannot be loaded.
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
        AppLocalizations.tr('Herramientas'),
        _menu,
      ),
      (
        Icons.bookmark_border,
        AppLocalizations.tr('Guardados'),
        () => context.go('/explore?section=saved'),
      ),
      (
        Icons.flag_outlined,
        AppLocalizations.tr('Mis misiones'),
        () => context.go('/missions?section=own'),
      ),
      (
        Icons.assignment_outlined,
        AppLocalizations.tr('Mis postulaciones'),
        () => context.go('/missions?section=applications'),
      ),
      if (widget.admin)
        (
          Icons.shield_outlined,
          AppLocalizations.tr('Moderación'),
          () => _open('/moderation'),
        ),
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

  Future<void> _menu() async {
    final route = await showProfileTools(
      context,
      profile: widget.profile,
      controller: widget.controller,
      admin: _owner && widget.admin,
    );
    if (!mounted || route == null) return;
    if (route == '#showcase') {
      await _allShowcase();
    } else if (route == '#missions') {
      await _allMissions();
    } else if (route == '#notifications' && _owner) {
      await openNotifications(context, widget.controller);
    } else if (route == '#posts') {
      final target = _postsKey.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    } else if (_owner) {
      if (route.startsWith('/missions?') ||
          route.startsWith('/explore?') ||
          route == '/map') {
        context.go(route);
      } else {
        await _open(route);
      }
    }
  }

  Future<void> _allShowcase() async {
    await showProfileShowcase(
      context,
      controller: widget.controller,
      profile: widget.profile,
      owner: _owner,
      onOpen: _open,
    );
    if (mounted) setState(() => _revision++);
  }

  Future<void> _allMissions() async {
    final repo = widget.controller.communityRepository;
    if (repo == null) return;
    await showProfileMissions(
      context,
      repository: repo,
      ownerId: widget.profile.id,
      owner: _owner,
      onOpen: _open,
    );
    if (mounted) setState(() => _revision++);
  }

  Widget _content() {
    final profile = widget.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile.userType.showcaseKinds.isNotEmpty) ...[
          ProfileShowcasePreview(
            key: ValueKey((profile.id, _revision, 'showcase')),
            controller: widget.controller,
            profile: profile,
            owner: _owner,
            onOpen: _open,
            onSeeAll: _allShowcase,
          ),
          const SizedBox(height: 14),
        ],
        ProfileMissionsPreview(
          key: ValueKey((profile.id, _revision, 'missions')),
          controller: widget.controller,
          ownerId: profile.id,
          onOpen: _open,
          onSeeAll: _allMissions,
        ),
        const SizedBox(height: 20),
        ProfileSectionHeading(
          key: _postsKey,
          title: AppLocalizations.tr('Publicaciones'),
        ),
        if (_owner)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _open('/posts/new'),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.tr('Agregar publicación')),
            ),
          ),
        if (widget.controller.communityRepository != null)
          PostsFeed(
            key: ValueKey((profile.id, _revision, 'posts')),
            controller: widget.controller,
            authorId: profile.id,
            showHeading: false,
          ),
        if (widget.controller.tourRepository != null)
          ProfileTourCard(
            key: ValueKey((profile.id, _revision, 'tours')),
            controller: widget.controller,
            profileId: profile.id,
          ),
        if (_owner) ...[const SizedBox(height: 12), _shortcuts(false)],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF4FBFE),
    child: SafeArea(
      top: false,
      bottom: false,
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
                  onSettings: () => _open('/settings'),
                  settingsTooltip: _owner
                      ? AppLocalizations.tr('Configuración')
                      : AppLocalizations.tr('Configuración de tu cuenta'),
                  onMenu: _menu,
                  editAction: _owner
                      ? TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: () => _open('/profile/edit'),
                          label: Text(AppLocalizations.tr('Editar perfil')),
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(48, 40),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF07345C),
                            shape: const StadiumBorder(),
                          ),
                        )
                      : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ProfileStatisticsCard(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ProfileAbout(profile: widget.profile, owner: _owner),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ProfileInterests(
                    profile: widget.profile,
                    onEdit: _owner ? () => _open('/profile/edit') : null,
                  ),
                ),
                if (!_owner &&
                    widget.controller.homeFeedRepository != null &&
                    widget.controller.profile?.id != widget.profile.id) ...[
                  const SizedBox(height: 12),
                  FollowButton(
                    repository: widget.controller.homeFeedRepository!,
                    authorId: widget.profile.id,
                    onChanged: widget.controller.refreshHomeFeed,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _chatBusy
                        ? null
                        : () async {
                            final chat = widget.controller.chatRepository;
                            if (chat == null) return;
                            setState(() => _chatBusy = true);
                            try {
                              final accepting =
                                  _conversationStatus == 'pending' &&
                                  _conversationIsIncoming;
                              final viewing =
                                  _conversationStatus == 'accepted' &&
                                  _conversationId != null;
                              if (viewing) {
                                if (context.mounted) {
                                  context.push('/messages/$_conversationId');
                                }
                                return;
                              }
                              if (accepting) {
                                await chat.accept(_conversationId!);
                                if (mounted) {
                                  setState(
                                    () => _conversationStatus = 'accepted',
                                  );
                                }
                              } else {
                                final id = await chat.request(
                                  widget.profile.id,
                                );
                                if (mounted) {
                                  setState(() {
                                    _conversationId = id;
                                    _conversationStatus = 'pending';
                                    _conversationIsIncoming = false;
                                  });
                                }
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        accepting
                                            ? AppLocalizations.tr(
                                                'Solicitud aceptada. Ya pueden conversar.',
                                              )
                                            : AppLocalizations.tr(
                                                'Solicitud enviada. Podrás escribir cuando la otra persona acepte.',
                                              ),
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.tr(error.toString()),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _chatBusy = false);
                            }
                          },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      _conversationStatus == 'accepted'
                          ? AppLocalizations.tr('Ver mensajes')
                          : _conversationStatus == 'pending' &&
                                _conversationIsIncoming
                          ? AppLocalizations.tr('Aceptar solicitud')
                          : AppLocalizations.tr('Solicitar chat'),
                    ),
                  ),
                ],
              ],
            );
            return SingleChildScrollView(
              key: const Key('profile-scroll'),
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 0,
                wide ? 24 : 0,
                wide ? 24 : 0,
                112 + MediaQuery.paddingOf(context).bottom,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _content(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
