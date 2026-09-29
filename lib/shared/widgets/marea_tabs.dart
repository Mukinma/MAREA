import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MareaTabs extends StatefulWidget {
  const MareaTabs({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  State<MareaTabs> createState() => _MareaTabsState();
}

class _MareaTabsState extends State<MareaTabs> {
  final _scroll = ScrollController();
  final _selected = GlobalKey();
  @override
  void initState() {
    super.initState();
    _revealSelection();
  }

  @override
  void didUpdateWidget(MareaTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.options != widget.options) {
      _revealSelection();
    }
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _selected.currentContext?.findRenderObject();
      if (target != null) {
        _scroll.position.ensureVisible(target, alignment: .5);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MareaSurface(
        inset: true,
        radius: 18,
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final option in widget.options.entries)
              Semantics(
                selected: option.key == widget.value,
                child: TextButton(
                  key: option.key == widget.value ? _selected : null,
                  style: TextButton.styleFrom(
                    backgroundColor: option.key == widget.value
                        ? AppColors.surface
                        : Colors.transparent,
                    foregroundColor: option.key == widget.value
                        ? AppColors.brandNavy
                        : AppColors.textSecondary,
                    textStyle: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => widget.onChanged(option.key),
                  child: Text(option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
