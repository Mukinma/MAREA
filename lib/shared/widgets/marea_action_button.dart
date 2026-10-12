import 'package:flutter/material.dart';

/// Keeps the icon in place while giving a pressed action a small spring response.
class MareaActionButton extends StatefulWidget {
  const MareaActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  State<MareaActionButton> createState() => _MareaActionButtonState();
}

class _MareaActionButtonState extends State<MareaActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (widget.onPressed != null) setState(() => _pressed = true);
    },
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .88 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      child: IconButton(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        tooltip: widget.tooltip,
        icon: widget.icon,
        onPressed: widget.onPressed,
      ),
    ),
  );
}
