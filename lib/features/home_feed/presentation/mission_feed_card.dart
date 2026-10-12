import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/presentation/mission_social_actions.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/home_feed/presentation/feed_city_label.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/shared/widgets/profile_image.dart';

class MissionFeedCard extends StatefulWidget {
  const MissionFeedCard({
    required this.mission,
    required this.controller,
    required this.saved,
    required this.onSaved,
    required this.onChanged,
    this.author,
    this.stats,
    this.onStats,
    super.key,
  });
  final Mission mission;
  final AppSessionController controller;
  final CommunityProfile? author;
  final bool saved;
  final ValueChanged<bool> onSaved;
  final MissionSocialStats? stats;
  final ValueChanged<MissionSocialStats>? onStats;
  final Future<void> Function() onChanged;
  @override
  State<MissionFeedCard> createState() => _MissionFeedCardState();
}

class _MissionFeedCardState extends State<MissionFeedCard> {
  bool _busy = false, _applying = false, _imageFailed = false;
  late bool _saved = widget.saved;
  Future<String>? _url;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    _imageFailed = false;
    _url = widget.mission.imagePath == null
        ? null
        : widget.controller.communityRepository?.missionImageUrl(
            widget.mission.imagePath!,
          );
  }

  @override
  void didUpdateWidget(MissionFeedCard old) {
    super.didUpdateWidget(old);
    if (old.mission.id != widget.mission.id ||
        old.controller.profile?.id != widget.controller.profile?.id) {
      ++_generation;
    }
    if (!_busy) _saved = widget.saved;
    if (old.mission.imagePath != widget.mission.imagePath ||
        old.controller.communityRepository !=
            widget.controller.communityRepository) {
      _loadImage();
    }
  }

  Future<void> _save(bool value, {bool undo = false}) async {
    if (!mounted || _busy) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      await widget.controller.communityRepository!.setMissionSaved(
        widget.mission.id,
        value,
      );
      if (!mounted || generation != _generation) return;
      setState(() => _saved = value);
      widget.onSaved(value);
      if (!undo) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Misión guardada' : 'Misión retirada de guardados',
            ),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => _save(!value, undo: true),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(communityError(e))));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    await context.push('/missions/${widget.mission.id}');
    if (mounted) await widget.onChanged();
  }

  Future<void> _collaborate() async {
    if (!mounted || _applying) return;
    final mission = widget.mission;
    final profile = widget.controller.profile;
    if (profile == null) return;
    final generation = _generation;
    setState(() => _applying = true);
    try {
      String path;
      if (mission.authorId == profile.id) {
        path = '/missions/${mission.id}/manage';
      } else {
        final applications = await widget.controller.communityRepository!
            .applications(missionId: mission.id);
        if (!mounted ||
            generation != _generation ||
            profile.id != widget.controller.profile?.id) {
          return;
        }
        final existing = applications.any((a) => a.applicantId == profile.id);
        final restriction = mission.applicationRestriction(
          viewerId: profile.id,
          viewerType: profile.userType,
        );
        path =
            '/missions/${mission.id}${existing || restriction != null ? '' : '/apply'}';
      }
      if (!mounted) return;
      await context.push(path);
      if (mounted && generation == _generation) await widget.onChanged();
    } catch (e) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(communityError(e))));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _applying = false);
      }
    }
  }

  void _location() {
    final mission = widget.mission;
    if (mission.coordinates == null) {
      _open();
      return;
    }
    showPostLocationViewer(
      context,
      label: mission.location,
      coordinates: mission.coordinates!,
    );
  }

  Widget _city({bool onPhoto = false}) => FeedCityLabel(
    contentKind: 'mission',
    contentId: widget.mission.id,
    city: widget.mission.city,
    coordinates: widget.mission.coordinates,
    repository: widget.controller.locationRepository,
    onTap: _location,
    color: onPhoto ? Colors.white : AppColors.textSecondary,
  );
  Widget _title({bool onPhoto = false}) => InkWell(
    onTap: _open,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          widget.mission.title,
          style: TextStyle(
            color: onPhoto ? Colors.white : AppColors.brandNavy,
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );

  Widget _calendar() {
    final date = widget.mission.startsAt.toLocal();
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return Semantics(
      label: 'Fecha de misión: ${missionDate(widget.mission.startsAt)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF9F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 18,
              color: AppColors.brandNavy,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  Text(
                    '${two(date.hour)}:${two(date.minute)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.brandNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveControl() => Tooltip(
    message: _saved ? 'Quitar misión de guardados' : 'Guardar misión',
    child: Semantics(
      button: true,
      selected: _saved,
      label: _saved ? 'Quitar misión de guardados' : 'Guardar misión',
      child: InkWell(
        onTap: _busy ? null : () => _save(!_saved),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _saved ? Icons.favorite : Icons.favorite_border,
                size: 21,
                color: AppColors.brandNavy,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _textHero() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: _calendar()),
          ),
          _saveControl(),
        ],
      ),
      const SizedBox(height: 10),
      _title(),
      _city(),
    ],
  );
  Widget _photoHero(String? url) => LayoutBuilder(
    builder: (context, bounds) {
      final painter = TextPainter(
        text: TextSpan(
          text: widget.mission.title,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: bounds.maxWidth - 28);
      final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
      final height = math.max(
        bounds.maxWidth / 1.93,
        math.max(48, painter.height) +
            math.max(48, 24 * scale) +
            38 * scale +
            36,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InkWell(
                onTap: _open,
                child: url == null
                    ? const MareaSkeleton(kind: SkeletonKind.image)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_imageFailed) {
                              setState(() => _imageFailed = true);
                            }
                          });
                          return const SizedBox.shrink();
                        },
                      ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.32, 1],
                      colors: [Colors.transparent, Color(0xC9000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 52,
                child: Align(alignment: Alignment.topLeft, child: _calendar()),
              ),
              Positioned(top: 0, right: 0, child: _saveControl()),
              Positioned(
                left: 14,
                right: 14,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [_title(onPhoto: true), _city(onPhoto: true)],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final controller = widget.controller;
    final own = mission.authorId == controller.profile?.id;
    final cta = TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFC9F8F3),
        foregroundColor: AppColors.brandNavy,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),
      onPressed: _applying ? null : _collaborate,
      icon: Icon(own ? Icons.tune : Icons.handshake_outlined, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _applying
                  ? 'Abriendo…'
                  : own
                  ? 'Gestionar'
                  : mission.isFull
                  ? 'Sin cupo · Ver misión'
                  : 'Me interesa colaborar',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward, size: 14),
        ],
      ),
      iconAlignment: IconAlignment.start,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/people/${mission.authorId}'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: ClipOval(
                                child: ProfileImage(
                                  path: widget.author?.avatarPath,
                                  repository: controller.mediaRepository,
                                  fallback: CircleAvatar(
                                    backgroundColor: AppColors.mint,
                                    child: Text(widget.author?.initials ?? 'M'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.author?.fullName ??
                                        mission.organizerName ??
                                        'MAREA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${missionDate(mission.createdAt)} · Misión',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de misión',
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) => value == 'save'
                        ? _save(!_saved)
                        : value == 'manage'
                        ? _collaborate()
                        : _open(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Ver detalles'),
                      ),
                      if (own)
                        const PopupMenuItem(
                          value: 'manage',
                          child: Text('Gestionar misión'),
                        ),
                      PopupMenuItem(
                        value: 'save',
                        child: Text(
                          _saved ? 'Quitar guardado' : 'Guardar misión',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              FutureBuilder<String>(
                future: _url,
                builder: (_, s) =>
                    mission.imagePath == null || _imageFailed || s.hasError
                    ? _textHero()
                    : _photoHero(s.data),
              ),
              const SizedBox(height: 9),
              Text(
                mission.body,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    communityCategories[mission.category] ?? 'Otros',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.brandNavy,
                    ),
                  ),
                ),
              ),
              if (controller.missionSocialRepository != null &&
                  controller.communityRepository != null)
                MissionSocialActions(
                  mission: mission,
                  repository: controller.missionSocialRepository!,
                  community: controller.communityRepository!,
                  config: AppConfig.fromValues(
                    supabaseUrl: '',
                    supabaseAnonKey: '',
                    publicUrl: controller.publicUrl,
                  ),
                  viewerId: controller.profile?.id,
                  moderator: controller.profile?.role == ProfileRole.admin,
                  stats: widget.stats,
                  onStats: widget.onStats,
                  trailingCTA: cta,
                )
              else
                Align(alignment: Alignment.centerRight, child: cta),
            ],
          ),
        ),
      ),
    );
  }
}
