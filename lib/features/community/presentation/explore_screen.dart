import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/profile/models/profile.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _query = '', _section = 'posts';
  String? _category;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CommunityPage(
    title: 'Descubre tu comunidad',
    subtitle: 'Encuentra talento, proyectos y lugares para conectar.',
    children: [
      TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onSubmitted: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          labelText: _section == 'people'
              ? 'Buscar nombre o usuario'
              : 'Buscar publicaciones por título',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Buscar',
            onPressed: () => setState(() => _query = _search.text.trim()),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in {
            'posts': 'Publicaciones',
            'people': 'Personas y proyectos',
            'saved': 'Guardados',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: _section == entry.key,
              onSelected: (_) => setState(() => _section = entry.key),
            ),
        ],
      ),
      const SizedBox(height: 20),
      if (_section != 'people') ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final entry in communityCategories.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _category == entry.key,
                onSelected: (_) => setState(() => _category = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PostsFeed(
          controller: widget.controller,
          query: _query,
          category: _category,
          savedOnly: _section == 'saved',
        ),
      ] else if (widget.controller.communityRepository == null)
        const CommunityNotice(message: 'No pudimos conectar con la comunidad.')
      else
        CommunityLoad<List<CommunityProfile>>(
          key: ValueKey(_query),
          load: () =>
              widget.controller.communityRepository!.profiles(query: _query),
          builder: (people, reload) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (people.isEmpty)
                const CommunityNotice(
                  message: 'No encontramos perfiles con ese nombre.',
                ),
              for (final person in people)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lavender,
                      child: Text(person.initials),
                    ),
                    title: Text(person.fullName),
                    subtitle: Text(
                      '@${person.username} · ${person.userType.databaseValue}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/people/${person.id}'),
                  ),
                ),
              if (people.length == 100)
                const Text(
                  'Se muestran los primeros 100 perfiles. Usa la búsqueda para encontrar a alguien.',
                ),
            ],
          ),
        ),
    ],
  );
}

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({
    required this.controller,
    required this.profileId,
    super.key,
  });
  final AppSessionController controller;
  final String profileId;
  @override
  Widget build(BuildContext context) {
    final repo = controller.communityRepository;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de la comunidad')),
      body: repo == null
          ? const CommunityNotice(
              message: 'No pudimos conectar con la comunidad.',
            )
          : CommunityLoad<List<CommunityProfile>>(
              key: ValueKey(profileId),
              load: () => repo.profiles(ids: [profileId]),
              builder: (profiles, reload) {
                if (profiles.isEmpty) {
                  return const CommunityNotice(
                    message: 'Este perfil ya no está disponible.',
                  );
                }
                final profile = profiles.first;
                return CommunityPage(
                  title: profile.fullName,
                  subtitle: '@${profile.username}',
                  onRefresh: reload,
                  children: [
                    Card(
                      color: AppColors.mint,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(label: Text(profile.userType.databaseValue)),
                            const SizedBox(height: 12),
                            Text(
                              profile.userType.headline,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.bio?.isNotEmpty == true
                                  ? profile.bio!
                                  : profile.userType.description,
                            ),
                            if (profile.website != null &&
                                ProfilePreferences.websiteError(
                                      profile.website,
                                    ) ==
                                    null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text(
                                    'Visitar enlace del perfil',
                                  ),
                                  onPressed: () => runCommunityAction(
                                    context,
                                    () async {
                                      if (!await launchUrl(
                                        Uri.parse(profile.website!),
                                        mode: LaunchMode.externalApplication,
                                      )) {
                                        throw StateError('Could not open link');
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      profile.userType.showcaseLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    PostsFeed(controller: controller, authorId: profileId),
                    const SizedBox(height: 24),
                    Text(
                      'Misiones de este perfil',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    CommunityLoad<List<Mission>>(
                      key: ValueKey('missions:$profileId'),
                      load: () => repo.missions(authorId: profileId),
                      builder: (missions, reload) => Column(
                        children: [
                          if (missions.isEmpty)
                            const CommunityNotice(
                              message: 'Aún no ha publicado misiones.',
                            ),
                          for (final mission in missions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: MissionSummary(mission: mission, repository: repo, onTap: () async { await context.push('/missions/${mission.id}'); if(context.mounted) reload(); }),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
