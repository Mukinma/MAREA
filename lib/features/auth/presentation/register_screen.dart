
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/legal/legal_screens.dart';
import 'package:marea/features/profile/models/profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.controller,
    super.key,
  });

  final AppSessionController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late AccessConsentDraft _consent =
      AccessConsentDraft(widget.controller);

  UserType _type = UserType.general;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _checking = false;
  bool _reloadingLegal = false;
  bool _googleLoading = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  static const Color _blue = Color(0xFF064BD5);
  static const Color _navy = Color(0xFF071D49);
  static const Color _muted = Color(0xFF72829A);
  static const Color _background = Color(0xFFF6FBFF);

  bool get _busy =>
      _checking ||
      _reloadingLegal ||
      _googleLoading ||
      widget.controller.isBusy;

  @override
  void didUpdateWidget(covariant RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _consent.dispose();
      _consent = AccessConsentDraft(widget.controller);
    }
  }

  @override
  void dispose() {
    _consent.dispose();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _back() {
    if (_busy) return;

    widget.controller.clearFeedback();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  void _navigateToLogin() {
    if (_busy) return;

    widget.controller.clearFeedback();

    context.goWithAccessEmail(
      '/login',
      email: _email.text.trim(),
    );
  }

  void _showMessage(String message) {
    final messenger = _messengerKey.currentState;

    if (messenger != null) {
      showAccessAlert(messenger, message);
    }
  }

  Future<void> _reloadLegal() async {
    if (_busy) return;

    setState(() => _reloadingLegal = true);

    try {
      await widget.controller.reloadLegal();
    } finally {
      if (mounted) {
        setState(() => _reloadingLegal = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy) return;

    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!widget.controller.legalPolicy.canRegister ||
        !_consent.hasDocuments) {
      _showMessage(
        'El registro no está disponible por el momento.',
      );
      return;
    }

    final consent = _consent.consent;

    if (consent == null || !_consent.isComplete) {
      _showMessage(
        'Debes completar los consentimientos requeridos.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _checking = true);

    try {
      final normalizedUsername =
          FormValidators.normalizeUsername(_username.text);

      final available =
          await widget.controller.isUsernameAvailable(
        normalizedUsername,
      );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _usernameError =
              'Este nombre de usuario ya está ocupado.';
        });
        _formKey.currentState?.validate();
        return;
      }

      final outcome = await widget.controller.signUp(
        fullName: _name.text.trim(),
        username: normalizedUsername,
        email: _email.text.trim(),
        password: _password.text,
        userType: _type,
        consent: consent,
      );

      if (!mounted) return;

      if (outcome == SignUpOutcome.confirmationRequired) {
        context.goWithAccessEmail(
          '/check-email',
          email: _email.text.trim(),
        );
        return;
      }

      if (outcome != null) {
        return;
      }

      final failure = widget.controller.failure;

      if (failure == null) return;

      if (failure.kind == AppFailureKind.usernameTaken) {
        setState(() {
          _usernameError = failure.message;
        });
        _formKey.currentState?.validate();
      } else if (
          failure.kind == AppFailureKind.emailAlreadyUsed) {
        setState(() {
          _emailError = failure.message;
        });
        _formKey.currentState?.validate();
      } else if (
          failure.kind == AppFailureKind.weakPassword) {
        setState(() {
          _passwordError = failure.message;
        });
        _formKey.currentState?.validate();
      } else {
        _showMessage(failure.message);
      }

      widget.controller.clearFeedback();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No pudimos completar el registro. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    setState(() => _googleLoading = true);

    try {
      final ok = await widget.controller.signInWithGoogle(
        redirectTo: kIsWeb
            ? Uri.base.origin
            : AppConfig.fromEnvironment()
                .mobileOAuthRedirect,
      );

      if (!mounted) return;

      if (!ok && widget.controller.failure != null) {
        _showMessage(widget.controller.failure!.message);
        widget.controller.clearFeedback();
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No se pudo conectar con Google.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  InputDecoration _decoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Color(0xFFDCE5EF),
      ),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: _muted,
        size: 21,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: _blue,
          width: 1.5,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 245,
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
            top: 12,
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
                onPressed: _busy ? null : _back,
              ),
            ),
          ),

          Positioned(
            top: 17,
            left: 85,
            right: 85,
            child: Center(
              child: Image.asset(
                'assets/brand/MAREA_LOGOTIPO.png',
                width: 125,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Positioned(
            top: 86,
            left: 24,
            right: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tu idea tiene\nun lugar aquí!',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crea tu cuenta y empieza a\n'
                  'conectar con tu comunidad.',
                  style: TextStyle(
                    color: Color(0xFF60758B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Mascota de MAREA: posición corregida.
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
            height: 40,
            child: CustomPaint(
              painter: _RegisterWavePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formContent(bool canRegister) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        26, 10, 26, 25,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _label('Nombre completo'),
              TextFormField(
                key: const Key('register-name'),
                controller: _name,
                enabled: !_busy,
                autofillHints: const [
                  AutofillHints.name,
                ],
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Escribe tu nombre',
                  Icons.person_outline,
                ),
                validator: FormValidators.fullName,
              ),

              const SizedBox(height: 13),

              _label('Nombre de usuario'),
              TextFormField(
                key: const Key('register-username'),
                controller: _username,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Elige un usuario',
                  Icons.alternate_email,
                ),
                validator: (value) =>
                    FormValidators.username(value) ??
                    _usernameError,
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
              ),

              const SizedBox(height: 13),

              _label('Correo electrónico'),
              TextFormField(
                key: const Key('register-email'),
                controller: _email,
                enabled: !_busy,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                ],
                decoration: _decoration(
                  'tu@correo.com',
                  Icons.mail_outline,
                ),
                validator: (value) =>
                    FormValidators.email(
                      value?.trim(),
                    ) ??
                    _emailError,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),

              const SizedBox(height: 13),

              _label('Contraseña'),
              TextFormField(
                key: const Key('register-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: _obscurePassword,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Mínimo 8 caracteres',
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
                    FormValidators.password(value) ??
                    _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),

              const SizedBox(height: 13),

              _label('Confirmar contraseña'),
              TextFormField(
                controller: _confirmPassword,
                enabled: !_busy,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                decoration: _decoration(
                  'Repite tu contraseña',
                  Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _muted,
                    ),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _obscureConfirm =
                                !_obscureConfirm;
                          }),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu contraseña.';
                  }
                  if (value != _password.text) {
                    return 'Las contraseñas no coinciden.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 13),

              _label('Tipo de perfil'),
              DropdownButtonFormField<UserType>(
                initialValue: _type,
                decoration: _decoration(
                  'Selecciona tu perfil',
                  Icons.groups_outlined,
                ),
                items: UserType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.label,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),

              const SizedBox(height: 17),

              if (!canRegister)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: AccessFeedback(
                    message: _consent.hasDocuments
                        ? 'El registro está pausado.'
                        : 'No pudimos cargar los documentos de MAREA.',
                    action: TextButton(
                      onPressed:
                          _busy ? null : _reloadLegal,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFDCE5EF),
                  ),
                ),
                child: ConsentFields(
                  terms: _consent.terms,
                  adult: _consent.adult,
                  enabled: !_busy && canRegister,
                  onTermsChanged: (value) {
                    setState(() {
                      _consent.terms = value;
                    });
                  },
                  onAdultChanged: (value) {
                    setState(() {
                      _consent.adult = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  key: const Key('register-continue'),
                  onPressed: _busy ||
                          !canRegister ||
                          !_consent.isComplete
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF9BB5E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                  ),
                  child: _checking ||
                          widget.controller.isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              'Crear mi cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 14),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 17,
                ),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(
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

              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed:
                      _busy ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _navy,
                    side: const BorderSide(
                      color: Color(0xFFD6E3EF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                  ),
                  child: _googleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/onboarding/google_g.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continuar con Google',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),

              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment:
                    WrapCrossAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes cuenta?',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _busy ? null : _navigateToLogin,
                    child: const Text(
                      'Inicia sesión',
                      style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
        final canRegister =
            widget.controller.legalPolicy.canRegister &&
            _consent.hasDocuments;

        return PopScope(
          canPop: !_busy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_busy) _back();
          },
          child: ScaffoldMessenger(
            key: _messengerKey,
            child: Scaffold(
              backgroundColor: _background,
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 430,
                    ),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                      child: Column(
                        children: [
                          _header(),
                          _formContent(canRegister),
                        ],
                      ),
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

class _RegisterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.25,
        size.height * 1.2,
        size.width * 0.35,
        0,
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
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}
