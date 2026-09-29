import 'package:marea/core/theme/app_depth.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';

String missionDate(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
}

class MissionSurface extends StatelessWidget {
  const MissionSurface({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: AppDepth.raised,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class MissionCover extends StatefulWidget {
  const MissionCover({
    super.key,
    this.path,
    this.bytes,
    this.repository,
    this.height = 190,
  });
  final String? path;
  final Uint8List? bytes;
  final CommunityRepository? repository;
  final double height;
  @override
  State<MissionCover> createState() => _MissionCoverState();
}

class _MissionCoverState extends State<MissionCover> {
  Future<String>? _url;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MissionCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load() {
    _url = widget.path == null
        ? null
        : widget.repository?.missionImageUrl(widget.path!);
  }

  Widget get _fallback => Container(
    color: AppColors.mint,
    alignment: Alignment.center,
    child: const Icon(Icons.waves_rounded, size: 64, color: AppColors.aquaDark),
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: widget.bytes != null
          ? Image.memory(widget.bytes!, fit: BoxFit.cover)
          : _url == null
          ? _fallback
          : FutureBuilder<String>(
              future: _url,
              builder: (_, snapshot) => snapshot.hasData
                  ? Image.network(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback,
                    )
                  : _fallback,
            ),
    ),
  );
}

class MissionSummary extends StatelessWidget {
  const MissionSummary({
    super.key,
    required this.mission,
    this.repository,
    this.bytes,
    this.preview = false,
    this.onTap,
    this.owner = false,
    this.dateLabel,
    this.viewerType,
    this.viewerId,
  });
  final Mission mission;
  final CommunityRepository? repository;
  final Uint8List? bytes;
  final bool preview, owner;
  final String? dateLabel;
  final UserType? viewerType;
  final String? viewerId;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => MissionSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview) ...[
          Text(
            'ASÍ LA VERÁ LA COMUNIDAD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: AppColors.aquaDark,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (mission.imagePath != null || bytes != null) ...[
          MissionCover(
            path: mission.imagePath,
            bytes: bytes,
            repository: repository,
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(
              label: Text(communityCategories[mission.category] ?? 'Otros'),
              visualDensity: VisualDensity.compact,
            ),
            if (!preview)
              Chip(
                label: Text(mission.statusLabel),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mission.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Por ${mission.organizerName ?? 'la comunidad MAREA'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          mission.body,
          maxLines: preview ? 5 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        _line(Icons.place_outlined, mission.location),
        _line(Icons.schedule, dateLabel ?? missionDate(mission.startsAt)),
        _line(
          Icons.people_outline,
          mission.targetType?.databaseValue ?? 'Todos los perfiles',
        ),
        _line(
          Icons.confirmation_number_outlined,
          '${mission.availableSeats} de ${mission.capacity} lugares disponibles',
        ),
        if (owner)
          _line(
            Icons.inbox_outlined,
            '${mission.pendingCount} pendientes · ${mission.acceptedCount} aceptadas',
          ),
        if (!owner && !preview && viewerType != null)
          _line(
            Icons.account_circle_outlined,
            mission.authorId == viewerId
                ? 'Misión que organizas'
                : mission.targetType == null || mission.targetType == viewerType
                ? 'Compatible con tu perfil'
                : 'Busca otro tipo de perfil',
          ),
        if (preview && mission.requirements != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Requisitos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(mission.requirements!),
        ],
        if (preview && mission.conditions != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Qué ofrecemos y condiciones',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(mission.conditions!),
        ],
        if (onTap != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(owner ? 'Gestionar misión' : 'Ver misión'),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.aquaDark),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
