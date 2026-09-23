import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          onSelected: enabled
              ? (value) {
                  final next = {...selected};
                  value ? next.add(entry.key) : next.remove(entry.key);
                  onChanged(next);
                }
              : null,
        ),
    ],
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  late Set<String> interests = {...?widget.controller.profile?.interests};
  late Set<String> goals = {...?widget.controller.profile?.goals};
  late final bio = TextEditingController(text: widget.controller.profile?.bio);
  late UserType type = widget.controller.profile?.userType ?? UserType.general;
  @override
  void dispose() {
    bio.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    final ok = await widget.controller.finishOnboarding(
      skip: true,
      interests: [],
      goals: [],
    );
    if (ok && mounted) context.go('/profile');
  }

  Future<void> _next() async {
    if (step < 2) {
      setState(() => step++);
      return;
    }
    final profile = widget.controller.profile;
    if (profile == null) return;
    final ok = await widget.controller.updateProfile(
      profile
          .copyWith(
            interests: interests.toList(),
            goals: goals.toList(),
            bio: bio.text.trim().isEmpty ? null : bio.text.trim(),
            userType: type,
            onboardingStatus: OnboardingStatus.completed,
          )
          .updateInput,
    );
    if (ok && mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const MareaLogo(compact: true),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.controller.isBusy ? null : _skip,
                        child: const Text('Ahora no'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'A tu manera · ${step + 1} de 3',
                    style: const TextStyle(
                      color: AppColors.aquaDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (step + 1) / 3,
                    color: AppColors.aqua,
                    backgroundColor: AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    [
                      '¿Qué te mueve?',
                      '¿Qué te gustaría encontrar?',
                      'Un poco sobre ti',
                    ][step],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    [
                      'Elige tus mundos favoritos. Puedes elegir varios o continuar sin seleccionar.',
                      'Tus preferencias nos ayudan a conocer qué buscas. No son públicas.',
                      'Esta presentación es opcional. Podrás cambiarla cuando quieras.',
                    ][step],
                  ),
                  const SizedBox(height: 28),
                  if (step == 0)
                    PreferenceChips(
                      catalog: ProfilePreferences.interests,
                      selected: interests,
                      enabled: !widget.controller.isBusy,
                      onChanged: (v) => setState(() => interests = v),
                    ),
                  if (step == 1)
                    PreferenceChips(
                      catalog: ProfilePreferences.goals,
                      selected: goals,
                      enabled: !widget.controller.isBusy,
                      onChanged: (v) => setState(() => goals = v),
                    ),
                  if (step == 2) ...[
                    DropdownButtonFormField<UserType>(
                      isExpanded: true,
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Me identifico como',
                      ),
                      items: [
                        for (final value in UserType.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value.databaseValue),
                          ),
                      ],
                      onChanged: (v) => setState(() => type = v ?? type),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: bio,
                      maxLength: 160,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Una línea sobre ti',
                        hintText: 'Cuéntanos qué te gusta crear.',
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SessionFeedback(controller: widget.controller),
                  PrimaryButton(
                    label: step == 2 ? 'Listo, entrar a MAREA' : 'Continuar',
                    isLoading: widget.controller.isBusy,
                    onPressed: _next,
                  ),
                  if (step > 0)
                    TextButton(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => setState(() => step--),
                      child: const Text('Atrás'),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Opcional, sin prisa. Puedes retomar esta guía desde Configuración.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
