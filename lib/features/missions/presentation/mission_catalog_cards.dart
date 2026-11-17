import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';

typedef MissionBookmark = ({bool saved, VoidCallback? onPressed});

const _metadataColor = Color(0xFF536078);
const _featuredSurface = Color(0xFFE3F5F5);
const _featuredBorder = Color(0xFFCEE8EC);

class FeaturedMissionCard extends StatelessWidget {
  const FeaturedMissionCard({
    required this.mission,
    required this.onOpen,
    this.resolveImage,
    this.bookmark,
    super.key,
  });

  final Mission mission;
  final VoidCallback onOpen;
  final Future<String> Function(String)? resolveImage;
  final MissionBookmark? bookmark;

  @override
  Widget build(BuildContext context) {
    final info = _MissionCardInfo(context, mission);
    final text = Theme.of(context).textTheme;
    final cover = Stack(
      children: [
        Positioned.fill(
          child: _MissionCover(mission: mission, resolveImage: resolveImage),
        ),
        if (bookmark case final value?)
          PositionedDirectional(
            top: 2,
            end: 2,
            child: _Bookmark(value: value, onCover: true),
          ),
      ],
    );
    final description = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Misión destacada',
              style: text.labelSmall?.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: .35,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _MissionTitle(info.title, featured: true),
          const SizedBox(height: 7),
          _MissionSchedule(info: info),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                textStyle: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('Ver misión')),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return _MissionSurface(
      color: _featuredSurface,
      borderColor: _featuredBorder,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 295 || _largeText(context)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  description,
                  SizedBox(height: 112, child: cover),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: (constraints.maxWidth * .41).clamp(116, 210),
                    child: cover,
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 140),
                      child: description,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FeaturedMissionEmptyCard extends StatelessWidget {
  const FeaturedMissionEmptyCard({required this.hasMissions, super.key});

  final bool hasMissions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _MissionSurface(
      color: _featuredSurface,
      borderColor: _featuredBorder,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(15, 9, 7, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Aún no hay una destacada',
                      style: text.titleMedium?.copyWith(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasMissions
                        ? 'Descubre las misiones disponibles más abajo.'
                        : 'Vuelve pronto para ver nuevas convocatorias.',
                    style: text.bodySmall?.copyWith(color: _metadataColor),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/missions/fiebrin-explorador.webp',
              width: _largeText(context) ? 76 : 102,
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyMissionCard extends StatelessWidget {
  const NearbyMissionCard({
    required this.mission,
    required this.nearby,
    required this.onOpen,
    this.resolveImage,
    this.bookmark,
    super.key,
  });

  final Mission mission;
  final NearbyMission nearby;
  final Future<String> Function(String)? resolveImage;
  final MissionBookmark? bookmark;
  final VoidCallback onOpen;

  static const imageHeight = 94.0;
  static const height = 192.0;

  @override
  Widget build(BuildContext context) {
    final info = _MissionCardInfo(context, mission, nearby);
    return _MissionSurface(
      child: _MissionCardTarget(
        info: info,
        bookmark: bookmark,
        bookmarkOnCover: true,
        onOpen: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              child: _MissionCover(
                mission: mission,
                resolveImage: resolveImage,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryTag(category: mission.category),
                  const SizedBox(height: 4),
                  _MissionTitle(info.title),
                  const SizedBox(height: 4),
                  if (info.hasLocation) _MissionLocation(info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissionCatalogCard extends StatelessWidget {
  const MissionCatalogCard({
    required this.mission,
    required this.onOpen,
    this.resolveImage,
    this.bookmark,
    this.distance,
    super.key,
  });

  final Mission mission;
  final Future<String> Function(String)? resolveImage;
  final MissionBookmark? bookmark;
  final NearbyMission? distance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final info = _MissionCardInfo(context, mission, distance);
    final large = _largeText(context);
    return _MissionSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bookmarkOnCover = large || constraints.maxWidth < 310;
          final imageWidth = large
              ? 66.0
              : (constraints.maxWidth * .31).clamp(80.0, 124.0);
          return _MissionCardTarget(
            info: info,
            bookmark: bookmark,
            bookmarkOnCover: bookmarkOnCover,
            bookmarkAtStart: bookmarkOnCover,
            onOpen: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: bookmarkOnCover
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: imageWidth,
                    height: imageWidth + 2,
                    child: _MissionCover(
                      mission: mission,
                      resolveImage: resolveImage,
                      alignment: bookmarkOnCover && bookmark != null
                          ? const Alignment(0, .65)
                          : Alignment.center,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 6, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: bookmark == null || bookmarkOnCover ? 0 : 36,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryTag(category: mission.category),
                                const SizedBox(height: 4),
                                _MissionTitle(info.title),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (info.hasLocation) ...[
                            _MissionLocation(info),
                            const SizedBox(height: 3),
                          ],
                          _MissionSchedule(info: info),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) > 20;

class _MissionSurface extends StatelessWidget {
  const _MissionSurface({
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
  });

  final Widget child;
  final Color color, borderColor;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      side: BorderSide(color: borderColor),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _MissionCardTarget extends StatelessWidget {
  const _MissionCardTarget({
    required this.info,
    required this.bookmark,
    required this.onOpen,
    required this.child,
    required this.bookmarkOnCover,
    this.bookmarkAtStart = false,
  });

  final _MissionCardInfo info;
  final MissionBookmark? bookmark;
  final VoidCallback onOpen;
  final bool bookmarkOnCover, bookmarkAtStart;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeSemantics(child: child),
      Positioned.fill(
        child: Semantics(
          button: true,
          label: 'Abrir ${info.title}',
          hint: info.semanticDetail,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return AppColors.brandNavy.withValues(alpha: .18);
                }
                return null;
              }),
              onTap: onOpen,
            ),
          ),
        ),
      ),
      if (bookmark case final value?)
        PositionedDirectional(
          top: 2,
          start: bookmarkAtStart ? 3 : null,
          end: bookmarkAtStart ? null : 2,
          child: _Bookmark(value: value, onCover: bookmarkOnCover),
        ),
    ],
  );
}

class _MissionCardInfo {
  _MissionCardInfo(BuildContext context, this.mission, [NearbyMission? nearby])
    : category = communityCategories[mission.category] ?? mission.category,
      title = mission.title.trim().isNotEmpty
          ? mission.title.trim()
          : mission.body.trim(),
      location = _locationLabel(mission),
      date = _startLabel(context, mission.startsAt),
      distance = nearby == null
          ? null
          : (
              label: _distanceLabel(context, nearby),
              approximate: nearby.approximate,
            );

  final Mission mission;
  final String title, category, location, date;
  final ({String label, bool approximate})? distance;

  bool get available => mission.isOpen && !mission.isExpired && !mission.isFull;
  String get availability {
    if (!available) return mission.statusLabel;
    final seats = mission.availableSeats;
    return seats == 1 ? '1 cupo disponible' : '$seats cupos disponibles';
  }

  bool get hasLocation => location.isNotEmpty || distance != null;

  String get semanticDetail => [
    category,
    'Inicia $date',
    if (location.isNotEmpty) location,
    if (distance case final value?)
      value.approximate ? 'Distancia aproximada ${value.label}' : value.label,
    availability,
  ].join(', ');

  static String _locationLabel(Mission mission) {
    final label = mission.location.trim();
    if (label.toLowerCase().startsWith('ubicación seleccionada (')) {
      return mission.city?.name ?? 'Punto en el mapa';
    }
    return label.isEmpty ? mission.city?.name ?? '' : label;
  }

  static String _startLabel(BuildContext context, DateTime startsAt) {
    final date = startsAt.toLocal();
    final local = MaterialLocalizations.of(context);
    return date.year == DateTime.now().year
        ? local.formatShortMonthDay(date)
        : local.formatCompactDate(date);
  }

  static String _distanceLabel(BuildContext context, NearbyMission distance) {
    final meters = distance.meters;
    return meters < 1000
        ? '${MaterialLocalizations.of(context).formatDecimal(meters.round())} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _MissionTitle extends StatelessWidget {
  const _MissionTitle(this.title, {this.featured = false});
  final String title;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final large = _largeText(context);
    return Text(
      title,
      maxLines: large ? null : (featured ? 3 : 2),
      overflow: large ? null : TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.brandNavy,
        fontSize: featured ? 20 : 17,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -.2,
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forProfileInterest(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: visual.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          communityCategories[category] ?? category,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w800,
            height: 1.18,
            letterSpacing: .1,
          ),
        ),
      ),
    );
  }
}

TextStyle? _metadataStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodySmall
    ?.copyWith(color: _metadataColor, height: 1.2, letterSpacing: 0);

class _MissionLocation extends StatelessWidget {
  const _MissionLocation(this.info);
  final _MissionCardInfo info;

  @override
  Widget build(BuildContext context) {
    final large = _largeText(context);
    final style = _metadataStyle(context);
    final distance = info.distance;
    final distanceText = distance == null
        ? null
        : distance.approximate
        ? '≈ ${distance.label}'
        : distance.label;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: _metadataColor),
        const SizedBox(width: 4),
        Flexible(
          child: large
              ? Text(
                  [
                    if (info.location.isNotEmpty) info.location,
                    ?distanceText,
                  ].join(' · '),
                  style: style,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (info.location.isNotEmpty)
                      Flexible(
                        child: Text(
                          info.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                    if (distanceText != null)
                      Text(
                        info.location.isEmpty
                            ? distanceText
                            : ' · $distanceText',
                        style: style,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MissionSchedule extends StatelessWidget {
  const _MissionSchedule({required this.info});
  final _MissionCardInfo info;

  @override
  Widget build(BuildContext context) {
    final style = _metadataStyle(context);
    return Wrap(
      spacing: 8,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: _metadataColor,
            ),
            const SizedBox(width: 4),
            Flexible(child: Text('Inicia ${info.date}', style: style)),
          ],
        ),
        Text(
          info.availability,
          style: style?.copyWith(
            color: info.available ? const Color(0xFF086449) : null,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.value, required this.onCover});

  final MissionBookmark value;
  final bool onCover;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: value.saved,
    child: Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onCover)
            Ink(
              width: 34,
              height: 34,
              decoration: const ShapeDecoration(
                color: AppColors.surface,
                shape: CircleBorder(),
              ),
            ),
          IconButton(
            tooltip: value.saved ? 'Quitar de guardados' : 'Guardar',
            onPressed: value.onPressed,
            icon: Icon(
              value.saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 21,
            ),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              minimumSize: const Size.square(48),
              foregroundColor: AppColors.brandNavy,
              disabledForegroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissionCover extends StatefulWidget {
  const _MissionCover({
    required this.mission,
    required this.resolveImage,
    this.alignment = Alignment.center,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppRadius.small),
    ),
  });

  final Mission mission;
  final Future<String> Function(String)? resolveImage;
  final Alignment alignment;
  final BorderRadius borderRadius;

  @override
  State<_MissionCover> createState() => _MissionCoverState();
}

class _MissionCoverState extends State<_MissionCover> {
  late Future<String>? _url = _resolve();

  Future<String>? _resolve() {
    final path = widget.mission.imagePath?.trim();
    return path == null || path.isEmpty
        ? null
        : widget.resolveImage?.call(path);
  }

  @override
  void didUpdateWidget(covariant _MissionCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.imagePath != widget.mission.imagePath ||
        oldWidget.resolveImage != widget.resolveImage) {
      _url = _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forProfileInterest(widget.mission.category);
    final fallback = ColoredBox(
      color: visual.color,
      child: Align(
        alignment: widget.alignment,
        child: Icon(visual.icon, color: visual.accent, size: 26),
      ),
    );
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: _url == null
          ? fallback
          : FutureBuilder<String>(
              future: _url,
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done ||
                    url == null ||
                    url.isEmpty) {
                  return fallback;
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  frameBuilder: (context, child, frame, synchronous) =>
                      frame == null && !synchronous ? fallback : child,
                  errorBuilder: (_, _, _) => fallback,
                );
              },
            ),
    );
  }
}
