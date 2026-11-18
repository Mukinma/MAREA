import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
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

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;

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
    if (!_form.currentState!.validate()) return;
    final ok = widget.changeEmail
        ? await widget.controller.changeEmail(_new.text, _current.text)
        : await widget.controller.changePassword(
            _new.text,
            currentPassword: _current.text,
            nonce: _nonce.text.trim(),
          );
    if (!mounted || !ok) return;
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
            : 'No pudimos guardar la contraseña. Inténtalo de nuevo.';
      }
    });
  }

  Widget _recoveryForm() => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final busy = _savingRecovery || widget.controller.isBusy;
      return AccessLayout(
        title: 'Nueva contraseña',
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
                  label: 'Contraseña',
                  helperText: 'Usa al menos 8 caracteres.',
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
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
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
                  label: 'Guardar contraseña',
                  loadingLabel: 'Guardando contraseña…',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return widget.recovery
        ? _recoveryForm()
        : Scaffold(
            appBar: AppBar(
              leading: widget.recovery ? null : const ProfileBackButton(),
              automaticallyImplyLeading: !widget.recovery,
              title: Text(
                widget.changeEmail
                    ? core_l10n.AppLocalizations.tr(l10n.cambiarCorreo)
                    : core_l10n.AppLocalizations.tr(l10n.cambiarContrasena),
              ),
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
                      child: ProfileFormSection(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.changeEmail
                                    ? core_l10n.AppLocalizations.tr(
                                        l10n.confirmacionCambioCorreo,
                                      )
                                    : core_l10n.AppLocalizations.tr(
                                        l10n.usaContrasenaUnica,
                                      ),
                              ),
                              const SizedBox(height: 24),
                              if (!widget.recovery) ...[
                                MareaTextField(
                                  controller: _current,
                                  label: core_l10n.AppLocalizations.tr(
                                    l10n.contrasenaActual,
                                  ),
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  validator: (v) => v == null || v.isEmpty
                                      ? core_l10n.AppLocalizations.tr(
                                          l10n.escribeContrasenaActual,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              MareaTextField(
                                controller: _new,
                                label: widget.changeEmail
                                    ? core_l10n.AppLocalizations.tr(
                                        l10n.nuevoCorreo,
                                      )
                                    : core_l10n.AppLocalizations.tr(
                                        l10n.nuevaContrasena,
                                      ),
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
                                            ? core_l10n.AppLocalizations.tr(
                                                l10n.mostrarContrasena,
                                              )
                                            : core_l10n.AppLocalizations.tr(
                                                l10n.ocultarContrasena,
                                              ),
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
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
                                  label: core_l10n.AppLocalizations.tr(
                                    l10n.confirmarNuevaContrasena,
                                  ),
                                  obscureText: _obscure,
                                  validator: (v) =>
                                      FormValidators.confirmPassword(
                                        v,
                                        _new.text,
                                      ),
                                ),
                                if (!widget.recovery) ...[
                                  const SizedBox(height: 16),
                                  MareaTextField(
                                    controller: _nonce,
                                    label: core_l10n.AppLocalizations.tr(
                                      l10n.codigoSeguridad,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  Text(
                                    core_l10n.AppLocalizations.tr(
                                      l10n.soloSiSeSolicita,
                                    ),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  TextButton(
                                    onPressed: widget.controller.isBusy
                                        ? null
                                        : widget
                                              .controller
                                              .requestReauthentication,
                                    child: Text(
                                      core_l10n.AppLocalizations.tr(
                                        l10n.enviarCodigoCorreo,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              SessionFeedback(controller: widget.controller),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: AnimatedBuilder(
              animation: widget.controller,
              builder: (_, _) => ProfileActionBar(
                maxWidth: 560,
                child: PrimaryButton(
                  label: widget.changeEmail
                      ? core_l10n.AppLocalizations.tr(
                          l10n.solicitarCambioCorreo,
                        )
                      : core_l10n.AppLocalizations.tr(l10n.guardarContrasena),
                  isLoading: widget.controller.isBusy,
                  onPressed: _save,
                ),
              ),
            ),
          );
  }
}

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({this.onContinue, super.key});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => AccessLayout(
    title: 'Contraseña actualizada',
    leading: const CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.brandNavy,
      child: Icon(Icons.check_rounded, size: 28),
    ),
    child: PrimaryButton(
      label: 'Entrar a Marea',
      onPressed: onContinue ?? () => context.go('/home'),
    ),
  );
}
