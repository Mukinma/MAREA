import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

typedef ProfileOpenRoute = Future<void> Function(String route);

class ProfileShowcasePreview extends StatelessWidget {
  const ProfileShowcasePreview({
    required this.controller,
    required this.profile,
    required this.owner,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });
  final AppSessionController controller;
  final CommunityProfile profile;
  final bool owner;
  final ProfileOpenRoute onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final repository = controller.showcaseRepository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(
          title: profile.userType.showcaseLabel,
          action: repository == null ? null : 'Ver todo',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 5),
        if (repository == null)
          const _ProfileEmpty(
            'El contenido no está disponible en este momento.',
          )
        else
          CommunityLoad<List<ShowcaseItem>>(
            key: ValueKey('showcase-data:${profile.id}:$owner'),
            load: () =>
                repository.items(ownerId: profile.id, management: owner),
            builder: (page, reload) {
              final items = page
                  .where(
                    (item) =>
                        item.ownerId == profile.id &&
                        (owner ||
                            item.status == ShowcaseStatus.published &&
                                item.available &&
                                !item.hidden),
                  )
                  .toList();
              if (items.isEmpty) {
                return const _ProfileEmpty(
                  'Este perfil aún no tiene contenido para mostrar.',
                );
              }
              final height = MediaQuery.textScalerOf(context).scale(12) > 16
                  ? 222.0
                  : 124.0;
              return SizedBox(
                height: height,
                child: ListView.separated(
                  key: ValueKey('profile-showcase-${profile.id}'),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SizedBox(
                      width: height == 124 ? 112 : 168,
                      child: Material(
                        color: const Color(0xFFE4F3F5),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await onOpen('/showcase/${item.id}');
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (item.imagePaths.isNotEmpty)
                                ShowcasePhoto(
                                  path: item.imagePaths.first,
                                  repository: repository,
                                  height: height,
                                )
                              else
                                const Center(
                                  child: Icon(
                                    Icons.photo_outlined,
                                    size: 38,
                                    color: Color(0xFF8BB3BF),
                                  ),
                                ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [.2, 1],
                                    colors: [
                                      Colors.transparent,
                                      Color(0xDD07345C),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (owner &&
                                        item.status != ShowcaseStatus.published)
                                      Text(
                                        item.status.label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    if (item.price != null)
                                      Text(
                                        '\$${item.price!.toStringAsFixed(2)} MXN',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (item.body.trim().isNotEmpty)
                                      Text(
                                        item.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          height: 1.15,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class ProfileMissionsPreview extends StatelessWidget {
  const ProfileMissionsPreview({
    required this.controller,
    required this.ownerId,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });
  final AppSessionController controller;
  final String ownerId;
  final ProfileOpenRoute onOpen;
  final VoidCallback onSeeAll;
  @override
  Widget build(BuildContext context) {
    final repository = controller.communityRepository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(
          title: 'Misiones destacadas',
          action: repository == null ? null : 'Ver todas',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 5),
        if (repository == null)
          const _ProfileEmpty(
            'Las misiones no están disponibles en este momento.',
          )
        else
          CommunityLoad<List<Mission>>(
            key: ValueKey('mission-data:$ownerId'),
            load: () => repository.missions(authorId: ownerId),
            builder: (page, reload) {
              final missions = page
                  .where(
                    (mission) => mission.authorId == ownerId && !mission.hidden,
                  )
                  .take(3)
                  .toList();
              if (missions.isEmpty) {
                return const _ProfileEmpty(
                  'Este perfil aún no ha publicado misiones.',
                );
              }
              return Column(
                children: [
                  for (final mission in missions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onOpen('/missions/${mission.id}'),
                          child: SizedBox(
                            height:
                                MediaQuery.textScalerOf(context).scale(12) > 16
                                ? 184
                                : 96,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 88,
                                  child: MissionCover(
                                    path: mission.imagePath,
                                    repository: repository,
                                    height:
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(12) >
                                            16
                                        ? 184
                                        : 96,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F8EF),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            mission.statusLabel,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF138E76),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mission.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                            color: Color(0xFF07345C),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          mission.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            height: 1.1,
                                            color: Color(0xFF607C98),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFDDF7FA),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF07345C),
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

Future<void> showProfileShowcase(
  BuildContext context, {
  required AppSessionController controller,
  required CommunityProfile profile,
  required bool owner,
  required ProfileOpenRoute onOpen,
}) => _showProfileList(
  context,
  title: profile.userType.showcaseLabel,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (owner) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in profile.userType.showcaseKinds)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onOpen('/showcase/new?kind=${kind.name}');
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(kind.action),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      ShowcaseList(
        controller: controller,
        ownerId: profile.id,
        management: owner,
      ),
    ],
  ),
);

Future<void> showProfileMissions(
  BuildContext context, {
  required CommunityRepository repository,
  required String ownerId,
  required bool owner,
  required ProfileOpenRoute onOpen,
}) => _showProfileList(
  context,
  title: 'Misiones del perfil',
  child: _ProfileMissionsList(
    repository: repository,
    ownerId: ownerId,
    owner: owner,
    onOpen: onOpen,
  ),
);

Future<void> _showProfileList(
  BuildContext context, {
  required String title,
  required Widget child,
}) async {
  await showMareaBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF07345C),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar lista',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileMissionsList extends StatefulWidget {
  const _ProfileMissionsList({
    required this.repository,
    required this.ownerId,
    required this.owner,
    required this.onOpen,
  });
  final CommunityRepository repository;
  final String ownerId;
  final bool owner;
  final ProfileOpenRoute onOpen;
  @override
  State<_ProfileMissionsList> createState() => _ProfileMissionsListState();
}

class _ProfileMissionsListState extends State<_ProfileMissionsList> {
  final _items = <Mission>[];
  int _offset = 0;
  bool _loading = true, _more = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.missions(
        authorId: widget.ownerId,
        offset: reset ? 0 : _offset,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items.clear();
          _offset = 0;
        }
        _offset += page.length;
        _more = page.length == 30;
        _items.addAll(
          page.where((m) => m.authorId == widget.ownerId && !m.hidden),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_items.isEmpty && !_loading && _error == null)
        const _ProfileEmpty('Este perfil aún no ha publicado misiones.'),
      for (final mission in _items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MissionSummary(
            mission: mission,
            repository: widget.repository,
            owner: widget.owner,
            onTap: () async {
              await widget.onOpen('/missions/${mission.id}');
              if (mounted) _load(reset: true);
            },
          ),
        ),
      if (_error != null) CommunityNotice(message: _error!, onRetry: _load),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_more)
        TextButton(onPressed: _load, child: const Text('Cargar más misiones')),
    ],
  );
}

class _ProfileEmpty extends StatelessWidget {
  const _ProfileEmpty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF607C98)),
    ),
  );
}
