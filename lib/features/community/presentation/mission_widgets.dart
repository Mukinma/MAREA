import 'dart:typed_data';
import 'package:marea/core/localization/app_localizations.dart';
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

String missionCategoryLabel(String category) =>
    AppLocalizations.tr(communityCategories[category] ?? 'Otros');

String missionTargetLabel(UserType? target) => target == null
    ? AppLocalizations.tr('Todos los perfiles')
    : AppLocalizations.tr(target.databaseValue);

String missionCompensationLocalizedLabel(String? type, int? cents) =>
    switch (type) {
      'unpaid' => AppLocalizations.tr('Sin pago'),
      'negotiable' => AppLocalizations.tr('Compensación por acordar'),
      'paid' when cents != null && cents > 0 && cents <= 9999999900 =>
        AppLocalizations.trTemplate('{amount} MXN por participante', {
          'amount': '\$${(cents / 100).toStringAsFixed(2)}',
        }),
      _ => AppLocalizations.tr('Compensación no indicada'),
    };

class MissionSurface extends StatelessWidget {
  const MissionSurface({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: EdgeInsets.all(padding), child: child),
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
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview) ...[
          Text(
            AppLocalizations.tr('ASÍ LA VERÁ LA COMUNIDAD'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.aquaDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (mission.imagePath != null || bytes != null) ...[
          MissionCover(
            path: mission.imagePath,
            bytes: bytes,
            repository: repository,
            height: preview ? 220 : 150,
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(missionCategoryLabel(mission.category), AppColors.mint),
            if (!preview)
              _badge(AppLocalizations.tr(mission.statusLabel), AppColors.mist),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          mission.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.trTemplate('Por {organizer}', {
            'organizer':
                mission.organizerName ??
                AppLocalizations.tr('la comunidad MAREA'),
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _line(
          Icons.schedule_outlined,
          dateLabel ?? missionDate(mission.startsAt),
        ),
        _line(Icons.place_outlined, mission.location),
        _line(
          Icons.payments_outlined,
          missionCompensationLocalizedLabel(
            mission.compensationType,
            mission.compensationAmountCents,
          ),
        ),
        _line(
          Icons.people_outline,
          AppLocalizations.trTemplate(
            mission.availableSeats == 1
                ? '{available} de {total} lugar disponible'
                : '{available} de {total} lugares disponibles',
            {
              'available': '${mission.availableSeats}',
              'total': '${mission.capacity}',
            },
          ),
        ),
        if (owner)
          _line(
            Icons.inbox_outlined,
            AppLocalizations.trTemplate(
              '{pending} pendientes · {accepted} aceptadas',
              {
                'pending': '${mission.pendingCount}',
                'accepted': '${mission.acceptedCount}',
              },
            ),
          ),
        if (!owner && !preview && viewerType != null)
          _line(
            Icons.account_circle_outlined,
            mission.authorId == viewerId
                ? AppLocalizations.tr('Misión que organizas')
                : mission.targetType == null || mission.targetType == viewerType
                ? AppLocalizations.tr('Compatible con tu perfil')
                : AppLocalizations.tr('Busca otro tipo de perfil'),
          ),
        if (preview) ...[
          const Divider(height: 28),
          Text(mission.body),
          const SizedBox(height: 14),
          _line(Icons.person_outline, missionTargetLabel(mission.targetType)),
          if (mission.requirements != null) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr('Requisitos'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(mission.requirements!),
          ],
          if (mission.conditions != null) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr('Qué ofrecemos y condiciones'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(mission.conditions!),
          ],
        ],
        if (onTap != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                owner
                    ? AppLocalizations.tr('Gestionar misión')
                    : AppLocalizations.tr('Ver misión'),
              ),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.brandNavy,
      ),
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
