import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/features/auth/presentation/intro_waves.dart';
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Opacity(opacity: 0, child: Text('Iniciar sesión')),
          Image.asset(
            'assets/brand/MAREA_LOGOTIPO.png',
            width: 190,
            height: 48,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _LoginMascot extends StatelessWidget {
  const _LoginMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 138,
      child: CustomPaint(painter: _LoginMascotPainter()),
    );
  }
}

class _LoginMascotPainter extends CustomPainter {
  const _LoginMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 154;
    canvas.scale(scale);

    final navy = const Color(0xFF074C9A);
    final blue = const Color(0xFF0877DF);
    final cyan = const Color(0xFF16BFD1);

    canvas.drawOval(Rect.fromLTWH(34, 54, 112, 78), Paint()..color = blue);
    canvas.drawOval(
      Rect.fromLTWH(46, 18, 76, 82),
      Paint()..color = const Color(0xFF126FE0),
    );

    final beak = Path()
      ..moveTo(82, 74)
      ..cubicTo(82, 58, 104, 52, 116, 64)
      ..cubicTo(128, 76, 118, 92, 102, 94)
      ..cubicTo(89, 96, 82, 86, 82, 74)
      ..close();
    canvas.drawPath(beak, Paint()..color = navy);

    canvas.drawCircle(const Offset(94, 63), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(97, 65),
      6,
      Paint()..color = const Color(0xFF11254C),
    );

    canvas.drawOval(
      const Rect.fromLTWH(74, 78, 28, 18),
      Paint()..color = const Color(0xFFE84A6A),
    );

    canvas.drawOval(
      const Rect.fromLTWH(50, 64, 26, 50),
      Paint()..color = const Color(0xFF0877DF),
    );

    final leftFin = Path()
      ..moveTo(50, 82)
      ..cubicTo(36, 82, 28, 72, 20, 58)
      ..cubicTo(13, 46, 3, 50, 8, 62)
      ..lineTo(24, 98)
      ..close();
    canvas.drawPath(leftFin, Paint()..color = blue);

    final rightFin = Path()
      ..moveTo(114, 108)
      ..cubicTo(128, 104, 146, 108, 150, 118)
      ..cubicTo(154, 128, 138, 132, 124, 128)
      ..close();
    canvas.drawPath(rightFin, Paint()..color = blue);

    final crest = Path()
      ..moveTo(94, 24)
      ..cubicTo(94, 10, 100, 2, 108, 0)
      ..cubicTo(116, 10, 112, 24, 104, 32)
      ..close();
    canvas.drawPath(crest, Paint()..color = cyan);

