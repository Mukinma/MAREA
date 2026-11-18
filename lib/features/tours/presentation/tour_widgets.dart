import 'package:marea/core/localization/app_localizations.dart' as legacy;
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';

String _tourText(String value) => legacy.AppLocalizations.tr(value);

void leaveTour(BuildContext context, String fallback) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    GoRouter.maybeOf(context)?.go(fallback);
  }
}

class TourBackButton extends StatelessWidget {
  const TourBackButton({required this.fallback, this.onPressed, super.key});
  final String fallback;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return IconButton(
      tooltip: _tourText(legacy.AppLocalizations.tr(l10n.volver)),
      onPressed: onPressed ?? () => leaveTour(context, fallback),
      icon: const Icon(Icons.arrow_back),
    );
  }
}

String tourError(Object e, {AppLocalizations? l10n}) {
  if (e is PostgrestException && e.message == 'space_permission_required') {
    return _tourText(
      l10n?.permisoEspacioRetiradoError ??
          'El permiso del espacio fue retirado. Solicita una nueva revisión para volver a publicar.',
    );
  }
  if (e is PostgrestException && e.message == 'capture_superseded') {
    return _tourText(
      l10n?.capturaSustituidaError ??
          'Esta captura fue sustituida por otra más reciente. Vuelve a la posición para continuar con la captura actual.',
    );
  }
  return _tourText(
    e is StateError ? e.message.toString() : AppFailureMapper.from(e).message,
  );
}

class TourNotice extends StatelessWidget {
  const TourNotice(this.text, {this.onRetry, super.key});
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tourText(text)),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              _tourText(
                (AppLocalizations.of(context) ?? AppLocalizationsEs())
                    .reintentar,
              ),
            ),
          ),
      ],
    ),
  );
}

Future<String?> tourTextDialog(
  BuildContext context,
  String title, {
  String initial = '',
  String? help,
}) async {
  final input = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (help != null) Text(help),
            TextField(
              controller: input,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(labelText: title),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(
            _tourText(
              (AppLocalizations.of(context) ?? AppLocalizationsEs()).cancelar,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (input.text.trim().isNotEmpty) {
              Navigator.pop(c, input.text.trim());
            }
          },
          child: Text(
            _tourText(
              (AppLocalizations.of(context) ?? AppLocalizationsEs()).guardar,
            ),
          ),
        ),
      ],
    ),
  );
  // The dialog's reverse transition may still own its editable text.
  WidgetsBinding.instance.addPostFrameCallback((_) => input.dispose());
  return result;
}
