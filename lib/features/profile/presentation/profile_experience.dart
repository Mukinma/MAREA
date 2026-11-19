import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/home_feed/presentation/follow_button.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/features/profile/presentation/profile_visits.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/data/community_reports_repository.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/notifications_panel.dart';
import 'package:marea/features/profile/presentation/profile_identity.dart';
import 'package:marea/features/profile/presentation/profile_tools_sheet.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
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
  late Future<ProfileFollowCounts?>? _counts = _loadCounts();
  bool _coverPastStatusBar = false;

  bool get _owner =>
      widget.owner && widget.controller.profile?.id == widget.profile.id;
  int _chatGeneration = 0;
  int _revision = 0;
  String? _conversationId;
  String? _conversationStatus;
  bool _conversationIsIncoming = false;
  bool _chatBusy = false;
  bool _chatLoading = true;
  bool _reporting = false;

  Future<void> _reportAccount() async {
    final repository = widget.controller.communityRepository;
    if (_reporting || _owner || repository is! CommunityReportsRepository) {
      return;
    }
    final target = widget.profile.id;
    final reporter = widget.controller.profile?.id;
    if (reporter == null || reporter == target) return;
    setState(() => _reporting = true);
    try {
      final reason = await askCommunityText(
        context,
        title: 'Reportar cuenta',
        label: 'Motivo del reporte',
        maxLength: 500,
        flat: true,
      );
      if (!mounted ||
          reason == null ||
          widget.controller.profile?.id != reporter ||
          widget.profile.id != target) {
        return;
      }
      await runCommunityAction(
        context,
        () => (repository as CommunityReportsRepository).reportAccount(
          target,
          reason,
        ),
        success: AppLocalizations.tr(
          'Recibimos tu reporte. Puedes consultarlo en Ayuda y reportes.',
        ),
      );
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateStatusBar);
    _loadIncomingRequest();
  }

  @override
  void didUpdateWidget(ProfileExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.controller != widget.controller) {
      _counts = _loadCounts();
      _conversationId = null;
      _conversationStatus = null;
      _conversationIsIncoming = false;
      _chatBusy = false;
      _chatLoading = true;
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
    } finally {
      if (mounted && generation == _chatGeneration) {
        setState(() => _chatLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<ProfileFollowCounts?>? _loadCounts() {
    final repository = widget.controller.homeFeedRepository;
    return repository is ProfileFollowCountsRepository &&
            widget.controller.profile != null
        ? (repository as ProfileFollowCountsRepository).followCounts(
            widget.profile.id,
          )
        : null;
  }

  Widget _followCounts() => FutureBuilder<ProfileFollowCounts?>(
    future: _counts,
    builder: (context, snapshot) {
      final counts = snapshot.data;
      if (counts == null) return const SizedBox.shrink();
      final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      Widget count(int value, String label) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: format.format(value),
              style: const TextStyle(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: ' ${AppLocalizations.tr(label)}'),
          ],
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            count(
              counts.followers,
              counts.followers == 1 ? 'seguidor' : 'seguidores',
            ),
            count(counts.following, 'seguidos'),
          ],
        ),
      );
    },
  );

  void _updateStatusBar() {
    final past = _scroll.offset >= 78;
    if (past != _coverPastStatusBar) setState(() => _coverPastStatusBar = past);
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (!mounted) return;
    setState(() {
      _counts = _loadCounts();
      _revision++;
    });
  }

  Future<void> _open(String route) async {
    final result = await context.push<Object?>(route);
    if (!mounted) return;
    if (route == '/missions/new' && result is String) {
      await context.push('/missions/$result');
    }
    if (mounted) setState(() => _revision++);
  }

  Future<void> _menu() async {
    final route = await showProfileTools(
      context,
      profile: widget.profile,
      controller: widget.controller,
      admin: _owner && widget.admin,
      messageLabel: !_owner && widget.controller.chatRepository != null
          ? _messageLabel
          : null,
      messageEnabled: _canMessage,
    );
    if (!mounted || route == null) return;
    if (route == '#message') {
      await _messageProfile();
    } else if (route == '#report') {
      await _reportAccount();
    } else if (route == '#settings') {
      await _open('/settings');
    } else if (route == '#showcase') {
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
        if (profile.userType.showcaseKinds.isNotEmpty)
          ProfileShowcasePreview(
            key: ValueKey((profile.id, _revision, 'showcase')),
            controller: widget.controller,
            profile: profile,
            owner: _owner,
            onOpen: _open,
            onSeeAll: _allShowcase,
          ),
        ProfileMissionsPreview(
          key: ValueKey((profile.id, _revision, 'missions')),
          controller: widget.controller,
          ownerId: profile.id,
          onOpen: _open,
          onSeeAll: _allMissions,
        ),
        if (widget.controller.communityRepository != null)
          PostsFeed(
            key: ValueKey((profile.id, _revision, 'posts')),
            controller: widget.controller,
            authorId: profile.id,
            showHeading: false,
            showRefresh: false,
            showEmpty: false,
            profilePresentation: true,
            sectionHeader: Padding(
              key: _postsKey,
              padding: const EdgeInsets.only(top: 22, bottom: 8),
              child: ProfileSectionHeading(
                title: AppLocalizations.tr('Publicaciones'),
                action: _owner ? 'Agregar publicación' : null,
                onAction: _owner ? () => _open('/posts/new') : null,
              ),
            ),
            alwaysShowSectionHeader: _owner,
          ),
      ],
    );
  }

  bool get _hasTourManagement =>
      widget.controller.tourRepository != null &&
      widget.profile.userType != UserType.general;

  bool get _canManageExperiences =>
      _owner &&
      (_hasTourManagement || widget.controller.markerRepository != null);

  Future<void> _manageExperiences() async {
    final routes = [
      if (_hasTourManagement)
        (Icons.panorama_photosphere_outlined, 'Tus recorridos 360°', '/tours'),
      if (widget.controller.markerRepository != null)
        (Icons.image_search_outlined, 'Tus marcadores RA', '/ar-markers'),
    ];
    if (routes.length == 1) {
      await _open(routes.single.$3);
      return;
    }
    final route = await showMareaBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label, route) in routes)
              ListTile(
                leading: Icon(icon),
                title: Text(AppLocalizations.tr(label)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, route),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (mounted && route != null && _owner) await _open(route);
  }

  static final _coverPill = FilledButton.styleFrom(
    backgroundColor: AppColors.profileCanvas,
    foregroundColor: AppColors.brandNavy,
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
      fontFamily: 'NunitoSans',
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
    iconSize: 17,
  );

  bool get _canMessage => !_chatBusy && !_chatLoading && !_awaitingReply;
  String get _messageLabel => _awaitingReply
      ? 'Solicitud enviada'
      : _incomingChat
      ? 'Aceptar solicitud'
      : 'Mensaje';

  bool get _incomingChat =>
      _conversationStatus == 'pending' && _conversationIsIncoming;
  bool get _awaitingReply =>
      _conversationStatus == 'pending' && !_conversationIsIncoming;

  Future<void> _messageProfile() async {
    final repository = widget.controller.chatRepository;
    final account = widget.controller.profile?.id;
    if (repository == null || account == null || _chatBusy || _awaitingReply) {
      return;
    }
    final target = widget.profile.id;
    final conversationId = _conversationId;
    final accepting = _incomingChat && conversationId != null;
    bool isCurrent() =>
        mounted &&
        widget.profile.id == target &&
        widget.controller.profile?.id == account;

    if (_conversationStatus == 'accepted' && conversationId != null) {
      await context.push('/messages/$conversationId');
      return;
    }

    setState(() => _chatBusy = true);
    try {
      if (accepting) {
        await repository.accept(conversationId);
        if (!mounted || !isCurrent()) return;
        setState(() {
          _conversationStatus = 'accepted';
          _conversationIsIncoming = false;
        });
        await context.push('/messages/$conversationId');
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.tr('Enviar solicitud de chat')),
            content: Text(
              AppLocalizations.trTemplate(
                'Podrás escribirle a {name} cuando acepte tu solicitud.',
                {'name': widget.profile.fullName},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.tr('Cancelar')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.tr('Enviar solicitud')),
              ),
            ],
          ),
        );
        if (confirmed != true || !isCurrent()) return;
        final id = await repository.request(target);
        if (!isCurrent()) return;
        setState(() {
          _conversationId = id;
          _conversationStatus = 'pending';
          _conversationIsIncoming = false;
        });
      }
    } catch (error) {
      if (mounted && isCurrent()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(communityError(error))));
      }
    } finally {
      if (isCurrent()) setState(() => _chatBusy = false);
    }
  }

  Widget? _profileActions() {
    final feed = widget.controller.homeFeedRepository;
    final chat = widget.controller.chatRepository;
    if (!_owner &&
        (widget.controller.profile?.id == widget.profile.id ||
            (feed == null && chat == null))) {
      return null;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_owner)
          FilledButton.tonalIcon(
            style: _coverPill,
            onPressed: () => _open('/profile/edit'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(AppLocalizations.tr('Editar perfil')),
          )
        else ...[
          if (feed != null)
            FollowButton(
              repository: feed,
              authorId: widget.profile.id,
              onChanged: () {
                setState(() {
                  _counts = _loadCounts();
                });
                widget.controller.refreshHomeFeed();
              },
              style: _coverPill,
              compact: true,
            ),
          if (chat != null)
            IconButton(
              tooltip: AppLocalizations.tr(_messageLabel),
              onPressed: _canMessage ? _messageProfile : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.profileCanvas,
                foregroundColor: AppColors.brandNavy,
                disabledBackgroundColor: AppColors.profileCanvas,
                disabledForegroundColor: AppColors.textSecondary,
                minimumSize: const Size(48, 48),
              ),
              icon: Badge(
                isLabelVisible: _incomingChat,
                backgroundColor: AppColors.aquaDark,
                child: Icon(
                  _awaitingReply
                      ? Icons.schedule_outlined
                      : Icons.chat_bubble_outline_rounded,
                  size: 20,
                ),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inset = constraints.maxWidth < 600 && widget.feedback == null
          ? MediaQuery.paddingOf(context).top
          : 0.0;
      final statusStyle = _coverPastStatusBar
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light;
      return ColoredBox(
        color: AppColors.profileCanvas,
        child: Stack(
          children: [
            SafeArea(top: inset == 0, bottom: false, child: _body(inset)),
            if (inset > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: inset,
                child: IgnorePointer(
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: statusStyle.copyWith(
                      statusBarColor: Colors.transparent,
                    ),
                    child: ColoredBox(
                      color: _coverPastStatusBar
                          ? AppColors.profileCanvas
                          : const Color(0x40101D30),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _body(double inset) => MareaRefreshIndicator(
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
              topInset: inset,
              followCounts: _followCounts(),
              leading: _owner
                  ? null
                  : ProfileBackButton(
                      fallback: '/explore',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x8C132B4B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
              onSettings: _owner ? () => _open('/settings') : null,
              onMenu: _menu,
              actions: _profileActions(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileVisits(
                key: ValueKey((
                  widget.profile.id,
                  _revision,
                  widget.controller.markerRevision,
                )),
                controller: widget.controller,
                profileId: widget.profile.id,
                onManage: _canManageExperiences ? _manageExperiences : null,
                onOpen: (route) async {
                  await context.push<void>(route);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileAbout(
                profile: widget.profile,
                onEdit: _owner ? () => _open('/profile/edit') : null,
              ),
            ),
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
            24,
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
  );
}
