
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';

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

  late final _emailController =
      TextEditingController(text: widget.email);
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  _SignInMethod? _pending;
  AppFailure? _passwordFailure;

  static const _blue = Color(0xFF064BD5);
  static const _navy = Color(0xFF071D49);
  static const _muted = Color(0xFF72829A);

  bool get _busy =>
      _pending != null || widget.controller.isBusy;

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
    final needsConfirmation =
        failure?.kind == AppFailureKind.emailNotConfirmed;

    setState(() {
      _pending = null;
      _passwordFailure =
          needsConfirmation ? failure : null;
    });

    if (failure != null) {
      widget.controller.clearFeedback();

      if (!needsConfirmation) {
        final message = switch (failure.message) {
          'No pudimos conectarnos. Inténtalo nuevamente.' ||
          'Espera un momento antes de volver a intentarlo.' =>
            failure.message,
          _ =>
            'Revisa tu correo y contraseña e inténtalo de nuevo.',
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

  InputDecoration _decoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: _muted, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFDCE5EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFDCE5EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _blue,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE6FAFF),
                    Color(0xFFD8F2FF),
                    Color(0xFFEEF8FF),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 15,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: _navy,
                  size: 18,
                ),
                onPressed:
                    _busy ? null : () => _go('/welcome'),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 85,
            right: 85,
            child: Center(
              child: Image.asset(
                'assets/brand/MAREA_LOGOTIPO.png',
                height: 46,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Positioned(
            left: 26,
            top: 91,
            right: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola de nuevo!',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Tu ciudad te está esperando.\n'
                  'Inicia sesión y sigue explorando\n'
                  'todo lo que está cerca de ti.',
                  style: TextStyle(
                    color: Color(0xFF60758B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Mascota de MAREA corregida.
          Positioned(
            right: 8,
            bottom: 25,
            width: 155,
            child: Image.asset(
              'assets/auth_design/mascota_login.png',
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 42,
            child: CustomPaint(
              painter: _LoginWavePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blueButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _busy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF8FAEEB),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _pending == _SignInMethod.password
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.arrow_forward, size: 21),
                ],
              ),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _busy ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _navy,
          side: const BorderSide(
            color: Color(0xFFD6E3EF),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _pending == _SignInMethod.google
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/onboarding/google_g.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _formContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 13, 27, 22),
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          autovalidateMode:
              AutovalidateMode.onUserInteractionIfError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel('Correo electrónico'),
              TextFormField(
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
                  Icons.mail_outline,
                ),
                validator: (value) =>
                    FormValidators.email(value?.trim()),
                onChanged: (_) => _clearPasswordFailure(),
              ),

              const SizedBox(height: 18),

              _fieldLabel('Contraseña'),
              TextFormField(
                key: const Key('login-password'),
                controller: _passwordController,
                enabled: !_busy,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: _decoration(
                  'Introduce tu contraseña',
                  Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _muted,
                    ),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          }),
                  ),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty
                        ? 'Escribe una contraseña.'
                        : null,
                onChanged: (_) => _clearPasswordFailure(),
                onFieldSubmitted: (_) => _submit(),
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
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              if (_passwordFailure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      const Text(
                        'Confirma tu correo para entrar a MAREA.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _navy),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _go(
                                  '/check-email',
                                  email:
                                      _emailController.text.trim(),
                                ),
                        child: const Text('Confirmar mi correo'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              _blueButton(),

              if (widget.allowGoogle) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 19),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Text(
                          'o continúa con',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                _googleButton(),
              ],

              const SizedBox(height: 25),

              Container(
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFDAF7FF),
                      Color(0xFFF5FCFF),
                      Color(0xFFE1F7FF),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '¿Aún no tienes cuenta?',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _busy ? null : () => _go('/register'),
                      child: const Text(
                        'Crea tu cuenta',
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return ScaffoldMessenger(
          key: _messengerKey,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6FBFF),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _header(),
                        _formContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.25,
        size.height * 1.2,
        size.width * 0.35,
        size.height * 0.0,
        size.width * 0.60,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.8,
        size.width * 0.88,
        size.height * 0.05,
        size.width,
        size.height * 0.30,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFF6FBFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}
