import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/localization/app_localizations.dart';

void main() {
  test(
    'template placeholders are substituted in both supported languages',
    () async {
      await AppLocalizations.delegate.load(const Locale('es', 'MX'));
      expect(
        AppLocalizations.trTemplate('Escribe al menos {min} caracteres.', {
          'min': '5',
        }),
        'Escribe al menos 5 caracteres.',
      );

      await AppLocalizations.delegate.load(const Locale('en', 'US'));
      expect(
        AppLocalizations.trTemplate('Escribe al menos {min} caracteres.', {
          'min': '5',
        }),
        'Enter at least 5 characters.',
      );
      expect(AppLocalizations.tr('Filtrar misiones'), 'Filter missions');
      expect(AppLocalizations.tr('Herramientas'), 'Tools');
      expect(AppLocalizations.tr('Mis postulaciones'), 'My applications');
      expect(AppLocalizations.tr('Portafolio'), 'Portfolio');
      expect(
        AppLocalizations.tr('Algo salió mal. Inténtalo nuevamente.'),
        'Something went wrong. Please try again.',
      );
      expect(
        AppLocalizations.tr('No pudimos conectarnos. Inténtalo nuevamente.'),
        'We could not connect. Please try again.',
      );
      expect(
        AppLocalizations.tr(
          'Te enviamos un enlace a ana@example.com para confirmar tu cuenta.',
        ),
        'We sent a confirmation link to ana@example.com.',
      );
      expect(
        AppLocalizations.tr(
          'Alex quiere iniciar una conversación contigo. ¿Deseas aceptar la solicitud?',
        ),
        'Alex wants to start a conversation with you. Would you like to accept the request?',
      );
      expect(
        AppLocalizations.trTemplate('Postulación {status} · {missionStatus}', {
          'status': 'accepted',
          'missionStatus': 'Open',
        }),
        'Application accepted · Open',
      );
      expect(
        AppLocalizations.trTemplate('Ver {section}', {'section': 'portfolio'}),
        'View portfolio',
      );
      expect(
        AppLocalizations.trTemplate('Motivo: {reason}', {
          'reason': 'Needs review',
        }),
        'Reason: Needs review',
      );

      await AppLocalizations.delegate.load(const Locale('es', 'MX'));
    },
  );
}
