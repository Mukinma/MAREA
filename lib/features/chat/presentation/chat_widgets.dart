import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/shared/widgets/profile_image.dart';

class ChatScaffold extends StatelessWidget {
  const ChatScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(child: child),
    ),
  );
}

class ChatBackButton extends StatelessWidget {
  const ChatBackButton({required this.fallback, super.key});

  final String fallback;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.tr('Volver'),
    icon: const BackButtonIcon(),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallback);
      }
    },
  );
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (subtitle == null
                                  ? theme.titleLarge
                                  : theme.titleMedium)
                              ?.copyWith(
                                color: AppColors.brandNavy,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall,
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    required this.chat,
    required this.repository,
    required this.size,
    super.key,
  });

  final ChatConversation chat;
  final ProfileMediaRepository? repository;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = chat.otherName.trim();
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word.characters.first.toUpperCase())
              .join();

    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: SizedBox.square(
            dimension: size,
            child: ClipOval(
              child: ProfileImage(
                path: chat.otherAvatarPath,
                repository: repository,
                fallback: ColoredBox(
                  color: AppColors.mint,
                  child: Center(
                    child: Text(
                      initials,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: AppColors.brandNavy,
                        fontSize: size * .34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatNotice extends StatelessWidget {
  const ChatNotice({
    required this.icon,
    required this.title,
    this.description,
    this.actions = const [],
    this.card = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final List<Widget> actions;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSpacing.huge,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandNavy, size: 22),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, textAlign: TextAlign.center, style: theme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: actions,
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: card
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.softBorder),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

class ChatLoading extends StatelessWidget {
  const ChatLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      semanticsLabel: AppLocalizations.tr('Cargando'),
    ),
  );
}

String chatTime(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
