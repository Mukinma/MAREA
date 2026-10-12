import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_depth.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.loadingLabel,
  });

  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  String get _busyLabel => switch (label) {
    'Guardar' || 'Guardar cambios' => 'Guardando…',
    'Publicar' || 'Crear publicación' => 'Publicando…',
    'Enviar' => 'Enviando…',
    _ => '$label…',
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null && !isLoading ? AppDepth.action : null,
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: isLoading
              ? Text(loadingLabel ?? _busyLabel, key: const ValueKey('loading'))
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon case final value?) ...[
                      Icon(value, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
