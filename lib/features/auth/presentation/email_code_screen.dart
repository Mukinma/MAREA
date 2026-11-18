import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/shared/widgets/primary_button.dart';

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

enum _CodeAction { send, verify }

class _EmailCodeScreenState extends State<EmailCodeScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email?.trim());
  final _code = TextEditingController();
  Timer? _timer;
  String? _destination;
  bool _requestAccepted = false;
  _CodeAction? _pending;
  String? _sendError;
  String? _verifyError;

  bool get _busy => _pending != null || widget.controller.isBusy;

  int get _cooldown => widget.controller.emailCooldown(
    _destination ?? _email.text.trim(),
    recovery: widget.recovery,
  );

  @override
  void initState() {
    super.initState();
    final initialEmail = _email.text;
    if (!widget.recovery &&
        FormValidators.email(initialEmail) == null &&
        _cooldown > 0) {
      _destination = initialEmail;
      _requestAccepted = true;
    }
    _watchCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _watchCooldown() {
    _timer?.cancel();
    if (_cooldown == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
      if (_cooldown == 0) timer.cancel();
    });
  }

  String _failureMessage(String fallback) {
    final failure = widget.controller.failure;
    return failure?.kind == AppFailureKind.general
        ? failure!.message
        : fallback;
  }

  Future<void> _send() async {
    if (_busy || _cooldown > 0) return;
    final destination = _destination;
    if (destination == null && !_emailForm.currentState!.validate()) return;
    final email = destination ?? _email.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = _CodeAction.send;
      _sendError = null;
      _verifyError = null;
    });
    final ok = await widget.controller.sendCode(
      email,
      recovery: widget.recovery,
    );
    if (!mounted) return;
    setState(() {
      _pending = null;
      if (ok) {
        _destination = email;
        _email.text = email;
        _code.clear();
        _requestAccepted = true;
      } else {
        _sendError = _failureMessage(
          'No pudimos solicitar el código. Inténtalo de nuevo en unos minutos.',
        );
      }
    });
    _watchCooldown();
  }

  void _clearSendError() {
    _watchCooldown();
    setState(() => _sendError = null);
    if (widget.controller.failure != null) widget.controller.clearFeedback();
  }

  void _enterCode() {
    if (_busy || !_emailForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    setState(() {
      _destination = _email.text.trim();
      _requestAccepted = false;
      _sendError = null;
    });
  }

  void _changeEmail() {
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    setState(() {
      _destination = null;
      _code.clear();
      _requestAccepted = false;
      _sendError = null;
      _verifyError = null;
    });
    _watchCooldown();
  }

  void _back() {
    if (_destination != null) {
      _changeEmail();
      return;
    }
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    context.goWithAccessEmail('/login', email: _email.text.trim());
  }

  Future<void> _verify() async {
    if (_busy || !_codeForm.currentState!.validate()) return;
    final destination = _destination!;
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = _CodeAction.verify;
      _verifyError = null;
      _sendError = null;
    });
    final ok = await widget.controller.verifyCode(
      destination,
      _code.text,
      recovery: widget.recovery,
    );
    if (!mounted) return;
    setState(() {
      _pending = null;
      if (!ok) {
        _verifyError = _failureMessage(
          'No pudimos verificar el código. Revisa el correo y vuelve a intentarlo.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final destination = _destination;
        final cooldown = _cooldown;
        return AccessLayout(
          title: widget.recovery
              ? destination == null
                    ? 'Recupera tu acceso'
                    : 'Verifica el código'
              : 'Verifica tu correo',
          description: destination != null
              ? 'Escribe el código del correo. Si no lo encuentras, revisa spam.'
              : widget.recovery
              ? 'Recibirás un código si hay una cuenta con ese correo.'
              : 'Usa el correo con el que te registraste.',
          showBack: true,
          onBack: _busy ? null : _back,
          step: destination == null ? 1 : 2,
          totalSteps: widget.recovery ? 3 : 2,
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: destination == null
                ? _requestForm(cooldown)
                : _verifyForm(context, destination, cooldown),
          ),
        );
      },
    );
  }

  Widget _requestForm(int cooldown) {
    return Form(
      key: _emailForm,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccessTextField(
            key: const Key('code-destination'),
            enabled: !_busy,
            controller: _email,
            label: 'Correo',
            hint: 'tu@correo.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: (value) => FormValidators.email(value?.trim()),
            onChanged: (_) => _clearSendError(),
            onFieldSubmitted: (_) => _send(),
          ),
          if (_sendError case final error?) ...[
            const SizedBox(height: AppSpacing.sm),
            AccessFeedback(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: cooldown > 0
                ? 'Solicitar de nuevo en ${cooldown}s'
                : 'Enviar código',
            loadingLabel: 'Enviando código…',
            isLoading: _pending == _CodeAction.send,
            onPressed: _busy || cooldown > 0 ? null : _send,
          ),
          TextButton(
            onPressed: _busy ? null : _enterCode,
            child: const Text('Ya tengo un código'),
          ),
        ],
      ),
    );
  }

  Widget _verifyForm(BuildContext context, String destination, int cooldown) {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _codeForm,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Correo',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(destination, style: textTheme.titleMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy ? null : _changeEmail,
              child: const Text('Usar otro correo'),
            ),
          ),
          if (_requestAccepted) ...[
            const AccessFeedback(
              message:
                  'Si el correo corresponde a tu cuenta, recibirás el código.',
              error: false,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AccessTextField(
            key: const Key('email-code'),
            enabled: !_busy,
            controller: _code,
            label: 'Código',
            helperText: 'Puedes pegar el código completo.',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _verify(),
            validator: (value) => RegExp(r'^\d{6,10}$').hasMatch(value ?? '')
                ? null
                : 'Escribe el código del correo (6 a 10 dígitos).',
            onChanged: (_) {
              if (_verifyError == null) return;
              setState(() => _verifyError = null);
              widget.controller.clearFeedback();
            },
          ),
          if (_verifyError case final error?) ...[
            const SizedBox(height: AppSpacing.sm),
            AccessFeedback(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Verificar código',
            loadingLabel: 'Verificando código…',
            isLoading: _pending == _CodeAction.verify,
            onPressed: _busy ? null : _verify,
          ),
          if (_sendError case final error?) ...[
            const SizedBox(height: AppSpacing.sm),
            AccessFeedback(message: error),
          ],
          TextButton(
            onPressed: _busy || cooldown > 0 ? null : _send,
            child: Text(
              _pending == _CodeAction.send
                  ? 'Reenviando código…'
                  : cooldown > 0
                  ? 'Reenviar en ${cooldown}s'
                  : 'Reenviar código',
            ),
          ),
        ],
      ),
    );
  }
}
