import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/core/localization/app_localizations.dart';

/// Identity always belongs to [profile]. Account actions are supplied separately.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    required this.profile,
    required this.controller,
    required this.wide,
    this.onSettings,
    this.onMenu,
    this.topInset = 0,
    this.followCounts,
    this.actions,
    this.leading,
    super.key,
  });
  final CommunityProfile profile;
  final AppSessionController controller;
  final bool wide;
  final VoidCallback? onSettings, onMenu;
  final double topInset;
  final Widget? followCounts;
  final Widget? actions, leading;

  @override
  Widget build(BuildContext context) {
    final place = profile.location?.trim();
    final latitude = profile.locationLatitude;
    final longitude = profile.locationLongitude;
    final coordinates = latitude == null || longitude == null
        ? null
        : PostCoordinates(
            latitude: latitude,
            longitude: longitude,
            precision: profile.locationPrecision == 'approximate'
                ? PostLocationPrecision.approximate
                : PostLocationPrecision.exact,
          );
    return LayoutBuilder(
      builder: (context, bounds) {
        final overlayActions =
            actions != null &&
            bounds.maxWidth >= 310 &&
            MediaQuery.textScalerOf(context).scale(16) <= 20;
        final avatarSize = wide ? 88.0 : 104.0;
        return Material(
          color: AppColors.profileCanvas,
          borderRadius: BorderRadius.circular(wide ? 20 : 0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: (wide ? 194 : 216) + topInset,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: ProfileImage(
                        path: profile.coverPath,
                        repository: controller.mediaRepository,
                        fallback: ProfileCover(preset: profile.coverPreset),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: wide ? 104 : 128,
                      child: ProfileWaves(
                        colors:
                            profile.waveColors ?? ProfileWaves.defaultColors,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topInset + 80,
                      child: const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xCC101D30), Color(0x00101D30)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: topInset + 8,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onSettings != null)
                            IconButton(
                              tooltip: AppLocalizations.tr('Configuración'),
                              onPressed: onSettings,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x8C132B4B),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(
                                Icons.settings_outlined,
                                size: 21,
                              ),
                            ),
                          if (onSettings != null && onMenu != null)
                            const SizedBox(width: 6),
                          if (onMenu != null)
                            IconButton(
                              tooltip: AppLocalizations.tr('Menú del perfil'),
                              onPressed: onMenu,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x8C132B4B),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                size: 23,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (leading != null)
                      Positioned(left: 12, top: topInset + 8, child: leading!),
                    Positioned(
                      left: 16,
                      bottom: 6,
                      width: avatarSize,
                      height: avatarSize,
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
                                    size: avatarSize - 8,
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
                                message: AppLocalizations.tr(
                                  'Disponible para colaborar',
                                ),
                                child: Semantics(
                                  label: AppLocalizations.tr(
                                    'Disponible para colaborar',
                                  ),
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
                    if (overlayActions)
                      PositionedDirectional(
                        key: const Key('profile-wave-actions'),
                        bottom: 20,
                        start: avatarSize + 28,
                        end: 16,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actions,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 28,
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
                          localizedProfileUserTypeLabel(
                            context,
                            profile.userType,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF07345C),
                          ),
                        ),
                        Text(
                          '@${profile.username}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF607C98),
                          ),
                        ),
                      ],
                    ),
                    if (place != null && place.isNotEmpty) ...[
                      if (coordinates?.isValid == true)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Tooltip(
                            message: AppLocalizations.tr('Ver en mapa'),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.place_outlined, size: 17),
                              label: Text(place),
                              onPressed: () => showPostLocationViewer(
                                context,
                                label: place,
                                coordinates: coordinates!,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 6),
                        Text(
                          place,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                    if (!overlayActions && actions != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: actions,
                      ),
                    ],
                    ?followCounts,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
