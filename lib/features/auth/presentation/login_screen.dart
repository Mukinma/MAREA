import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _confirmationEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || widget.controller.isBusy) return;
    final email = _emailController.text.trim();
    final ok = await widget.controller.signIn(
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _confirmationEmail =
          !ok &&
              _emailController.text.trim() == email &&
              widget.controller.failure?.kind ==
                  AppFailureKind.emailNotConfirmed
          ? email
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => AuthLayout(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : () => context.go('/welcome'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Inicio'),
                  ),
                ),
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Descubre personas, proyectos y lugares cerca de ti.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                MareaTextField(
                  key: const Key('login-email'),
                  enabled: !widget.controller.isBusy,
                  controller: _emailController,
                  label: 'Correo',
                  hint: 'tu@correo.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: FormValidators.email,
                  onChanged: (_) {
                    setState(() => _confirmationEmail = null);
                    widget.controller.clearFeedback();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                MareaTextField(
                  key: const Key('login-password'),
                  enabled: !widget.controller.isBusy,
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: FormValidators.password,
                  onFieldSubmitted: (_) => _submit(),
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
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.controller.isBusy
                        ? null
                        : () {
                            widget.controller.clearFeedback();
                            context.go('/recover-password');
                          },
                    child: const Text('Olvidé mi contraseña'),
                  ),
                ),
                AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          label: 'Iniciar sesión',
                          isLoading: widget.controller.isBusy,
                          onPressed: _submit,
                        ),
                        if (_confirmationEmail != null &&
                            widget.controller.failure?.kind ==
                                AppFailureKind.emailNotConfirmed)
                          TextButton(
                            onPressed: widget.controller.isBusy
                                ? null
                                : () {
                                    final email = _confirmationEmail!;
                                    widget.controller.clearFeedback();
                                    context.go('/check-email', extra: email);
                                  },
                            child: const Text('Confirmar mi correo'),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('¿Nuevo en MAREA?'),
                    TextButton(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => context.go('/register'),
                      child: const Text('Crear una cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
