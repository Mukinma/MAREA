import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => context.push('/terms'),
        child: Text(compact ? 'Términos' : 'Términos y condiciones'),
      ),
      TextButton(
        onPressed: () => context.push('/privacy'),
        child: const Text('Aviso de privacidad'),
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
  Widget build(BuildContext context) => Column(
    children: [
      const LegalLinks(compact: true),
      CheckboxListTile(
        key: const Key('accept-terms'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
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
        value: adult,
        onChanged: enabled ? (value) => onAdultChanged(value ?? false) : null,
        title: const Text('Tengo 18 años o más.'),
      ),
    ],
  );
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.controller,
    required this.kind,
    super.key,
  });
  final AppSessionController controller;
  final String kind;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final policy = controller.legalPolicy;
      final doc = kind == 'terms' ? policy.terms : policy.privacy;
      final deletion = kind == 'deletion';
      return Scaffold(
        appBar: AppBar(
          title: Text(
            deletion
                ? 'Eliminar mi cuenta'
                : kind == 'terms'
                ? 'Términos y condiciones'
                : 'Aviso de privacidad',
          ),
          leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/welcome'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (deletion) ...[
                    Text(
                      'Tú decides cuándo irte.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Puedes eliminar tu cuenta de MAREA desde Configuración → Eliminar cuenta. Se borrarán tu acceso, perfil, preferencias e imágenes. Es una acción permanente.',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: controller.status == AuthStatus.authenticated
                          ? 'Ir a Configuración'
                          : 'Iniciar sesión para eliminar mi cuenta',
                      onPressed: () => context.go(
                        controller.status == AuthStatus.authenticated
                            ? '/settings'
                            : '/login',
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/recover-password'),
                      child: const Text('No puedo acceder a mi cuenta'),
                    ),
                    if (policy.supportEmail case final email?)
                      TextButton(
                        onPressed: () async {
                          final ok = await launchUrl(
                            Uri(
                              scheme: 'mailto',
                              path: email,
                              queryParameters: {
                                'subject':
                                    'Solicitud de eliminación de cuenta MAREA',
                              },
                            ),
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Escríbenos a $email')),
                            );
                          }
                        },
                        child: Text('Solicitar ayuda: $email'),
                      ),
                  ] else if (doc != null) ...[
                    Text(
                      doc.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Versión ${doc.version} · México'),
                    const SizedBox(height: 24),
                    SelectableText(
                      doc.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ] else ...[
                    Text(
                      'Documento pendiente de publicación',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.legalError ??
                          'MAREA todavía no ha publicado este documento. No es posible crear una cuenta hasta que estén disponibles los términos y el aviso de privacidad.',
                    ),
                    TextButton(
                      onPressed: controller.reloadLegal,
                      child: const Text('Volver a cargar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class AcceptLegalScreen extends StatefulWidget {
  const AcceptLegalScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<AcceptLegalScreen> createState() => _AcceptLegalScreenState();
}

class _AcceptLegalScreenState extends State<AcceptLegalScreen> {
  bool terms = false, adult = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Antes de continuar')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Conoce las condiciones de MAREA',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'La comunidad es para mayores de 18 años. Revisa los documentos vigentes antes de continuar. Si no deseas aceptarlos, puedes cerrar sesión o eliminar tu cuenta.',
                ),
                ConsentFields(
                  terms: terms,
                  adult: adult,
                  enabled: !widget.controller.isBusy,
                  onTermsChanged: (v) => setState(() => terms = v),
                  onAdultChanged: (v) => setState(() => adult = v),
                ),
                SessionFeedback(controller: widget.controller),
                PrimaryButton(
                  label: 'Aceptar y continuar',
                  isLoading: widget.controller.isBusy,
                  onPressed:
                      terms &&
                          adult &&
                          widget.controller.legalPolicy.hasDocuments
                      ? () async {
                          final p = widget.controller.legalPolicy;
                          final ok = await widget.controller.acceptLegal(
                            LegalConsent(
                              termsVersion: p.terms!.version,
                              privacyVersion: p.privacy!.version,
                              acceptedTerms: terms,
                              adultConfirmed: adult,
                            ),
                          );
                          if (ok && context.mounted) {
                            context.go(
                              widget.controller.needsOnboarding
                                  ? '/onboarding'
                                  : '/profile',
                            );
                          }
                        }
                      : null,
                ),
                TextButton(
                  onPressed: widget.controller.isBusy
                      ? null
                      : () => widget.controller.signOut(),
                  child: const Text('Cerrar sesión'),
                ),
                TextButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Gestionar o eliminar mi cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
