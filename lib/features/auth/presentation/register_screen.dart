import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/legal/legal_screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _adultConfirmed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || widget.controller.isBusy) return;
    if (!_acceptedTerms ||
        !_adultConfirmed ||
        !widget.controller.legalPolicy.canRegister) {
      return;
    }
    final username = FormValidators.normalizeUsername(_usernameController.text);

    final outcome = await widget.controller.signUp(
      fullName: _nameController.text.trim(),
      username: username,
      email: _emailController.text,
      password: _passwordController.text,
      consent: LegalConsent(
        termsVersion: widget.controller.legalPolicy.terms!.version,
        privacyVersion: widget.controller.legalPolicy.privacy!.version,
        acceptedTerms: _acceptedTerms,
        adultConfirmed: _adultConfirmed,
      ),
    );
    if (!mounted) return;
    if (outcome == SignUpOutcome.confirmationRequired) {
      context.go('/check-email', extra: _emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      register: true,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Inicio'),
                ),
              ),
              Text(
                'Crea tu lugar en MAREA',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Da el primer paso para conectar, crear y crecer en tu ciudad.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              MareaTextField(
                controller: _nameController,
                label: 'Nombre completo',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: FormValidators.fullName,
              ),
              const SizedBox(height: AppSpacing.md),
              MareaTextField(
                key: const Key('register-username'),
                controller: _usernameController,
                label: 'Nombre de usuario',
                prefixText: '@',
                textInputAction: TextInputAction.next,
                validator: FormValidators.username,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Este será el nombre con el que otras personas podrán encontrarte.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              MareaTextField(
                controller: _emailController,
                label: 'Correo',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: FormValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              MareaTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: FormValidators.password,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MareaTextField(
                controller: _confirmationController,
                label: 'Confirmar contraseña',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => FormValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.controller.legalPolicy.canRegister) ...[
                      Text(
                        widget.controller.legalError ??
                            'El registro abrirá cuando estén publicados los documentos legales de MAREA. Por ahora no enviaremos tus datos.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: widget.controller.reloadLegal,
                        child: const Text('Volver a cargar documentos'),
                      ),
                    ],
                    ConsentFields(
                      terms: _acceptedTerms,
                      adult: _adultConfirmed,
                      enabled:
                          !widget.controller.isBusy &&
                          widget.controller.legalPolicy.canRegister,
                      onTermsChanged: (v) => setState(() => _acceptedTerms = v),
                      onAdultChanged: (v) =>
                          setState(() => _adultConfirmed = v),
                    ),
                    const SizedBox(height: 12),
                    if (widget.controller.failure case final failure?) ...[
                      Text(
                        failure.message,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    PrimaryButton(
                      label: 'Crear mi cuenta',
                      isLoading: widget.controller.isBusy,
                      onPressed:
                          _acceptedTerms &&
                              _adultConfirmed &&
                              widget.controller.legalPolicy.canRegister
                          ? _submit
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
