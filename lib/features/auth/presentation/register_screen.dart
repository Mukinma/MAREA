import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/access_navigation.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/legal/legal_screens.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _identityForm = GlobalKey<FormState>();
  final _accessForm = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late var _consent = AccessConsentDraft(widget.controller);
  UserType _type = UserType.general;
  int _step = 0;
  bool _obscure = true, _checking = false, _reloadingLegal = false;
  bool _obscureConfirm = true, _googleLoading = false;
  bool _usernameCheckFailed = false;
  String? _usernameError, _emailError, _passwordError;

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
    for (final field in [
      _name,
      _username,
      _email,
      _password,
      _confirmPassword,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  void _showStep(int step) {
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    _messengerKey.currentState?.removeCurrentSnackBar();
    setState(() => _step = step);
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      widget.controller.clearFeedback();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/welcome');
      }
    } else {
      _showStep(_step - 1);
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_step == 0) {
      _showStep(1);
      return;
    }
    if (_usernameCheckFailed) {
      _usernameError = null;
      _usernameCheckFailed = false;
    }
    if (!_identityForm.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _checking = true);
    try {
      final available = await widget.controller.isUsernameAvailable(
        FormValidators.normalizeUsername(_username.text),
      );
      if (!mounted) return;
      if (available) {
        _showStep(2);
      } else {
        _setUsernameError(AppLocalizations.tr('Este usuario ya está ocupado.'));
      }
    } catch (_) {
      if (mounted) {
        _setUsernameError(
          AppLocalizations.tr(
            'No pudimos comprobar el usuario. Intenta de nuevo.',
          ),
          retry: true,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _setUsernameError(String? message, {bool retry = false}) {
    setState(() {
      _usernameError = message;
      _usernameCheckFailed = retry;
    });
    _identityForm.currentState?.validate();
  }

  Future<void> _reloadLegal() async {
    if (_busy) return;
    setState(() => _reloadingLegal = true);
    try {
      await widget.controller.reloadLegal();
    } finally {
      if (mounted) setState(() => _reloadingLegal = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    _messengerKey.currentState?.removeCurrentSnackBar();
    setState(() => _googleLoading = true);
    try {
      final ok = await widget.controller.signInWithGoogle(
        redirectTo: kIsWeb
            ? Uri.base.origin
            : AppConfig.fromEnvironment().mobileOAuthRedirect,
      );
      if (!mounted || ok) return;
      final failure = widget.controller.failure;
      if (failure != null) {
        widget.controller.clearFeedback();
        showAccessAlert(_messengerKey.currentState!, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showAccessAlert(
          _messengerKey.currentState!,
          AppLocalizations.tr('No se pudo conectar con Google.'),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_accessForm.currentState!.validate()) return;
    final consent = _consent.consent;
    if (consent == null || !widget.controller.legalPolicy.canRegister) return;

    FocusScope.of(context).unfocus();
    _messengerKey.currentState?.removeCurrentSnackBar();
    final outcome = await widget.controller.signUp(
      fullName: _name.text.trim(),
      username: FormValidators.normalizeUsername(_username.text),
      email: _email.text.trim(),
      password: _password.text,
      userType: _type,
      consent: consent,
    );
    if (!mounted) return;
    if (outcome == SignUpOutcome.confirmationRequired) {
      context.goWithAccessEmail('/check-email', email: _email.text.trim());
      return;
    }
    if (outcome != null) return;
    final failure = widget.controller.failure;
    if (failure == null) return;
    if (failure.kind == AppFailureKind.usernameTaken ||
        failure.message == 'Este nombre de usuario ya está ocupado.') {
      _usernameError = failure.message;
      _showStep(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _identityForm.currentState?.validate();
      });
    } else if (failure.kind == AppFailureKind.emailAlreadyUsed ||
        failure.kind == AppFailureKind.weakPassword) {
      setState(() {
        if (failure.kind == AppFailureKind.emailAlreadyUsed) {
          _emailError = failure.message;
        } else {
          _passwordError = failure.message;
        }
      });
      widget.controller.clearFeedback();
      _accessForm.currentState?.validate();
    } else {
      widget.controller.clearFeedback();
      showAccessAlert(_messengerKey.currentState!, failure.message);
    }
  }

  void _navigateToAccess(String path) {
    widget.controller.clearFeedback();
    context.goWithAccessEmail(path, email: _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final canRegister =
              widget.controller.legalPolicy.canRegister &&
              _consent.hasDocuments;
          final canContinue =
              !_busy && (_step != 2 || (canRegister && _consent.isComplete));
          return PopScope(
            canPop: _step == 0 && !_busy,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: AccessLayout(
              key: ValueKey(_step),
              messengerKey: _messengerKey,
              showBack: true,
              onBack: _busy ? null : _back,
              step: _step + 1,
              totalSteps: 3,
              compact: _step == 2,
              title: [
                AppLocalizations.tr('Tipo de perfil'),
                AppLocalizations.tr('Tu perfil'),
                AppLocalizations.tr('Tu acceso'),
              ][_step],
              description: [
                AppLocalizations.tr(
                  'Elige cómo quieres participar. Tu tipo de perfil quedará fijo al crear la cuenta.',
                ),
                AppLocalizations.tr(
                  'Así te verán y podrán encontrarte en Marea.',
                ),
                AppLocalizations.tr(
                  'Usarás este correo para verificar tu cuenta e iniciar sesión.',
                ),
              ][_step],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (_step) {
                    0 => ProfileTypePicker(
                      value: _type,
                      enabled: !_busy,
                      onChanged: (type) {
                        if (type == null) return;
                        _messengerKey.currentState?.removeCurrentSnackBar();
                        setState(() => _type = type);
                      },
                    ),
                    1 => _buildIdentityForm(),
                    _ => _buildAccessForm(canRegister),
                  },
                  SizedBox(height: _step == 2 ? 12 : 24),
                  PrimaryButton(
                    key: const Key('register-continue'),
                    label: _step == 2
                        ? AppLocalizations.tr('Crear cuenta')
                        : AppLocalizations.tr('Continuar'),
                    isLoading:
                        _checking ||
                        (widget.controller.isBusy && !_googleLoading),
                    loadingLabel: _checking
                        ? AppLocalizations.tr('Comprobando usuario…')
                        : _step == 2
                        ? AppLocalizations.tr('Creando cuenta…')
                        : null,
                    onPressed: canContinue
                        ? (_step == 2 ? _submit : _next)
                        : null,
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 12),
                    AccessGoogleButton(
                      onPressed: _busy ? null : _signInWithGoogle,
                      isLoading: _googleLoading,
                    ),
                  ],
                  if (_step == 0 || (_step == 2 && _emailError == null))
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(AppLocalizations.tr('¿Ya tienes cuenta?')),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _navigateToAccess('/login'),
                          child: Text(AppLocalizations.tr('Iniciar sesión')),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdentityForm() => Form(
    key: _identityForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _ProfileSummary(type: _type),
        AccessTextField(
          key: const Key('register-name'),
          controller: _name,
          label: AppLocalizations.tr(_type.nameLabel),
          enabled: !_busy,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          validator: FormValidators.fullName,
        ),
        AccessTextField(
          key: const Key('register-username'),
          controller: _username,
          label: AppLocalizations.tr('Usuario'),
          prefixText: '@',
          helperText: AppLocalizations.tr(
            '3 a 24 caracteres. Puedes usar letras, números, punto y guion bajo.',
          ),
          enabled: !_busy,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.done,
          validator: (v) => FormValidators.username(v) ?? _usernameError,
          onChanged: (_) {
            if (_usernameError != null) {
              _setUsernameError(null);
            }
          },
          onFieldSubmitted: (_) => _next(),
        ),
      ],
    ),
  );

  Widget _buildAccessForm(bool canRegister) => Form(
    key: _accessForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        _ProfileSummary(
          type: _type,
          onChange: () => _showStep(0),
          changeEnabled: !_busy,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccessTextField(
              key: const Key('register-email'),
              controller: _email,
              label: AppLocalizations.tr('Correo'),
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: (v) => FormValidators.email(v?.trim()) ?? _emailError,
              onChanged: (_) {
                if (_emailError == null) return;
                setState(() => _emailError = null);
                _accessForm.currentState?.validate();
              },
            ),
            if (_emailError != null)
              Wrap(
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => _navigateToAccess('/login'),
                    child: Text(AppLocalizations.tr('Iniciar sesión')),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _navigateToAccess('/recover-password'),
                    child: Text(AppLocalizations.tr('Recuperar contraseña')),
                  ),
                ],
              ),
          ],
        ),
        AccessTextField(
          key: const Key('register-password'),
          controller: _password,
          label: AppLocalizations.tr('Contraseña'),
          helperText: AppLocalizations.tr('Usa al menos 8 caracteres.'),
          enabled: !_busy,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          validator: (v) => FormValidators.password(v) ?? _passwordError,
          onChanged: (_) {
            if (_passwordError == null) return;
            setState(() => _passwordError = null);
            _accessForm.currentState?.validate();
          },
          suffixIcon: _passwordVisibility(
            _obscure,
            () => setState(() => _obscure = !_obscure),
          ),
        ),
        AccessTextField(
          key: const Key('register-confirm-password'),
          controller: _confirmPassword,
          label: AppLocalizations.tr('Confirmar contraseña'),
          enabled: !_busy,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.tr('Confirma tu contraseña.');
            }
            if (value != _password.text) {
              return AppLocalizations.tr('Las contraseñas no coinciden.');
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
          suffixIcon: _passwordVisibility(
            _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        if (!canRegister)
          AccessFeedback(
            message: _consent.hasDocuments
                ? AppLocalizations.tr(
                    'El registro está pausado. Intenta más tarde.',
                  )
                : AppLocalizations.tr(
                    'No pudimos cargar los documentos de Marea.',
                  ),
            action: TextButton(
              onPressed: _busy ? null : _reloadLegal,
              child: Text(
                _reloadingLegal
                    ? AppLocalizations.tr('Cargando…')
                    : AppLocalizations.tr('Reintentar'),
              ),
            ),
          ),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ConsentFields(
              compact: true,
              terms: _consent.terms,
              adult: _consent.adult,
              enabled: !_busy && canRegister,
              onTermsChanged: (value) => setState(() => _consent.terms = value),
              onAdultChanged: (value) => setState(() => _consent.adult = value),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _passwordVisibility(bool obscure, VoidCallback onPressed) =>
      IconButton(
        tooltip: AppLocalizations.tr(
          obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
        onPressed: _busy ? null : onPressed,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      );
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.type,
    this.onChange,
    this.changeEnabled = true,
  });

  final UserType type;
  final VoidCallback? onChange;
  final bool changeEnabled;

  @override
  Widget build(BuildContext context) {
    final identity = Row(
      children: [
        AccessProfileIcon(type: type),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.tr(type.label),
            style: const TextStyle(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: onChange == null
          ? identity
          : LayoutBuilder(
              builder: (context, constraints) {
                final change = TextButton(
                  onPressed: changeEnabled ? onChange : null,
                  child: Text(AppLocalizations.tr('Cambiar')),
                );
                final compact =
                    constraints.maxWidth < 252 ||
                    MediaQuery.textScalerOf(context).scale(16) > 22;
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [identity, change],
                      )
                    : Row(
                        children: [
                          Expanded(child: identity),
                          change,
                        ],
                      );
              },
            ),
    );
  }
}
