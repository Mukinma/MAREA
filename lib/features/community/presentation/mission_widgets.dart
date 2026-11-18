import 'dart:typed_data';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/localization/on_device_post_translator.dart';
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

class MissionTranslationAction extends StatefulWidget {
  const MissionTranslationAction({
    super.key,
    required this.content,
    required this.onChanged,
    this.translator,
  });

  final Map<String, String> content;
  final ValueChanged<Map<String, String>?> onChanged;
  final PostContentTranslator? translator;

  @override
  State<MissionTranslationAction> createState() =>
      _MissionTranslationActionState();
}

class _MissionTranslationActionState extends State<MissionTranslationAction> {
  static final _onDeviceTranslator = MlKitPostContentTranslator();

  PostContentTranslator get _translator =>
      widget.translator ?? _onDeviceTranslator;

  Map<String, String>? _translatedContent;
  String? _targetLanguage, _error;
  bool _translating = false, _sameLanguage = false;
  int _generation = 0;

  bool _sameContent(Map<String, String> first, Map<String, String> second) =>
      first.length == second.length &&
      first.entries.every((entry) => second[entry.key] == entry.value);

  @override
  void didUpdateWidget(covariant MissionTranslationAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameContent(oldWidget.content, widget.content)) {
      _generation++;
      _translatedContent = null;
      _sameLanguage = false;
      _error = null;
      _translating = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_targetLanguage != null && _targetLanguage != language) {
      _generation++;
      _translatedContent = null;
      _sameLanguage = false;
      _error = null;
      _translating = false;
    }
    _targetLanguage = language;
  }

  Future<void> _toggleTranslation() async {
    final translator = _translator;
    if (!translator.isSupported || _translating) return;
    if (_translatedContent != null || _sameLanguage) {
      setState(() {
        _translatedContent = null;
        _sameLanguage = false;
        _error = null;
      });
      widget.onChanged(null);
      return;
    }

    final generation = ++_generation;
    final targetLanguage = Localizations.localeOf(context).languageCode;
    setState(() {
      _translating = true;
      _error = null;
    });
    try {
      final translated = <String, String>{};
      for (final entry in widget.content.entries) {
        if (entry.value.trim().isEmpty) {
          translated[entry.key] = entry.value;
          continue;
        }
        final result = await translator.translate(
          title: entry.value,
          body: '',
          targetLanguage: targetLanguage,
        );
        translated[entry.key] = result.title;
      }
      if (!mounted || generation != _generation) return;
      final unchanged = _sameContent(widget.content, translated);
      setState(() {
        _translatedContent = unchanged ? null : translated;
        _sameLanguage = unchanged;
      });
      widget.onChanged(unchanged ? null : translated);
    } on PostTranslationException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = AppLocalizations.tr(switch (error.failure) {
          PostTranslationFailure.languageUndetermined =>
            'No pudimos identificar el idioma de esta misión.',
          PostTranslationFailure.unsupportedLanguage =>
            'Todavía no podemos traducir misiones en este idioma.',
          PostTranslationFailure.modelUnavailable =>
            'No se pudo descargar el modelo de traducción. Conéctate a internet e inténtalo de nuevo.',
        }),
      );
    } on Exception {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = AppLocalizations.tr(
          'No se pudo traducir la misión. Revisa tu conexión e inténtalo de nuevo.',
        ),
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _translating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_translator.isSupported) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: _translating ? null : _toggleTranslation,
          icon: _translating
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate_rounded, size: 18),
          label: Text(
            AppLocalizations.tr(
              _translatedContent != null ? 'Ver original' : 'Traducir misión',
            ),
          ),
        ),
        if (_sameLanguage)
          Text(
            AppLocalizations.tr(
              'Esta misión ya está en el idioma seleccionado.',
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
      ],
    );
  }
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

class MissionSummary extends StatefulWidget {
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
  State<MissionSummary> createState() => _MissionSummaryState();
}

class _MissionSummaryState extends State<MissionSummary> {
  Map<String, String>? _translatedContent;
  String? _translationLanguage;

  @override
  void didUpdateWidget(covariant MissionSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.title != widget.mission.title ||
        oldWidget.mission.body != widget.mission.body ||
        oldWidget.mission.requirements != widget.mission.requirements ||
        oldWidget.mission.conditions != widget.mission.conditions) {
      _translatedContent = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_translationLanguage != null && _translationLanguage != language) {
      _translatedContent = null;
    }
    _translationLanguage = language;
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final preview = widget.preview;
    final owner = widget.owner;
    final viewerType = widget.viewerType;
    final viewerId = widget.viewerId;
    final dateLabel = widget.dateLabel;
    final onTap = widget.onTap;
    final translated = _translatedContent ?? const <String, String>{};
    final content = {
      'title': mission.title,
      'body': preview ? mission.body : '',
      if (preview && mission.requirements != null)
        'requirements': mission.requirements!,
      if (preview && mission.conditions != null)
        'conditions': mission.conditions!,
    };
    return MissionSurface(
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
          if (mission.imagePath != null || widget.bytes != null) ...[
            MissionCover(
              path: mission.imagePath,
              bytes: widget.bytes,
              repository: widget.repository,
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
                _badge(
                  AppLocalizations.tr(mission.statusLabel),
                  AppColors.mist,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            translated['title'] ?? mission.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          MissionTranslationAction(
            content: content,
            onChanged: (value) => setState(() => _translatedContent = value),
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
                  : mission.targetType == null ||
                        mission.targetType == viewerType
                  ? AppLocalizations.tr('Compatible con tu perfil')
                  : AppLocalizations.tr('Busca otro tipo de perfil'),
            ),
          if (preview) ...[
            const Divider(height: 28),
            Text(translated['body'] ?? mission.body),
            const SizedBox(height: 14),
            _line(Icons.person_outline, missionTargetLabel(mission.targetType)),
            if (mission.requirements != null) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.tr('Requisitos'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                translated['requirements'] ?? mission.requirements!,
              ),
            ],
            if (mission.conditions != null) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.tr('Qué ofrecemos y condiciones'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(translated['conditions'] ?? mission.conditions!),
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
  }
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
