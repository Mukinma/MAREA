import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';

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
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Volver',
    onPressed: onPressed ?? () => leaveTour(context, fallback),
    icon: const Icon(Icons.arrow_back),
  );
}

String tourError(Object e) {
  if (e is PostgrestException && e.message == 'space_permission_required') {
    return 'El permiso del espacio fue retirado. Solicita una nueva revisión para volver a publicar.';
  }
  if (e is PostgrestException && e.message == 'capture_superseded') {
    return 'Esta captura fue sustituida por otra más reciente. Vuelve a la posición para continuar con la captura actual.';
  }
  return e is StateError
      ? e.message.toString()
      : AppFailureMapper.from(e).message;
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
        Text(text),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
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
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (input.text.trim().isNotEmpty) {
              Navigator.pop(c, input.text.trim());
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  // The dialog's reverse transition may still own its editable text.
  WidgetsBinding.instance.addPostFrameCallback((_) => input.dispose());
  return result;
}
