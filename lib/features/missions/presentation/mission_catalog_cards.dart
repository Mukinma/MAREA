import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_depth.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';

typedef MissionBookmark = ({bool saved, VoidCallback? onPressed});

class NearbyMissionCard extends StatelessWidget {
  const NearbyMissionCard({
    required this.mission,
    required this.onOpen,
    this.resolveImage,
    required this.nearby,
    this.bookmark,
    super.key,
  });

  final Mission mission;
  final NearbyMission nearby;
  final Future<String> Function(String)? resolveImage;
  final MissionBookmark? bookmark;
  final VoidCallback onOpen;

  static double height(BuildContext context) =>
      126.0 +
      2 * (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0, 48);

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forProfileInterest(mission.category);
    final location = _distanceLabel(context, nearby);
    final large = MediaQuery.textScalerOf(context).scale(16) > 22;
    final title = mission.title.trim().isEmpty
        ? mission.body.trim()
        : mission.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppDepth.floating,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(
              path: mission.imagePath,
              resolve: resolveImage,
              color: Color.alphaBlend(
                AppColors.brandNavy.withValues(alpha: .48),
                visual.accent,
              ),
              icon: visual.icon,
              iconColor: visual.color,
              iconAlignment: const Alignment(0, -.42),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x220B255E),
                    Color(0xAB041734),
                    Color(0xF0041734),
                  ],
                  stops: [0, .27, .56, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: CustomPaint(
                size: const Size(92, 29),
                painter: _CornerWave(visual.accent),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (large
                                  ? Theme.of(context).textTheme.titleSmall
                                  : Theme.of(context).textTheme.titleMedium)
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 7,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryPill(category: mission.category),
                        _MissionFact(
                          icon: Icons.location_on_outlined,
                          label: location,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: _OpenCard(
                title: title,
                detail: _distanceLabel(context, nearby, spoken: true),
                onOpen: onOpen,
                light: true,
              ),
            ),
            if (bookmark case final action?)
              Positioned(
                top: 3,
                right: 3,
                child: _Bookmark(value: action, light: true),
              ),
          ],
        ),
      ),
    );
  }
}

class MissionCatalogCard extends StatefulWidget {
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
  State<MissionCatalogCard> createState() => _MissionCatalogCardState();
}

class _MissionCatalogCardState extends State<MissionCatalogCard> {
  bool _coverFailed = false;

  @override
  void didUpdateWidget(covariant MissionCatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mission.imagePath != oldWidget.mission.imagePath ||
        widget.resolveImage != oldWidget.resolveImage) {
      _coverFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final visual = CategoryVisuals.forProfileInterest(mission.category);
    final category = communityCategories[mission.category] ?? mission.category;
    final body = mission.body.trim();
    final title = mission.title.trim().isEmpty ? body : mission.title.trim();
    final theme = Theme.of(context).textTheme;
    final start = mission.startsAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final shortStart = start.year == DateTime.now().year
        ? localizations.formatShortMonthDay(start)
        : localizations.formatCompactDate(start);
    final date = 'Inicia $shortStart';
    final location = mission.location.trim();
    final distance = widget.distance;
    final available = mission.isOpen && !mission.isExpired && !mission.isFull;
    final availability = available
        ? mission.availableSeats == 1
              ? '1 cupo disponible'
              : '${mission.availableSeats} cupos disponibles'
        : mission.statusLabel;
    final large = MediaQuery.textScalerOf(context).scale(16) > 21;
    final path = mission.imagePath;
    final hasCover =
        !_coverFailed &&
        widget.resolveImage != null &&
        path?.trim().isNotEmpty == true;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  if (hasCover) ...[
                    SizedBox(
                      width: large ? 54 : 92,
                      height: large ? 68 : 91,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _Cover(
                          path: path,
                          resolve: widget.resolveImage,
                          color: visual.color,
                          icon: visual.icon,
                          iconColor: visual.accent,
                          onUnavailable: () {
                            if (mounted &&
                                widget.mission.imagePath == path &&
                                !_coverFailed) {
                              setState(() => _coverFailed = true);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: widget.bookmark == null ? 0 : 39,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: large ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.titleMedium?.copyWith(
                                  color: AppColors.brandNavy,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                ),
                              ),
                              if (body.isNotEmpty && body != title)
                                Text(
                                  body,
                                  maxLines: large ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: EdgeInsets.only(
                            right: widget.bookmark == null ? 0 : 31,
                          ),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _CategoryPill(category: mission.category),
                              _MissionPill(
                                icon: available ? Icons.circle : null,
                                iconSize: 7,
                                label: availability,
                                background: available
                                    ? const Color(0xFFDBF6E8)
                                    : AppColors.mist,
                                foreground: available
                                    ? const Color(0xFF00673C)
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 9,
                          runSpacing: 3,
                          children: [
                            _MissionFact(
                              icon: Icons.calendar_today_outlined,
                              label: date,
                            ),
                            if (distance != null || location.isNotEmpty)
                              _MissionFact(
                                icon: Icons.location_on_outlined,
                                label: [
                                  if (location.isNotEmpty) location,
                                  if (distance != null)
                                    _distanceLabel(context, distance),
                                ].join(' · '),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: _OpenCard(
              title: title,
              detail: [
                if (body.isNotEmpty && body != title) body,
                category,
                'Inicia ${missionDate(mission.startsAt)}',
                if (location.isNotEmpty) location,
                if (distance != null)
                  _distanceLabel(context, distance, spoken: true),
                availability,
              ].join(', '),
              onOpen: widget.onOpen,
            ),
          ),
          if (widget.bookmark case final action?)
            Positioned(top: 0, right: 1, child: _Bookmark(value: action)),
        ],
      ),
    );
  }
}

String _distanceLabel(
  BuildContext context,
  NearbyMission distance, {
  bool spoken = false,
}) {
  final meters = distance.meters;
  final label = meters < 1000
      ? '${MaterialLocalizations.of(context).formatDecimal(meters.round())} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';
  if (!distance.approximate) return label;
  return spoken ? 'Distancia aproximada $label' : '≈ $label';
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forProfileInterest(category);
    return _MissionPill(
      icon: visual.icon,
      label: communityCategories[category] ?? category,
      background: visual.color,
      foreground: AppColors.brandNavy,
    );
  }
}

class _MissionPill extends StatelessWidget {
  const _MissionPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconSize = 13,
  });

  final String label;
  final Color background, foreground;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: iconSize),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissionFact extends StatelessWidget {
  const _MissionFact({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ),
    ],
  );
}

