import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/social_avatar.dart';

/// Identity always belongs to [profile]. Account actions are supplied separately.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    required this.profile,
    required this.controller,
    required this.wide,
    this.onSettings,
    this.onMenu,
    this.settingsTooltip = 'Configuración',
    this.editAction,
    super.key,
  });
  final CommunityProfile profile;
  final AppSessionController controller;
  final bool wide;
  final VoidCallback? onSettings, onMenu;
  final String settingsTooltip;
  final Widget? editAction;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF4FBFE),
    borderRadius: BorderRadius.circular(wide ? 20 : 0),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: wide ? 220 : 232 + MediaQuery.paddingOf(context).top,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProfileImage(
                path: profile.coverPath,
                repository: controller.mediaRepository,
                fallback: ProfileCover(preset: profile.coverPreset),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 90,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x6607345C), Color(0x0007345C)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 144,
                child: ProfileWaves(
                  colors: profile.waveColors ?? ProfileWaves.defaultColors,
                ),
              ),
              Positioned(
                top: wide ? 12 : MediaQuery.paddingOf(context).top + 12,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onSettings != null)
                      IconButton(
                        tooltip: settingsTooltip,
                        onPressed: onSettings,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 21),
                      ),
                    if (onMenu != null)
                      IconButton(
                        tooltip: 'Menú del perfil',
                        onPressed: onMenu,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.menu_rounded, size: 23),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: 8,
                width: 112,
                height: 112,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A07345C),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: ProfileImage(
                            path: profile.avatarPath,
                            repository: controller.mediaRepository,
                            fallback: SocialAvatar(
                              initials: profile.initials,
                              size: 104,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (profile.openToCollaboration)
                      Positioned(
                        right: 6,
                        bottom: 10,
                        child: Tooltip(
                          message: 'Disponible para colaborar',
                          child: Semantics(
                            label: 'Disponible para colaborar',
                            child: Container(
                              width: 19,
                              height: 19,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00AD8A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (editAction != null)
                Positioned(
                  left: 148,
                  right: 16,
                  bottom: 14,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: editAction!,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF07345C),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    profile.userType.databaseValue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF07345C),
                    ),
                  ),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF607C98),
                    ),
                  ),
                ],
              ),
              if (profile.bio?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  profile.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF607C98),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              InkWell(
                onTap:
                    profile.location == null || profile.locationLatitude == null
                    ? null
                    : () => showPostLocationViewer(
                        context,
                        label: profile.location!,
                        coordinates: PostCoordinates(
                          latitude: profile.locationLatitude!,
                          longitude: profile.locationLongitude!,
                          precision: PostLocationPrecision.values.byName(
                            profile.locationPrecision ?? 'exact',
                          ),
                        ),
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF607C98),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          profile.location ?? 'Ubicación no indicada',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF607C98),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
