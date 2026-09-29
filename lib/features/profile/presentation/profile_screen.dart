import 'package:flutter/material.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _feedRevision = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final profile = controller.profile;
          if (profile == null) {
            return _ProfileState(
              isLoading: controller.status == AuthStatus.initializing,
              onRetry: controller.refreshProfile,
            );
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.successMessage case final message?) ...[
                      _SuccessBanner(
                        message: message,
                        onDismiss: controller.clearFeedback,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Row(
                      children: [
                        Text(
                          'Tu perfil',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Configuración',
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 600;
                          final inset = wide ? 36.0 : 24.0;
                          final bio = profile.bio?.trim();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: wide ? 176 : 130,
                                child: ProfileImage(
                                  repository: controller.mediaRepository,
                                  path: profile.coverPath,
                                  fallback: ProfileCover(
                                    preset: profile.coverPreset,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  inset,
                                  0,
                                  inset,
                                  32,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: wide ? 100 : 76,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            top: -40,
                                            left: -5,
                                            child: SizedBox.square(
                                              dimension: wide ? 128 : 104,
                                              child: ClipOval(
                                                child: ProfileImage(
                                                  repository: controller
                                                      .mediaRepository,
                                                  path: profile.avatarPath,
                                                  fallback: SocialAvatar(
                                                    initials: profile.initials,
                                                    size: wide ? 128 : 104,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            profile.fullName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontSize: wide ? 34 : 28,
                                                ),
                                          ),
                                        ),
                                        if (wide)
                                          TextButton.icon(
                                            onPressed: () =>
                                                context.push('/profile/edit'),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            label: const Text('Editar perfil'),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 14,
                                      runSpacing: 10,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '@${profile.username}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.mint,
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          child: Text(
                                            profile.userType.databaseValue,
                                            style: const TextStyle(
                                              color: AppColors.brandNavy,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 620,
                                      ),
                                      child: Text(
                                        bio == null || bio.isEmpty
                                            ? 'Tu bio puede ser el inicio de una buena conexión.'
                                            : bio,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: bio == null || bio.isEmpty
                                                  ? AppColors.textSecondary
                                                  : AppColors.textPrimary,
                                            ),
                                      ),
                                    ),
                                    if (!wide) ...[
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: PrimaryButton(
                                          label: 'Editar perfil',
                                          icon: Icons.edit_outlined,
                                          onPressed: () =>
                                              context.push('/profile/edit'),
                                        ),
                                      ),
                                    ],
                                    if (profile.website != null &&
                                        ProfilePreferences.websiteError(
                                              profile.website,
                                            ) ==
                                            null) ...[
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final ok = await launchUrl(
                                            Uri.parse(profile.website!),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                          if (!ok && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No pudimos abrir el enlace.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.link_rounded),
                                        label: const Text('Mi portafolio'),
                                      ),
                                    ],
                                    if (profile.interests.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final interest
                                              in profile.interests)
                                            if (ProfilePreferences
                                                    .interests[interest] !=
                                                null)
                                              Chip(
                                                backgroundColor:
                                                    AppColors.lavender,
                                                side: BorderSide.none,
                                                label: Text(
                                                  ProfilePreferences
                                                      .interests[interest]!,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.userType.showcaseLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(profile.userType.description),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar publicación'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/missions'),
                          child: const Text('Misiones y postulaciones'),
                        ),
                        if (profile.role == ProfileRole.admin)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await context.push('/moderation');
                              if (!mounted) return;
                              setState(() => _feedRevision++);
                            },
                            icon: const Icon(Icons.shield_outlined),
                            label: const Text('Moderación'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (controller.communityRepository != null)
                      PostsFeed(
                        key: ValueKey('${profile.id}:$_feedRevision'),
                        controller: controller,
                        authorId: profile.id,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7F2),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProfileState extends StatelessWidget {
  const _ProfileState({required this.isLoading, required this.onRetry});
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('No pudimos cargar tu perfil.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
