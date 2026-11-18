import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
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
  final _feedback = GlobalKey();
  bool _obscure = true;
  bool _obscureCurrent = true;
  bool _showFeedback = false;
  bool _savingRecovery = false;
  String? _recoveryError;
  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    _nonce.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.controller.isBusy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _showFeedback = true);
    final ok = widget.changeEmail
        ? await widget.controller.changeEmail(_new.text, _current.text)
        : await widget.controller.changePassword(
            _new.text,
            currentPassword: _current.text,
            nonce: _nonce.text.trim(),
          );
    if (!mounted) return;
    _revealFeedback();
    if (!ok) return;
    _current.clear();
    _new.clear();
    _confirm.clear();
    _nonce.clear();
  }

  Future<void> _saveRecovery() async {
    if (_savingRecovery ||
        widget.controller.isBusy ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _savingRecovery = true;
      _recoveryError = null;
    });
    final ok = await widget.controller.changePassword(_new.text);
    if (!mounted) return;
    if (ok) TextInput.finishAutofillContext();
    setState(() {
      _savingRecovery = false;
      if (!ok) {
        final failure = widget.controller.failure;
        _recoveryError = failure?.kind == AppFailureKind.weakPassword
            ? failure!.message
            : AppLocalizations.tr(
                'No pudimos guardar la contraseña. Inténtalo de nuevo.',
              );
      }
    });
  }

  Widget _recoveryForm() => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final busy = _savingRecovery || widget.controller.isBusy;
      return AccessLayout(
        title: AppLocalizations.tr('Nueva contraseña'),
        step: 3,
        totalSteps: 3,
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccessTextField(
                  key: const Key('recovery-password'),
                  controller: _new,
                  label: AppLocalizations.tr('Contraseña'),
                  helperText: AppLocalizations.tr('Usa al menos 8 caracteres.'),
                  enabled: !busy,
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  validator: FormValidators.password,
                  onFieldSubmitted: (_) => _saveRecovery(),
                  onChanged: (_) {
                    if (_recoveryError == null) return;
                    setState(() => _recoveryError = null);
                    widget.controller.clearFeedback();
                  },
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? AppLocalizations.tr('Mostrar contraseña')
                        : AppLocalizations.tr('Ocultar contraseña'),
                    onPressed: busy
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                if (_recoveryError case final error?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AccessFeedback(message: error),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: AppLocalizations.tr('Guardar contraseña'),
                  loadingLabel: AppLocalizations.tr('Guardando contraseña…'),
                  isLoading: _savingRecovery,
                  onPressed: busy ? null : _saveRecovery,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _revealFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_feedback.currentContext case final context?) {
        Scrollable.ensureVisible(context, alignment: 1);
      }
    });
  }

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _showFeedback = true);
    await widget.controller.requestReauthentication();
    if (mounted) _revealFeedback();
  }

  Widget _visibilityToggle({
    required bool obscured,
    required String field,
    required VoidCallback onPressed,
    required bool busy,
  }) => IconButton(
    tooltip: obscured ? 'Mostrar $field' : 'Ocultar $field',
    onPressed: busy ? null : onPressed,
    icon: Icon(
      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
  );

  @override
  Widget build(BuildContext context) => widget.recovery
      ? _recoveryForm()
      : ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final busy = widget.controller.isBusy;
            return ProfilePage(
              title: widget.changeEmail
                  ? AppLocalizations.tr('Cambiar correo')
                  : AppLocalizations.tr('Cambiar contraseña'),
              fallback: '/settings/personal',
              busy: busy,
              body: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ProfilePageFrame(
                  child: AutofillGroup(
                    onDisposeAction: AutofillContextAction.cancel,
                    child: Form(
                      key: _form,
                      child: ProfileFormSection(
                        children: [
                          Text(
                            widget.changeEmail
                                ? AppLocalizations.tr(
                                    'Confirma el cambio en tu correo actual y en el nuevo.',
                                  )
                                : AppLocalizations.tr(
                                    'Usa una contraseña única de al menos 8 caracteres.',
                                  ),
                          ),
                          MareaTextField(
                            controller: _current,
                            label: AppLocalizations.tr('Contraseña actual'),
                            enabled: !busy,
                            obscureText: _obscureCurrent,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.next,
                            validator: (value) => value == null || value.isEmpty
                                ? AppLocalizations.tr(
                                    'Escribe tu contraseña actual.',
                                  )
                                : null,
                            suffixIcon: _visibilityToggle(
                              obscured: _obscureCurrent,
                              field: AppLocalizations.tr('contraseña actual'),
                              onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              busy: busy,
                            ),
                          ),
                          MareaTextField(
                            controller: _new,
                            label: widget.changeEmail
                                ? AppLocalizations.tr('Nuevo correo')
                                : AppLocalizations.tr('Nueva contraseña'),
                            enabled: !busy,
                            obscureText: !widget.changeEmail && _obscure,
                            keyboardType: widget.changeEmail
                                ? TextInputType.emailAddress
                                : TextInputType.visiblePassword,
                            textInputAction: widget.changeEmail
                                ? TextInputAction.done
                                : TextInputAction.next,
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
                                : _visibilityToggle(
                                    obscured: _obscure,
                                    field: AppLocalizations.tr(
                                      'contraseña nueva',
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    busy: busy,
                                  ),
                          ),
                          if (!widget.changeEmail) ...[
                            MareaTextField(
                              controller: _confirm,
                              label: AppLocalizations.tr(
                                'Confirmar nueva contraseña',
                              ),
                              enabled: !busy,
                              obscureText: _obscure,
                              validator: (value) =>
                                  FormValidators.confirmPassword(
                                    value,
                                    _new.text,
                                  ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            MareaTextField(
                              controller: _nonce,
                              label: AppLocalizations.tr('Código de seguridad'),
                              helperText: AppLocalizations.tr(
                                'Solo si se solicita.',
                              ),
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: busy ? null : _requestCode,
                                child: Text(
                                  AppLocalizations.tr(
                                    'Enviar código por correo',
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_showFeedback)
                            SessionFeedback(
                              key: _feedback,
                              controller: widget.controller,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              action: FilledButton(
                onPressed: busy ? null : _save,
                child: Text(
                  busy
                      ? AppLocalizations.tr('Un momento…')
                      : widget.changeEmail
                      ? AppLocalizations.tr('Solicitar cambio de correo')
                      : AppLocalizations.tr('Guardar contraseña'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
}

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({this.onContinue, super.key});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => AccessLayout(
    title: AppLocalizations.tr('Contraseña actualizada'),
    leading: const CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.brandNavy,
      child: Icon(Icons.check_rounded, size: 28),
    ),
    child: PrimaryButton(
      label: AppLocalizations.tr('Entrar a Marea'),
      onPressed: onContinue ?? () => context.go('/home'),
    ),
  );
}
