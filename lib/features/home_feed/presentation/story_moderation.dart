import 'package:flutter/material.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';

class StoryModeration extends StatefulWidget {
  const StoryModeration({required this.repository, super.key});
  final StoriesRepository repository;
  @override
  State<StoryModeration> createState() => _StoryModerationState();
}

class _StoryModerationState extends State<StoryModeration> {
  late Future<List<Story>> _future = widget.repository.reported();
  String? _error;
  String? _busy;
  void _reload() => setState(() {
    _future = widget.repository.reported();
    _error = null;
  });
  Future<void> _moderate(Story story) async {
    setState(() => _busy = story.id);
    try {
      await widget.repository.moderate(story.id, !story.hidden);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Historias reportadas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar historias reportadas',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      if (_error != null) CommunityNotice(message: _error!),
      FutureBuilder<List<Story>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CommunityNotice(
              message: communityError(snapshot.error!),
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          if (snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No hay historias reportadas.'),
            );
          }
          return Column(
            children: [
              for (final story in snapshot.data!)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (story.imagePath != null)
                          FutureBuilder<String>(
                            future: widget.repository.imageUrl(story),
                            builder: (_, image) => image.hasData
                                ? Image.network(
                                    image.data!,
                                    height: 160,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Text(
                                      'La foto no está disponible.',
                                    ),
                                  )
                                : image.hasError
                                ? const Text('La foto no está disponible.')
                                : const LinearProgressIndicator(),
                          ),
                        Text(story.text),
                        const SizedBox(height: 8),
                        for (final reason in story.reportReasons)
                          Text('Motivo: $reason'),
                        Text(
                          story.hidden ? 'Oculta por moderación' : 'Visible',
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _busy != null
                                ? null
                                : () => _moderate(story),
                            icon: Icon(
                              story.hidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            label: Text(
                              _busy == story.id
                                  ? 'Guardando…'
                                  : story.hidden
                                  ? 'Restaurar historia'
                                  : 'Ocultar historia',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
    ],
  );
}
