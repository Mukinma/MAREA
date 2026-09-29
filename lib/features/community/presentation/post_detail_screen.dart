import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/features/profile/models/profile.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    required this.controller,
    required this.postId,
    this.panel,
    this.commentId,
    this.interestId,
    this.notificationId,
    super.key,
  });
  final AppSessionController controller;
  final String postId;
  final String? panel, commentId, interestId, notificationId;
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  CommunityPost? _post;
  CommunityProfile? _author;
  PostSocialStats? _stats;
  bool _loading = true, _saved = false, _opened = false;
  String? _error;
  final _draft = CommentDraft();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = widget.controller.communityRepository!;
      final post = await repo.post(widget.postId);
      if (post == null || post.hidden) {
        if (mounted) {
          setState(() {
            _post = null;
            _loading = false;
          });
        }
        return;
      }
      final authors = await repo.profiles(ids: [post.authorId]);
      final saved = await repo.savedPostIds();
      final stats = await widget.controller.socialRepository?.stats([post.id]);
      if (!mounted) return;
      setState(() {
        _post = post;
        _author = authors.firstOrNull;
        _saved = saved.contains(post.id);
        _stats = stats?[post.id];
        _loading = false;
      });
      if (!_opened) {
        _opened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) await _openDestination();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = communityError(e);
        });
      }
    }
  }

  Future<void> _refreshStats() async {
    final stats = await widget.controller.socialRepository?.stats([
      widget.postId,
    ]);
    if (mounted) setState(() => _stats = stats?[widget.postId]);
  }

  Future<void> _markRead() async {
    if (widget.notificationId != null) {
      await widget.controller.socialRepository?.markRead(
        id: widget.notificationId,
      );
      await widget.controller.notifications?.refresh();
    }
  }

  Future<void> _openDestination() async {
    final social = widget.controller.socialRepository;
    try {
      if (widget.panel == 'interest' &&
          social != null &&
          widget.interestId != null) {
        final interest = await social.interest(widget.interestId!);
        if (!mounted) return;
        if (interest == null || interest.postId != widget.postId) {
          setState(() => _error = 'Este interés ya no está disponible.');
          return;
        }
        final profiles = await widget.controller.communityRepository!.profiles(
          ids: [interest.applicantId],
        );
        if (!mounted) return;
        await _markRead();
        if (!mounted) return;
        await showSocialPanel(
          context,
          SocialPanelFrame(
            title: 'Interés de colaboración',
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  profiles.firstOrNull?.fullName ?? 'Cuenta no disponible',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  interest.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(socialDate(interest.createdAt)),
                const SizedBox(height: 12),
                const Text('Mensaje privado entre el solicitante y el autor.'),
              ],
            ),
          ),
        );
      } else if (widget.panel == 'comments' && social != null) {
        if (!mounted) return;
        await showSocialPanel(
          context,
          CommentsPanel(
            post: _post!,
            repository: social,
            community: widget.controller.communityRepository!,
            viewerId: widget.controller.profile?.id,
            moderator: widget.controller.profile?.role == ProfileRole.admin,
            draft: _draft,
            commentId: widget.commentId,
            onReady: _markRead,
            onChanged: _refreshStats,
          ),
        );
      } else {
        await _markRead();
      }
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Volver',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Publicación'),
    ),
    body: CommunityPage(
      title: '',
      maxWidth: 820,
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_post == null && _error == null)
          const CommunityNotice(
            message: 'Esta publicación fue retirada o ya no está disponible.',
          ),
        if (_error != null)
          CommunityNotice(
            message: _error!,
            onRetry: () {
              _opened = false;
              _load();
            },
          ),
        if (_post != null)
          PostCard(
            post: _post!,
            author: _author,
            repository: widget.controller.communityRepository!,
            socialRepository: widget.controller.socialRepository,
            mediaRepository: widget.controller.mediaRepository,
            viewerId: widget.controller.profile?.id,
            moderator: widget.controller.profile?.role == ProfileRole.admin,
            saved: _saved,
            stats: _stats,
            publicUrl: widget.controller.publicUrl,
            onStats: (stats) => _stats = stats,
            onChanged: _load,
            onSaved: (saved) => _saved = saved,
          ),
      ],
    ),
  );
}
