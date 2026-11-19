import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';

class AccessBrand extends StatelessWidget {
  const AccessBrand({super.key, this.width = 112});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/MAREA_LOGOTIPO.png',
    width: width,
    height: width / 4.5,
    fit: BoxFit.contain,
    semanticLabel: 'Marea',
  );
}

class AccessHeader extends StatelessWidget {
  const AccessHeader({super.key, this.start, this.end, this.brandWidth = 112});

  final Widget? start;
  final Widget? end;
  final double brandWidth;

  @override
  Widget build(BuildContext context) {
    const minHeight = BoxConstraints(minHeight: 48);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: minHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: start,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: Center(child: AccessBrand(width: brandWidth)),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: minHeight,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              heightFactor: 1,
              child: end,
            ),
          ),
        ),
      ],
    );
  }
}

class AccessLayout extends StatelessWidget {
  const AccessLayout({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.onBack,
    this.showBack = false,
    this.step,
    this.totalSteps,
    this.leading,
    this.messengerKey,
    this.maxWidth = 480,
    this.compact = false,
  }) : assert((step == null) == (totalSteps == null));

  final Widget child;
  final String title;
  final String? description;
  final VoidCallback? onBack;
  final bool showBack;
  final int? step, totalSteps;
  final Widget? leading;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: const BorderSide(color: Color(0xFF8193A8)),
    );
    final content = Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: AppColors.surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.actionBlue, width: 2),
          ),
          disabledBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.border),
          ),
          errorMaxLines: 4,
          helperMaxLines: 4,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 360 ? 16 : 24,
                constraints.maxWidth >= 600 ? 32 : 8,
                constraints.maxWidth < 360 ? 16 : 24,
                compact ? 12 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AccessHeader(
                        start: showBack || onBack != null
                            ? IconButton.outlined(
                                tooltip: AppLocalizations.tr('Atrás'),
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              )
                            : null,
                        end: step == null
                            ? null
                            : Text(
                                '$step de $totalSteps',
                                textAlign: TextAlign.end,
                                semanticsLabel: 'Paso $step de $totalSteps',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                      if (step case final activeStep?) ...[
                        const SizedBox(height: 12),
                        ExcludeSemantics(
                          child: Row(
                            spacing: 6,
                            children: [
                              for (var index = 1; index <= totalSteps!; index++)
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: index <= activeStep
                                          ? AppColors.aquaDark
                                          : AppColors.mint,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const SizedBox(height: 4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 12 : 24),
                      if (leading != null) ...[
                        Align(alignment: Alignment.centerLeft, child: leading),
                        const SizedBox(height: 12),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      if (description case final description?) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 12 : 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return messengerKey == null
        ? content
        : ScaffoldMessenger(key: messengerKey, child: content);
  }
}

void showAccessAlert(ScaffoldMessengerState messenger, String message) {
  messenger
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const _AccessAlertIcon(),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}

class _AccessAlertIcon extends StatelessWidget {
  const _AccessAlertIcon();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Icon(
      Icons.error_outline_rounded,
      size: 20,
      color: AppColors.navigationAqua,
    ),
  );
}

class AccessTextField extends MareaTextField {
  const AccessTextField({
    super.key,
    required super.controller,
    required super.label,
    super.hint,
    super.helperText,
    super.validator,
    super.keyboardType,
    super.textInputAction,
    super.autofillHints,
    super.obscureText,
    super.enabled,
    super.prefixText,
    super.suffixIcon,
    super.maxLines,
    super.maxLength,
    super.onFieldSubmitted,
    super.onChanged,
    super.inputFormatters,
  }) : super(outlined: true);
}

class AccessFeedback extends StatelessWidget {
  const AccessFeedback({
    super.key,
    required this.message,
    this.error = true,
    this.action,
  });

  final String message;
  final bool error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = error ? Colors.white : const Color(0xFF075C52);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error ? AppColors.brandNavy : AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error)
              const _AccessAlertIcon()
            else
              ExcludeSemantics(
                child: Icon(Icons.info_outline_rounded, color: color, size: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(message, style: TextStyle(color: color)),
                  ),
                  if (action case final action?)
                    TextButtonTheme(
                      data: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: error
                              ? AppColors.navigationAqua
                              : color,
                          disabledForegroundColor: error
                              ? AppColors.border
                              : null,
                        ),
                      ),
                      child: action,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccessGoogleButton extends StatelessWidget {
  const AccessGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: isLoading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Image.asset(
            'assets/onboarding/google_g.png',
            width: 18,
            height: 18,
            excludeFromSemantics: true,
          ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            isLoading
                ? AppLocalizations.tr('Conectando con Google…')
                : AppLocalizations.tr('Continuar con Google'),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
