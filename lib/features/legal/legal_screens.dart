import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class AccessConsentDraft {
  AccessConsentDraft(this._controller) {
    _controller.addListener(_discardOutdatedAcceptance);
  }

  final AppSessionController _controller;
  ({String terms, String privacy})? _acceptedVersions;
  bool adult = false;

  ({String terms, String privacy})? get _versions {
    final policy = _controller.legalPolicy;
    if (!policy.hasDocuments) return null;
    final terms = policy.terms!.version;
    final privacy = policy.privacy!.version;
    if (terms.isEmpty || privacy.isEmpty) return null;
    return (terms: terms, privacy: privacy);
  }

  bool get hasDocuments => _versions != null;
  bool get terms => _acceptedVersions != null && _acceptedVersions == _versions;

  set terms(bool value) => _acceptedVersions = value ? _versions : null;

  void _discardOutdatedAcceptance() {
    if (_acceptedVersions != _versions) _acceptedVersions = null;
  }

  bool get isComplete => terms && adult;

  LegalConsent? get consent {
    final acceptedVersions = _acceptedVersions;
    if (!isComplete || acceptedVersions == null) return null;
    return LegalConsent(
      termsVersion: acceptedVersions.terms,
      privacyVersion: acceptedVersions.privacy,
      acceptedTerms: true,
      adultConfirmed: true,
    );
  }

  void dispose() => _controller.removeListener(_discardOutdatedAcceptance);
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({
    super.key,
    this.compact = false,
    this.alignment = WrapAlignment.center,
  });

  final bool compact;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment,
    children: [
      TextButton(
        onPressed: () => context.push('/terms'),
        child: Text(
          compact
              ? AppLocalizations.tr('Términos')
              : AppLocalizations.tr('Términos y condiciones'),
        ),
      ),
      TextButton(
        onPressed: () => context.push('/privacy'),
        child: Text(AppLocalizations.tr('Aviso de privacidad')),
      ),
    ],
  );
}

class ConsentFields extends StatelessWidget {
  const ConsentFields({
    required this.terms,
    required this.adult,
    required this.onTermsChanged,
    required this.onAdultChanged,
    this.enabled = true,
    super.key,
  });

