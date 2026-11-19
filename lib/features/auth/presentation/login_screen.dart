import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/features/auth/presentation/login_artwork.dart';

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

        final messenger = _messengerKey.currentState;
        if (messenger != null) {
          showAccessAlert(messenger, message);
        }
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
      final messenger = _messengerKey.currentState;
      if (messenger != null) {
        showAccessAlert(messenger, failure.message);
      }
    }
  }

  static InputDecoration _decoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    const outline = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
      borderSide: BorderSide(color: Color(0xFF8193A8)),
    );

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      prefixIconColor: AppColors.textSecondary,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: outline,
      enabledBorder: outline,
      disabledBorder: outline.copyWith(
        borderSide: const BorderSide(color: AppColors.border),
      ),
      errorMaxLines: 4,
    );
  }

  Widget _formContent(BuildContext context, double gutter) {
    final theme = Theme.of(context);
    final tr = AppLocalizations.tr;
    final signingIn = _pending == _SignInMethod.password;
    final emailLabel = tr('Correo electrónico');
    final passwordLabel = tr('Contraseña');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: gutter,
        vertical: AppSpacing.sm,
      ),
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LoginField(
                label: emailLabel,
                child: TextFormField(
                  key: const Key('login-email'),
                  controller: _emailController,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  decoration: _decoration(
                    'tu@correo.com',
                    Icons.mail_outline_rounded,
                  ),
                  validator: (value) => FormValidators.email(value?.trim()),
                  onChanged: (_) => _clearPasswordFailure(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LoginField(
                label: passwordLabel,
                child: TextFormField(
                  key: const Key('login-password'),
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: _decoration(
                    tr('Introduce tu contraseña'),
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      tooltip: tr(
                        _obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                  validator: (value) => (value ?? '').isEmpty
                      ? tr('Escribe una contraseña.')
                      : null,
                  onChanged: (_) => _clearPasswordFailure(),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => _go(
                          '/recover-password',
                          email: _emailController.text.trim(),
                        ),
                  child: Text(
                    tr('¿Olvidaste tu contraseña?'),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
              if (_passwordFailure != null) ...[
                AccessFeedback(
                  message: tr('Confirma tu correo para entrar a Marea.'),
                  action: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _go(
                            '/check-email',
                            email: _emailController.text.trim(),
                          ),
                    child: Text(tr('Confirmar mi correo')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xxs),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accessPrimary,
                ),
                onPressed: _busy ? null : _submit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    if (signingIn)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.actionBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        tr(signingIn ? 'Iniciando sesión…' : 'Iniciar sesión'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.allowGoogle) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          tr('o continúa con'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                ),
                AccessGoogleButton(
                  key: const Key('login-google'),
                  onPressed: _busy ? null : _signInWithGoogle,
                  isLoading: _pending == _SignInMethod.google,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => ScaffoldMessenger(
        key: _messengerKey,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.mist,
          ),
          child: Scaffold(
            backgroundColor: AppColors.profileCanvas,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gutter = constraints.maxWidth < 360
                          ? AppSpacing.md
                          : AppSpacing.xl;
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LoginHero(
                                topInset: systemPadding.top,
                                gutter: gutter,
                                onBack: _busy ? null : () => _go('/welcome'),
                              ),
                              _formContent(context, gutter),
                              LoginFooter(
                                bottomInset: systemPadding.bottom,
                                gutter: gutter,
                                onRegister: _busy
                                    ? null
                                    : () => _go('/register'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _LoginField extends StatelessWidget {
  const _LoginField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.xxs,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ),
      Semantics(label: label, child: child),
    ],
  );
}
