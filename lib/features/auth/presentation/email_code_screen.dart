import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class EmailCodeScreen extends StatefulWidget {
  const EmailCodeScreen({
    required this.controller,
    required this.recovery,
    this.email,
    super.key,
  });
  final AppSessionController controller;
  final bool recovery;
  final String? email;
  @override
  State<EmailCodeScreen> createState() => _EmailCodeScreenState();
}

class _EmailCodeScreenState extends State<EmailCodeScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  final _code = TextEditingController();
  Timer? _timer;
  bool _codeStep = false;
  String? _destination;
  bool _requestAccepted = false;
  @override
  void initState() {
    super.initState();
    final initialEmail = widget.email?.trim() ?? '';
    _codeStep =
        !widget.recovery &&
        FormValidators.email(initialEmail) == null &&
        widget.controller.emailCooldown(initialEmail, recovery: false) > 0;
    if (_codeStep) _destination = initialEmail;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (widget.controller.isBusy) return;
    final destination = _destination ?? _email.text.trim();
    final error = FormValidators.email(destination);
    if (error != null) {
      _form.currentState!.validate();
      return;
    }
    final ok = await widget.controller.sendCode(
      destination,
      recovery: widget.recovery,
    );
    if (ok && mounted) {
      setState(() {
        _destination = destination;
        _email.text = destination;
        _code.clear();
        _codeStep = true;
        _requestAccepted = true;
      });
    }
  }

  void _changeEmail() {
    widget.controller.clearFeedback();
    setState(() {
      _destination = null;
      _code.clear();
      _codeStep = false;
      _requestAccepted = false;
    });
  }

  Future<void> _verify() async {
    if (widget.controller.isBusy || !_form.currentState!.validate()) return;
    final ok = await widget.controller.verifyCode(
      _destination!,
      _code.text,
      recovery: widget.recovery,
    );
    if (ok && mounted) {
      context.go(
        widget.recovery
            ? '/reset-password'
            : widget.controller.needsLegalAcceptance
            ? '/legal/accept'
            : widget.controller.needsOnboarding
            ? '/onboarding'
            : '/profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: AnimatedBuilder(
      animation: widget.controller,
      builder: (_, _) {
        final cooldown = widget.controller.emailCooldown(
          _destination ?? _email.text,
          recovery: widget.recovery,
        );
        return Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.controller.isBusy
                      ? null
                      : () {
                          widget.controller.clearFeedback();
                          context.go('/login');
                        },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Iniciar sesión'),
                ),
              ),
              Text(
                widget.recovery ? 'Recupera tu acceso' : 'Revisa tu correo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                _codeStep
                    ? 'Introduce el código del correo de MAREA. No lo compartas con nadie.'
                    : widget.recovery
                    ? 'Escribe el correo de tu cuenta para solicitar un código y elegir una contraseña nueva.'
                    : 'Confirma el correo de tu cuenta para poder entrar a MAREA. Solicita un código o usa uno que ya hayas recibido.',
              ),
              const SizedBox(height: 24),
              if (!_codeStep)
                MareaTextField(
                  key: const Key('code-destination'),
                  enabled: !widget.controller.isBusy,
                  controller: _email,
                  label: 'Correo',
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.email,
                  onChanged: (_) {
                    widget.controller.clearFeedback();
                    setState(() {});
                  },
                ),
              if (_codeStep) ...[
                Text(
                  'Correo de destino',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _destination!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: widget.controller.isBusy ? null : _changeEmail,
                    child: const Text('Cambiar correo'),
                  ),
                ),
                const SizedBox(height: 16),
                MareaTextField(
                  key: const Key('email-code'),
                  enabled: !widget.controller.isBusy,
                  controller: _code,
                  label: 'Código del correo',
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verify(),
                  validator: (value) =>
                      RegExp(r'^\d{6,10}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Escribe el código del correo (6 a 10 dígitos).',
                ),
              ],
              SessionFeedback(controller: widget.controller),
              if (_requestAccepted && widget.controller.failure == null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Solicitud recibida. Revisa tu bandeja de entrada y spam; el mensaje puede tardar unos minutos.',
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _codeStep
                    ? 'Verificar código'
                    : cooldown > 0
                    ? 'Solicitar de nuevo en ${cooldown}s'
                    : 'Enviar código',
                isLoading: widget.controller.isBusy,
                onPressed: _codeStep
                    ? _verify
                    : cooldown == 0
                    ? _send
                    : null,
              ),
              if (_codeStep)
                TextButton(
                  onPressed: cooldown == 0 && !widget.controller.isBusy
                      ? _send
                      : null,
                  child: Text(
                    cooldown > 0
                        ? 'Reenviar en ${cooldown}s'
                        : 'Reenviar código',
                  ),
                ),
              if (!_codeStep)
                TextButton(
                  onPressed: widget.controller.isBusy
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          widget.controller.clearFeedback();
                          setState(() {
                            _destination = _email.text.trim();
                            _codeStep = true;
                          });
                        },
                  child: const Text('Ya tengo un código'),
                ),
              const SizedBox(height: 12),
              Text(
                _codeStep
                    ? '¿No llegó? Comprueba el correo de destino y revisa spam. Puedes solicitar otro código al terminar la espera. Por seguridad no indicamos si existe una cuenta con ese correo.'
                    : widget.recovery
                    ? 'Por seguridad, la solicitud no indica si existe una cuenta con ese correo. Tu contraseña no cambia hasta completar la recuperación.'
                    : 'Por seguridad, la solicitud no indica si existe una cuenta con ese correo.',
              ),
            ],
          ),
        );
      },
    ),
  );
}