class _OpenCard extends StatelessWidget {
  const _OpenCard({
    required this.title,
    required this.detail,
    required this.onOpen,
    this.light = false,
  });

  final String title, detail;
  final VoidCallback onOpen;
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: detail.isEmpty ? 'Abrir $title' : 'Abrir $title, $detail',
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onOpen,
        overlayColor: WidgetStatePropertyAll(
          (light ? Colors.white : AppColors.brandNavy).withValues(alpha: .12),
        ),
      ),
    ),
  );
}

class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.value, this.light = false});

  final MissionBookmark value;
  final bool light;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(1),
    child: Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (light)
            Ink(
              width: 34,
              height: 34,
              decoration: ShapeDecoration(
                color: AppColors.brandNavy.withValues(alpha: .64),
                shape: const CircleBorder(),
              ),
            ),
          Semantics(
            selected: value.saved,
            child: IconButton(
              tooltip: value.saved ? 'Quitar de guardados' : 'Guardar',
              onPressed: value.onPressed,
              icon: Icon(
                value.saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 22,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                foregroundColor: light ? Colors.white : AppColors.brandNavy,
                disabledForegroundColor: light
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Cover extends StatefulWidget {
  const _Cover({
    required this.path,
    required this.resolve,
    required this.color,
    required this.icon,
    required this.iconColor,
    this.iconAlignment = Alignment.center,
    this.onUnavailable,
  });

  final String? path;
  final Future<String> Function(String)? resolve;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final Alignment iconAlignment;
  final VoidCallback? onUnavailable;

  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  late Future<String>? _url = _resolve();

  Future<String>? _resolve() {
    final path = widget.path?.trim();
    return path == null || path.isEmpty ? null : widget.resolve?.call(path);
  }

  @override
  void didUpdateWidget(covariant _Cover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.resolve != widget.resolve) {
      _url = _resolve();
    }
  }

  void _reportUnavailable() {
    final request = _url;
    if (widget.onUnavailable == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && request == _url) widget.onUnavailable?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: widget.color,
      child: Align(
        alignment: widget.iconAlignment,
        child: Icon(widget.icon, color: widget.iconColor, size: 26),
      ),
    );
    if (_url == null) return fallback;
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) return fallback;
        if (url == null || url.isEmpty) {
          _reportUnavailable();
          return fallback;
        }
        return Image.network(
          url,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) =>
              frame == null && !synchronous ? fallback : child,
          errorBuilder: (_, _, _) {
            _reportUnavailable();
            return fallback;
          },
        );
      },
    );
  }
}

class _CornerWave extends CustomPainter {
  const _CornerWave(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * .45,
        size.height * .94,
        size.width * .46,
        0,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .54));
  }

  @override
  bool shouldRepaint(covariant _CornerWave oldDelegate) =>
      oldDelegate.color != color;
}