    final leftSpray = Path()
      ..moveTo(32, 52)
      ..lineTo(18, 38)
      ..moveTo(38, 42)
      ..lineTo(34, 24)
      ..moveTo(44, 48)
      ..lineTo(54, 34);
    canvas.drawPath(
      leftSpray,
      Paint()
        ..color = cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    final foot = Path()
      ..moveTo(48, 124)
      ..cubicTo(38, 132, 34, 138, 44, 142)
      ..cubicTo(58, 144, 68, 138, 68, 128)
      ..close();
    canvas.drawPath(foot, Paint()..color = navy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
        final theme = Theme.of(context);
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border),
        );
        final loginTheme = theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.actionBlue,
                width: 2,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: theme.outlinedButtonTheme.style?.copyWith(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              minimumSize: const WidgetStatePropertyAll(Size(48, 68)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005CB8),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size(48, 68),
            ),
          ),
        );

        final content = Theme(
          data: loginTheme,
          child: Scaffold(
            key: const ValueKey('login-mockup-screen'),
            backgroundColor: const Color(0xFFF7FCFF),
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 600;
                  final horizontal = narrow
                      ? 24.0
                      : (constraints.maxWidth - 520).clamp(24.0, 80.0) / 2;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                          ? 24
                          : 0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontal,
                                  18,
                                  horizontal,
                                  0,
                                ),
                                child: const _LoginHeader(),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontal,
                                  20,
                                  horizontal,
                                  0,
                                ),
                                child: SizedBox(
                                  height: 154,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 150,
                                        top: 0,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '¡Hola de nuevo!',
                                              style: theme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontSize: 34,
                                                    height: 1.08,
                                                    color: AppColors.brandNavy,
                                                  ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'Tu ciudad te está esperando.\nInicia sesión y sigue explorando\ntodo lo que está cerca de ti.',
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 17,
                                                    height: 1.38,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: const IgnorePointer(
                                          child: _LoginMascot(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontal,
                                ),
                                child: AutofillGroup(
                                  onDisposeAction: AutofillContextAction.cancel,
                                  child: Form(
                                    key: _formKey,
                                    autovalidateMode: AutovalidateMode
                                        .onUserInteractionIfError,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AccessTextField(
                                          key: const Key('login-email'),
                                          enabled: !_busy,
                                          controller: _emailController,
                                          label: core_l10n.AppLocalizations.tr(
                                            'Correo',
                                          ),
                                          hint: 'tu@correo.com',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          validator: (value) =>
                                              FormValidators.email(
                                                value?.trim(),
                                              ),
                                          onChanged: (_) =>
                                              _clearPasswordFailure(),
                                        ),
                                        const SizedBox(height: 18),
                                        AccessTextField(
                                          key: const Key('login-password'),
                                          enabled: !_busy,
                                          controller: _passwordController,
                                          label: core_l10n.AppLocalizations.tr(
                                            'Contraseña',
                                          ),
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          validator: (value) =>
                                              (value ?? '').isEmpty
                                              ? core_l10n.AppLocalizations.tr(
                                                  'Escribe una contraseña.',
                                                )
                                              : null,
                                          onChanged: (_) =>
                                              _clearPasswordFailure(),
                                          onFieldSubmitted: (_) => _submit(),
                                          suffixIcon: IconButton(
                                            tooltip: _obscurePassword
                                                ? core_l10n.AppLocalizations.tr(
                                                    'Mostrar contraseña',
                                                  )
                                                : core_l10n.AppLocalizations.tr(
                                                    'Ocultar contraseña',
                                                  ),
                                            onPressed: _busy
                                                ? null
                                                : () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              minimumSize: const Size(48, 44),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                            ),
                                            onPressed: _busy
                                                ? null
                                                : () => _go(
                                                    '/recover-password',
                                                    email: _emailController.text
                                                        .trim(),
                                                  ),
                                            child: Text(
                                              core_l10n.AppLocalizations.tr(
                                                'Olvidé mi contraseña',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                                                      email: _emailController
                                                          .text
                                                          .trim(),
                                                    ),
                                              child: Text(
                                                core_l10n.AppLocalizations.tr(
                                                  'Confirmar mi correo',
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        SizedBox(
                                          height: 68,
                                          child: PrimaryButton(
                                            label:
                                                core_l10n.AppLocalizations.tr(
                                                  'Iniciar sesión',
                                                ),
                                            loadingLabel:
                                                core_l10n.AppLocalizations.tr(
                                                  'Iniciando sesión…',
                                                ),
                                            isLoading:
                                                _pending ==
                                                _SignInMethod.password,
                                            onPressed: _busy ? null : _submit,
                                          ),
                                        ),
                                        if (widget.allowGoogle) ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              spacing: 12,
                                              children: [
                                                Expanded(child: Divider()),
                                                Text(
                                                  'o continúa con',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                Expanded(child: Divider()),
                                              ],
                                            ),
                                          ),
                                          AccessGoogleButton(
                                            key: const Key('login-google'),
                                            isLoading:
                                                _pending ==
                                                _SignInMethod.google,
                                            onPressed: _busy
                                                ? null
                                                : _signInWithGoogle,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 100,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: -28,
                                      height: 88,
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: const IntroWavesPainter(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      height: 56,
                                      child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEAF7FF),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              const Text(
                                                '¿Aún no tienes cuenta?',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _go('/register'),
                                                child: const Text(
                                                  'Crear cuenta',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        return ScaffoldMessenger(key: _messengerKey, child: content);
      },
    );
  }
}