  final bool terms, adult, enabled;
  final ValueChanged<bool> onTermsChanged, onAdultChanged;

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LegalLinks(alignment: WrapAlignment.start),
        CheckboxListTile(
          key: const Key('accept-terms'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.actionBlue,
          shape: shape,
          value: terms,
          onChanged: enabled ? (value) => onTermsChanged(value ?? false) : null,
          title: const Text(
            'Acepto los términos y he leído el aviso de privacidad.',
          ),
        ),
        CheckboxListTile(
          key: const Key('confirm-adult'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.actionBlue,
          shape: shape,
          value: adult,
          onChanged: enabled ? (value) => onAdultChanged(value ?? false) : null,
          title: const Text('Tengo 18 años o más.'),
        ),
      ],
    );
  }
}

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    required this.controller,
    required this.kind,
    super.key,
  });

  final AppSessionController controller;
  final String kind;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final policy = widget.controller.legalPolicy;
      final deletion = widget.kind == 'deletion';
      final terms = widget.kind == 'terms';
      final doc = terms ? policy.terms : policy.privacy;
      final available = doc != null && doc.body.trim().isNotEmpty;
      final authenticated =
          widget.controller.status == AuthStatus.authenticated;
      final loading =
          widget.controller.status == AuthStatus.initializing ||
          widget.controller.isLoadingLegal;
      return ProfilePage(
        title: deletion
            ? 'Eliminar mi cuenta'
            : available
            ? doc.title
            : terms
            ? 'Términos y condiciones'
            : 'Aviso de privacidad',
        fallback: authenticated ? '/settings' : '/welcome',
        busy: !deletion && loading,
        body: SingleChildScrollView(
          child: ProfilePageFrame(
            child: ProfileFormSection(
              children: [
                if (deletion)
                  _buildDeletionHelp()
                else if (available) ...[
                  Text(
                    'Versión ${doc.version} · México',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SelectableText(
                    doc.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ] else if (loading)
                  Semantics(
                    liveRegion: true,
                    child: const Text('Cargando documento…'),
                  )
                else
                  AccessFeedback(
                    message:
                        widget.controller.legalError ??
                        'Este documento aún no está disponible.',
                    action: TextButton(
                      onPressed: widget.controller.reloadLegal,
                      child: const Text('Volver a cargar'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _buildDeletionHelp() {
    final controller = widget.controller;
    final authenticated = controller.status == AuthStatus.authenticated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Puedes eliminar tu cuenta desde Configuración → Mis datos personales → Eliminar cuenta. Se borrarán tu acceso, perfil, preferencias e imágenes. Es una acción permanente.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: authenticated
              ? 'Ir a Mis datos personales'
              : 'Iniciar sesión para eliminar mi cuenta',
          onPressed: () =>
              context.go(authenticated ? '/settings/personal' : '/login'),
        ),
        TextButton(
          onPressed: () => context.go('/recover-password'),
          child: const Text('No puedo acceder a mi cuenta'),
        ),
        if (controller.legalPolicy.supportEmail case final email?)
          TextButton(
            onPressed: () async {
              final ok = await launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: email,
                  queryParameters: {
                    'subject': 'Solicitud de eliminación de cuenta MAREA',
                  },
                ),
              );
              if (!ok && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Escríbenos a $email')));
              }
            },
            child: Text('Solicitar ayuda: $email'),
          ),
      ],
    );
  }
}

class AcceptLegalScreen extends StatefulWidget {
  const AcceptLegalScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<AcceptLegalScreen> createState() => _AcceptLegalScreenState();
}

class _AcceptLegalScreenState extends State<AcceptLegalScreen> {
  late var _consent = AccessConsentDraft(widget.controller);
  bool _reloading = false;

  bool get _busy => _reloading || widget.controller.isBusy;

  @override
  void didUpdateWidget(covariant AcceptLegalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _consent.dispose();
      _consent = AccessConsentDraft(widget.controller);
    }
  }

  @override
  void dispose() {
    _consent.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_busy) return;
    setState(() => _reloading = true);
    await widget.controller.reloadLegal();
    if (mounted) setState(() => _reloading = false);
  }

  Future<void> _accept() async {
    if (_busy) return;
    final consent = _consent.consent;
    if (consent != null) await widget.controller.acceptLegal(consent);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => AccessLayout(
      title: 'Antes de continuar',
      description:
          'Revisa los documentos vigentes. Puedes cerrar sesión o gestionar tu cuenta si prefieres no aceptarlos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_consent.hasDocuments) ...[
            AccessFeedback(
              message: 'No pudimos cargar los documentos de Marea.',
              action: TextButton(
                onPressed: _busy ? null : _reload,
                child: Text(_reloading ? 'Cargando…' : 'Reintentar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ConsentFields(
            terms: _consent.terms,
            adult: _consent.adult,
            enabled: !_busy && _consent.hasDocuments,
            onTermsChanged: (value) => setState(() => _consent.terms = value),
            onAdultChanged: (value) => setState(() => _consent.adult = value),
          ),
          if (widget.controller.failure?.message case final message?) ...[
            const SizedBox(height: 16),
            AccessFeedback(message: message),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Aceptar y continuar',
            loadingLabel: 'Guardando aceptación…',
            isLoading: widget.controller.isBusy,
            onPressed: !_busy && _consent.isComplete ? _accept : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : widget.controller.signOut,
            child: const Text('Cerrar sesión'),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.go('/settings'),
            child: const Text('Gestionar o eliminar mi cuenta'),
          ),
        ],
      ),
    ),
  );
}
