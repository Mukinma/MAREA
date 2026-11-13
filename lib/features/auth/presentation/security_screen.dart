import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/utils/form_validators.dart';
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
    if (widget.recovery) context.go('/password-updated');
  }

  Widget _recoveryForm() => AuthLayout(
    child: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
        return AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  core_l10n.AppLocalizations.tr(l10n.nuevaContrasena),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 28),
                MareaTextField(
                  key: const Key('recovery-password'),
                  controller: _new,
                  label: core_l10n.AppLocalizations.tr(l10n.contrasena),
                  hint: core_l10n.AppLocalizations.tr(l10n.minimoCaracteres),
                  enabled: !widget.controller.isBusy,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  validator: FormValidators.password,
                  onFieldSubmitted: (_) => _save(),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? core_l10n.AppLocalizations.tr(l10n.mostrarContrasena)
                        : core_l10n.AppLocalizations.tr(l10n.ocultarContrasena),
                    onPressed: widget.controller.isBusy
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                SessionFeedback(controller: widget.controller),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: core_l10n.AppLocalizations.tr(l10n.guardarContrasena),
                  isLoading: widget.controller.isBusy,
                  onPressed: widget.controller.isBusy ? null : _save,
                ),
              ],
            ),
          ),
        );
      },
    ),
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
              widget.changeEmail ? core_l10n.AppLocalizations.tr(l10n.cambiarCorreo) : core_l10n.AppLocalizations.tr(l10n.cambiarContrasena),
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
                                  ? core_l10n.AppLocalizations.tr(l10n.confirmacionCambioCorreo)
                                  : core_l10n.AppLocalizations.tr(l10n.usaContrasenaUnica),
                            ),
                            const SizedBox(height: 24),
                            if (!widget.recovery) ...[
                              MareaTextField(
                                controller: _current,
                                label: core_l10n.AppLocalizations.tr(l10n.contrasenaActual),
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                validator: (v) => v == null || v.isEmpty
                                    ? core_l10n.AppLocalizations.tr(l10n.escribeContrasenaActual)
                                    : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            MareaTextField(
                              controller: _new,
                              label: widget.changeEmail
                                  ? core_l10n.AppLocalizations.tr(l10n.nuevoCorreo)
                                  : core_l10n.AppLocalizations.tr(l10n.nuevaContrasena),
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
                                          ? core_l10n.AppLocalizations.tr(l10n.mostrarContrasena)
                                          : core_l10n.AppLocalizations.tr(l10n.ocultarContrasena),
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
                                label:                                 core_l10n.AppLocalizations.tr(l10n.confirmarNuevaContrasena),
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
                                  label: core_l10n.AppLocalizations.tr(l10n.codigoSeguridad),
                                  keyboardType: TextInputType.number,
                                ),
                                Text(
                                  core_l10n.AppLocalizations.tr(l10n.soloSiSeSolicita),
                                  style: TextStyle(fontSize: 12),
                                ),
                                TextButton(
                                  onPressed: widget.controller.isBusy
                                      ? null
                                      : widget
                                            .controller
                                            .requestReauthentication,
                                  child: Text(
                                    core_l10n.AppLocalizations.tr(l10n.enviarCodigoCorreo),
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
                    ? core_l10n.AppLocalizations.tr(l10n.solicitarCambioCorreo)
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
  const PasswordUpdatedScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: Color(0xFF087F80),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          (AppLocalizations.of(context) ?? AppLocalizationsEs())
              .contrasenaActualizada,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: (AppLocalizations.of(context) ?? AppLocalizationsEs()).entrar,
          onPressed: () => context.go('/home'),
        ),
      ],
    ),
  );
}
