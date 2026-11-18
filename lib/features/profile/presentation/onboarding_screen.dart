import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class PreferenceChips extends StatelessWidget {
  const PreferenceChips({
    required this.catalog,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final Map<String, String> catalog;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final entry in catalog.entries)
        FilterChip(
          label: Text(entry.value),
          selected: selected.contains(entry.key),
          selectedColor: AppColors.mint,
          onSelected: enabled
              ? (v) {
                  final next = {...selected};
                  v ? next.add(entry.key) : next.remove(entry.key);
                  onChanged(next);
                }
              : null,
        ),
    ],
  );
}

/// Legacy accounts only: confirm type once without making optional setup a gate.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  UserType? _type;

  Future<void> _confirm() async {
    final controller = widget.controller;
    final profile = controller.profile;
    final type = _type;
    if (controller.isBusy || profile == null || type == null) return;
    await controller.completeInitialProfile(
      InitialProfileInput(
        userType: type,
        interests: profile.interests,
        goals: profile.goals,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => AccessLayout(
      title: AppLocalizations.tr('Elige tu perfil'),
      description: AppLocalizations.tr(
        'Elige cómo quieres participar en Marea. El tipo de perfil queda fijo al confirmar.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTypePicker(
            value: _type,
            enabled: !widget.controller.isBusy,
            onChanged: (v) => setState(() => _type = v),
          ),
          if (widget.controller.failure?.message case final message?) ...[
            const SizedBox(height: 16),
            AccessFeedback(message: message),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppLocalizations.tr('Confirmar y entrar'),
            loadingLabel: AppLocalizations.tr('Confirmando perfil…'),
            isLoading: widget.controller.isBusy,
            onPressed: _type == null || widget.controller.isBusy
                ? null
                : _confirm,
          ),
          TextButton(
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.signOut,
            child: Text(AppLocalizations.tr('Cerrar sesión')),
          ),
        ],
      ),
    ),
  );
}
