import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/legal/legal_screens.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _identityForm = GlobalKey<FormState>(),
      _accessForm = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _username = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  UserType? _type;
  int _step = 0;
  bool _obscure = true, _terms = false, _adult = false, _checking = false;
  String? _usernameError, _emailError, _passwordError, _error;
  bool get _busy => _checking || widget.controller.isBusy;
  @override
  void dispose() {
    for (final field in [_name, _username, _email, _password]) {
      field.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_busy) return;
    widget.controller.clearFeedback();
    if (_step == 0) {
      context.go('/welcome');
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
  }

  Future<void> _next() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (_type == null) {
        setState(() => _error = 'Elige un perfil.');
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    if (!_identityForm.currentState!.validate()) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final available = await widget.controller.isUsernameAvailable(
        FormValidators.normalizeUsername(_username.text),
      );
      if (!mounted) return;
      if (!available) {
        setState(() => _usernameError = 'Este usuario ya está ocupado.');
        _identityForm.currentState!.validate();
      } else {
        setState(() => _step = 2);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppFailureMapper.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        !_accessForm.currentState!.validate() ||
        !_terms ||
        !_adult ||
        !widget.controller.legalPolicy.canRegister) {
      return;
    }
    FocusScope.of(context).unfocus();
    final outcome = await widget.controller.signUp(
      fullName: _name.text.trim(),
      username: FormValidators.normalizeUsername(_username.text),
      email: _email.text.trim(),
      password: _password.text,
      userType: _type!,
      consent: LegalConsent(
        termsVersion: widget.controller.legalPolicy.terms!.version,
        privacyVersion: widget.controller.legalPolicy.privacy!.version,
        acceptedTerms: _terms,
        adultConfirmed: _adult,
      ),
    );
    if (!mounted) return;
    if (outcome == SignUpOutcome.confirmationRequired) {
      context.go('/check-email', extra: _email.text.trim());
    } else if (outcome == null) {
      final failure = widget.controller.failure;
      if (failure?.kind == AppFailureKind.usernameTaken ||
          failure?.message.contains('usuario') == true) {
        setState(() {
          _step = 1;
          _usernameError = failure!.message;
        });
        widget.controller.clearFeedback();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _identityForm.currentState?.validate();
        });
      } else if (failure?.kind == AppFailureKind.emailAlreadyUsed ||
          failure?.kind == AppFailureKind.weakPassword) {
        setState(() {
          if (failure!.kind == AppFailureKind.emailAlreadyUsed) {
            _emailError = failure.message;
          } else {
            _passwordError = failure.message;
          }
        });
        widget.controller.clearFeedback();
        _accessForm.currentState?.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => PopScope(
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthLayout(
        register: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Atrás',
                  onPressed: _busy ? null : _back,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                Text(
                  '${_step + 1} de 3',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [
                '¿Qué perfil quieres crear?',
                'Tu perfil',
                'Crea tu acceso',
              ][_step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_step + 1) / 3,
                minHeight: 4,
                color: AppColors.aquaDark,
                backgroundColor: AppColors.mint,
              ),
            ),
            const SizedBox(height: 28),
            if (_step == 0)
              ProfileTypePicker(
                value: _type,
                enabled: !_busy,
                onChanged: (type) => setState(() {
                  _type = type;
                  _error = null;
                }),
              ),
            if (_step == 1)
              AutofillGroup(
                child: Form(
                  key: _identityForm,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ProfileTypeIcon(type: _type!),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _type!.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      MareaTextField(
                        key: const Key('register-name'),
                        controller: _name,
                        label: _type!.nameLabel,
                        enabled: !_busy,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: FormValidators.fullName,
                      ),
                      const SizedBox(height: 16),
                      MareaTextField(
                        key: const Key('register-username'),
                        controller: _username,
                        label: 'Usuario',
                        prefixText: '@',
                        enabled: !_busy,
                        textInputAction: TextInputAction.done,
                        validator: (v) =>
                            FormValidators.username(v) ?? _usernameError,
                        onChanged: (_) => setState(() => _usernameError = null),
                        onFieldSubmitted: (_) => _next(),
                      ),
                    ],
                  ),
                ),
              ),
            if (_step == 2)
              AutofillGroup(
                child: Form(
                  key: _accessForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MareaSurface(
                        inset: true,
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, bounds) {
                            final change = TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _step = 0),
                              child: const Text('Cambiar'),
                            );
                            final compact =
                                bounds.maxWidth < 320 ||
                                MediaQuery.textScalerOf(context).scale(1) > 1.3;
                            final identity = Row(
                              children: [
                                ProfileTypeIcon(type: _type!),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _type!.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!compact) change,
                              ],
                            );
                            return compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      identity,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: change,
                                      ),
                                    ],
                                  )
                                : identity;
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'El tipo de perfil queda fijo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MareaTextField(
                        key: const Key('register-email'),
                        controller: _email,
                        label: 'Correo',
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            FormValidators.email(v?.trim()) ?? _emailError,
                        onChanged: (_) {
                          final hadError = _emailError != null;
                          setState(() => _emailError = null);
                          if (hadError) _accessForm.currentState?.validate();
                        },
                      ),
                      const SizedBox(height: 16),
                      MareaTextField(
                        key: const Key('register-password'),
                        controller: _password,
                        label: 'Contraseña',
                        hint: 'Mínimo 8 caracteres',
                        enabled: !_busy,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        validator: (v) =>
                            FormValidators.password(v) ?? _passwordError,
                        onChanged: (_) => setState(() => _passwordError = null),
                        onFieldSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!widget.controller.legalPolicy.canRegister) ...[
                        Text(
                          widget.controller.legalError ??
                              'El registro no está disponible. Intenta de nuevo.',
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : widget.controller.reloadLegal,
                          child: const Text('Reintentar'),
                        ),
                      ],
                      ConsentFields(
                        terms: _terms,
                        adult: _adult,
                        enabled:
                            !_busy && widget.controller.legalPolicy.canRegister,
                        onTermsChanged: (v) => setState(() => _terms = v),
                        onAdultChanged: (v) => setState(() => _adult = v),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error ?? widget.controller.failure?.message
                case final String error)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            const SizedBox(height: 28),
            PrimaryButton(
              key: const Key('register-continue'),
              label: _step == 2 ? 'Crear cuenta' : 'Continuar',
              isLoading: _busy,
              onPressed:
                  _busy ||
                      (_step == 2 &&
                          (!_terms ||
                              !_adult ||
                              !widget.controller.legalPolicy.canRegister))
                  ? null
                  : _step == 2
                  ? _submit
                  : _next,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      widget.controller.clearFeedback();
                      context.go('/login', extra: _email.text.trim());
                    },
              child: const Text('Iniciar sesión'),
            ),
            if (_step == 2 && _emailError != null)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        widget.controller.clearFeedback();
                        context.go(
                          '/recover-password',
                          extra: _email.text.trim(),
                        );
                      },
                child: const Text('Recuperar contraseña'),
              ),
          ],
        ),
      ),
    ),
  );
}
