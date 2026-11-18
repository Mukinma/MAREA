import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/shared/widgets/primary_button.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.controller,
    this.email,
    this.allowGoogle = true,
    super.key,
  });

  final AppSessionController controller;
  final String? email;
  final bool allowGoogle;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _SignInMethod { password, google }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final _emailController = TextEditingController(text: widget.email);
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  _SignInMethod? _pending;
  AppFailure? _passwordFailure;

  bool get _busy => _pending != null || widget.controller.isBusy;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _go(String location, {String? email}) {
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    context.goWithAccessEmail(location, email: email);
  }

  void _clearPasswordFailure() {
    if (_passwordFailure == null) return;
    setState(() => _passwordFailure = null);
    widget.controller.clearFeedback();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _messengerKey.currentState?.removeCurrentSnackBar();
    setState(() {
      _pending = _SignInMethod.password;
      _passwordFailure = null;
    });
    final ok = await widget.controller.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) TextInput.finishAutofillContext();
    final failure = ok ? null : widget.controller.failure;
    final needsConfirmation = failure?.kind == AppFailureKind.emailNotConfirmed;
    setState(() {
      _pending = null;
      _passwordFailure = needsConfirmation ? failure : null;
    });
    if (failure != null) {
      widget.controller.clearFeedback();
      if (!needsConfirmation) {
        final message = switch (failure.message) {
          'No pudimos conectarnos. Inténtalo nuevamente.' ||
          'Espera un momento antes de volver a intentarlo.' => failure.message,
          _ => 'Revisa tu correo y contraseña e inténtalo de nuevo.',
        };
        showAccessAlert(_messengerKey.currentState!, message);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy || !widget.allowGoogle) return;
    FocusScope.of(context).unfocus();
    _messengerKey.currentState?.removeCurrentSnackBar();
    setState(() {
      _pending = _SignInMethod.google;
      _passwordFailure = null;
    });
    final ok = await widget.controller.signInWithGoogle(
      redirectTo: kIsWeb
          ? Uri.base.origin
          : AppConfig.fromEnvironment().mobileOAuthRedirect,
    );
    if (!mounted) return;
    setState(() => _pending = null);
    final failure = ok ? null : widget.controller.failure;
    if (failure != null) {
      widget.controller.clearFeedback();
      showAccessAlert(_messengerKey.currentState!, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AccessLayout(
          messengerKey: _messengerKey,
          title: core_l10n.AppLocalizations.tr('Iniciar sesión'),
          showBack: true,
          onBack: _busy ? null : () => _go('/welcome'),
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccessTextField(
                    key: const Key('login-email'),
                    enabled: !_busy,
                    controller: _emailController,
                    label: core_l10n.AppLocalizations.tr('Correo'),
                    hint: 'tu@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: (value) => FormValidators.email(value?.trim()),
                    onChanged: (_) => _clearPasswordFailure(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AccessTextField(
                    key: const Key('login-password'),
                    enabled: !_busy,
                    controller: _passwordController,
                    label: core_l10n.AppLocalizations.tr('Contraseña'),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) => (value ?? '').isEmpty
                        ? core_l10n.AppLocalizations.tr(
                            'Escribe una contraseña.',
                          )
                        : null,
                    onChanged: (_) => _clearPasswordFailure(),
                    onFieldSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? core_l10n.AppLocalizations.tr('Mostrar contraseña')
                          : core_l10n.AppLocalizations.tr('Ocultar contraseña'),
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _go(
                              '/recover-password',
                              email: _emailController.text.trim(),
                            ),
                      child: Text(
                        core_l10n.AppLocalizations.tr('Olvidé mi contraseña'),
                      ),
                    ),
                  ),
                  if (_passwordFailure != null) ...[
                    AccessFeedback(
                      message: core_l10n.AppLocalizations.tr(
                        'Confirma tu correo para entrar a Marea.',
                      ),
                      error: false,
                      action: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _go(
                                '/check-email',
                                email: _emailController.text.trim(),
                              ),
                        child: Text(
                          core_l10n.AppLocalizations.tr('Confirmar mi correo'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  PrimaryButton(
                    label: 'Entrar',
                    loadingLabel: core_l10n.AppLocalizations.tr(
                      'Iniciando sesión…',
                    ),
                    isLoading: _pending == _SignInMethod.password,
                    onPressed: _busy ? null : _submit,
                  ),
                  if (widget.allowGoogle) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(child: Divider()),
                          Text(
                            'o',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    AccessGoogleButton(
                      key: const Key('login-google'),
                      isLoading: _pending == _SignInMethod.google,
                      onPressed: _busy ? null : _signInWithGoogle,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(core_l10n.AppLocalizations.tr('¿No tienes cuenta?')),
                      TextButton(
                        onPressed: _busy ? null : () => _go('/register'),
                        child: Text(
                          core_l10n.AppLocalizations.tr('Crear cuenta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
