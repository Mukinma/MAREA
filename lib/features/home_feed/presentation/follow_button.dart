import 'package:flutter/material.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';

class FollowButton extends StatefulWidget {
  const FollowButton({
    required this.repository,
    required this.authorId,
    this.onChanged,
    super.key,
  });
  final HomeFeedRepository repository;
  final String authorId;
  final VoidCallback? onChanged;
  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool? _following;
  bool _busy = false;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FollowButton old) {
    super.didUpdateWidget(old);
    if (old.authorId != widget.authorId ||
        old.repository != widget.repository) {
      _following = null;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final value = await widget.repository.isFollowing(widget.authorId);
      if (mounted && generation == _generation) {
        setState(() {
          _following = value;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(e));
      }
    }
  }

  Future<void> _toggle() async {
    final next = !_following!;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      await widget.repository.setFollowing(widget.authorId, next);
      if (mounted && generation == _generation) {
        setState(() {
          _following = next;
          _error = null;
          widget.onChanged?.call();
        });
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(e));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FilledButton.tonalIcon(
        onPressed: _busy
            ? null
            : _following == null
            ? _load
            : _toggle,
        icon: Icon(_following == true ? Icons.check : Icons.person_add_alt_1),
        label: Text(
          _busy
              ? 'Guardando…'
              : _following == null
              ? _error == null
                    ? 'Cargando…'
                    : 'Reintentar'
              : _following!
              ? 'Siguiendo'
              : 'Seguir',
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: const TextStyle(fontSize: 12)),
        ),
    ],
  );
}
