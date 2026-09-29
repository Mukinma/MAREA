import 'package:marea/features/profile/presentation/profile_experience.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/marea_tabs.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:flutter/material.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    required this.controller,
    this.initialSection,
    super.key,
  });
  final AppSessionController controller;
  final String? initialSection;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _query = '', _section = 'posts', _savedSection = 'posts';
  String? _category;
  ShowcaseKind? _kind;
  @override
  void initState() {
    super.initState();
    _section = widget.initialSection == 'saved' ? 'saved' : 'posts';
  }

  @override
  void didUpdateWidget(ExploreScreen old) {
    super.didUpdateWidget(old);
    if (old.initialSection != widget.initialSection) {
      setState(
        () => _section = widget.initialSection == 'saved' ? 'saved' : 'posts',
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CommunityPage(
    title: _section == 'saved' ? 'Guardados' : 'Explorar',
    children: [
      MareaSurface(
        inset: true,
        radius: 16,
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            filled: false,
            labelText: _section == 'people'
                ? 'Buscar nombre o usuario'
                : _section == 'showcases'
                ? 'Buscar fichas por título'
                : 'Buscar por título',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: () => setState(() => _query = _search.text.trim()),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      MareaTabs(
        options: const {
          'posts': 'Publicaciones',
          'people': 'Personas',
          'showcases': 'Fichas',
          'saved': 'Guardados',
        },
        value: _section,
        onChanged: (value) => setState(() => _section = value),
      ),
      const SizedBox(height: 20),
      if (_section == 'saved') ...[
        MareaTabs(
          options: const {'posts': 'Publicaciones', 'showcases': 'Fichas'},
          value: _savedSection,
          onChanged: (value) => setState(() => _savedSection = value),
        ),
        const SizedBox(height: 20),
      ],
      if (_section != 'people') ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final entry in communityCategories.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _category == entry.key,
                    onSelected: (_) => setState(() => _category = entry.key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_section == 'showcases')
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos los tipos'),
                selected: _kind == null,
                onSelected: (_) => setState(() => _kind = null),
              ),
              for (final kind in ShowcaseKind.values)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
        if (_section != 'showcases' &&
            (_section != 'saved' || _savedSection == 'posts')) ...[
          if (_section == 'saved')
            Text(
              'Publicaciones guardadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          PostsFeed(
            controller: widget.controller,
            query: _query,
            category: _category,
            savedOnly: _section == 'saved',
            showHeading: false,
          ),
        ],
        if (_section == 'showcases' ||
            (_section == 'saved' && _savedSection == 'showcases')) ...[
          const SizedBox(height: 20),
          if (_section == 'saved')
            Text(
              'Fichas guardadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ShowcaseList(
            controller: widget.controller,
            query: _query,
            category: _category,
            kind: _section == 'showcases' ? _kind : null,
            savedOnly: _section == 'saved',
          ),
        ],
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
                MareaCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: SizedBox.square(
                      dimension: 44,
                      child: ClipOval(
                        child: ProfileImage(
                          path: person.avatarPath,
                          repository: widget.controller.mediaRepository,
                          fallback: SocialAvatar(
                            initials: person.initials,
                            size: 44,
                          ),
                        ),
                      ),
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

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    required this.controller,
    required this.profileId,
    super.key,
  });
  final AppSessionController controller;
  final String profileId;
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  CommunityProfile? _profile;
  String? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId ||
        oldWidget.controller != widget.controller) {
      _profile = null;
      _error = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final repo = widget.controller.communityRepository;
      if (repo == null) throw StateError('community unavailable');
      final profiles = await repo.profiles(ids: [widget.profileId]);
      if (mounted && generation == _generation) {
        setState(() {
          _profile = profiles.firstOrNull;
          _error = profiles.isEmpty
              ? 'Este perfil ya no está disponible.'
              : null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = communityError(error);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ProfileBackButton(fallback: '/explore'),
      title: const Text('Perfil'),
    ),
    body: _profile == null
        ? _loading
              ? const Center(child: CircularProgressIndicator())
              : CommunityNotice(
                  message: _error ?? 'Este perfil ya no está disponible.',
                  onRetry: _load,
                )
        : ProfileExperience(
            key: ValueKey(widget.profileId),
            controller: widget.controller,
            profile: _profile!,
            owner: false,
            onRefresh: _load,
            feedback: _error == null
                ? null
                : CommunityNotice(message: _error!, onRetry: _load),
          ),
  );
}
