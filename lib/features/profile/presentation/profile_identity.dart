import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/professional_details.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private actions are supplied by the owner screen, never by public data.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    required this.profile,
    required this.controller,
    required this.wide,
    this.onSettings,
    this.editAction,
    super.key,
  });
  final CommunityProfile profile;
  final AppSessionController controller;
  final bool wide;
  final VoidCallback? onSettings;
  final Widget? editAction;
  @override
  Widget build(BuildContext context) => MareaSurface(
    radius: 24,
    color: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: wide ? 96 : 80,
          width: double.infinity,
          child: ProfileImage(
            path: profile.coverPath,
            repository: controller.mediaRepository,
            fallback: ProfileCover(preset: profile.coverPreset),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -20,
                          child: Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: ProfileImage(
                                path: profile.avatarPath,
                                repository: controller.mediaRepository,
                                fallback: SocialAvatar(
                                  initials: profile.initials,
                                  size: 68,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (editAction != null)
                    Flexible(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: editAction,
                      ),
                    ),
                  if (onSettings != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: IconButton(
                        tooltip: 'Configuración',
                        onPressed: onSettings,
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 21),
                      ),
                    ),
                ],
              ),
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: profile.userType.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(profile.userType.icon, size: 15),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            profile.userType.databaseValue,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.bio?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    profile.bio!,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ),
              ProfessionalDetails(
                profile: profile,
                showContact: editAction == null,
              ),
              if (profile.website?.trim().isNotEmpty == true &&
                  ProfilePreferences.websiteError(profile.website) == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => runCommunityAction(context, () async {
                      if (!await launchUrl(
                        Uri.parse(profile.website!),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw StateError('link unavailable');
                      }
                    }),
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Sitio web'),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
