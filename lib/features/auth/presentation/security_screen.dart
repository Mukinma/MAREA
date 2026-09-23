import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({
    required this.controller,
    this.changeEmail = false,
    this.recovery = false,
    super.key,
  });
  final AppSessionController controller;
  final bool changeEmail, recovery;
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _new = TextEditingController(),
      _confirm = TextEditingController(),
      _nonce = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    _nonce.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = widget.changeEmail
        ? await widget.controller.changeEmail(_new.text, _current.text)
        : await widget.controller.changePassword(
            _new.text,
            currentPassword: widget.recovery ? null : _current.text,
            nonce: _nonce.text.trim(),
          );
    if (!mounted || !ok) return;
    _current.clear();
    _new.clear();
    _confirm.clear();
    _nonce.clear();
    if (widget.recovery) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.changeEmail ? 'Cambiar correo' : 'Cambiar contraseña'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (_, _) => Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.changeEmail
                        ? 'El cambio necesita confirmación en tus correos. Hasta completarla seguirás usando el actual.'
                        : 'Elige una contraseña única. No uses tu nombre ni la misma contraseña de otros servicios.',
                  ),
                  const SizedBox(height: 24),
                  if (!widget.recovery) ...[
                    MareaTextField(
                      controller: _current,
                      label: 'Contraseña actual',
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => v == null || v.isEmpty
                          ? 'Escribe tu contraseña actual.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  MareaTextField(
                    controller: _new,
                    label: widget.changeEmail
                        ? 'Nuevo correo'
                        : 'Nueva contraseña',
                    obscureText: !widget.changeEmail && _obscure,
                    keyboardType: widget.changeEmail
                        ? TextInputType.emailAddress
                        : TextInputType.visiblePassword,
                    autofillHints: [
                      widget.changeEmail
                          ? AutofillHints.email
                          : AutofillHints.newPassword,
                    ],
                    validator: widget.changeEmail
                        ? FormValidators.email
                        : FormValidators.password,
                    suffixIcon: widget.changeEmail
                        ? null
                        : IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                  ),
                  if (!widget.changeEmail) ...[
                    const SizedBox(height: 16),
                    MareaTextField(
                      controller: _confirm,
                      label: 'Confirmar nueva contraseña',
                      obscureText: _obscure,
                      validator: (v) =>
                          FormValidators.confirmPassword(v, _new.text),
                    ),
                    if (!widget.recovery) ...[
                      const SizedBox(height: 16),
                      MareaTextField(
                        controller: _nonce,
                        label: 'Código de seguridad (si se solicita)',
                        keyboardType: TextInputType.number,
                      ),
                      TextButton(
                        onPressed: widget.controller.isBusy
                            ? null
                            : widget.controller.requestReauthentication,
                        child: const Text(
                          'Enviar código de seguridad a mi correo',
                        ),
                      ),
                    ],
                  ],
                  SessionFeedback(controller: widget.controller),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: widget.changeEmail
                        ? 'Solicitar cambio de correo'
                        : 'Guardar contraseña',
                    isLoading: widget.controller.isBusy,
                    onPressed: _save,
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
