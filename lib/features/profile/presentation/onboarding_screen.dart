import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

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
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => AuthLayout(
      register: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Elige tu perfil',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          ProfileTypePicker(
            value: _type,
            enabled: !widget.controller.isBusy,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 16),
          const Text(
            'El tipo de perfil queda fijo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SessionFeedback(controller: widget.controller),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirmar y entrar',
            isLoading: widget.controller.isBusy,
            onPressed: _type == null
                ? null
                : () async {
                    final before = widget.controller.profile!;
                    final ok = await widget.controller.completeInitialProfile(
                      InitialProfileInput(
                        userType: _type!,
                        interests: before.interests,
                        goals: before.goals,
                      ),
                    );
                    if (ok && context.mounted) context.go('/home');
                  },
          ),
          TextButton(
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.signOut,
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    ),
  );
}
