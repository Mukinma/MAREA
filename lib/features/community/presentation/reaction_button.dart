import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/post_social.dart';

IconData reactionIcon(PostReaction? reaction) => switch (reaction) {
  PostReaction.like => Icons.favorite_rounded,
  PostReaction.inspire => Icons.auto_awesome_rounded,
  PostReaction.support => Icons.volunteer_activism_rounded,
  null => Icons.favorite_border_rounded,
};

/// A short tap toggles; a long press tracks the finger over the palette.
class ReactionButton extends StatefulWidget {
  const ReactionButton({
    required this.selected,
    required this.count,
    required this.enabled,
    required this.onSelected,
    this.inline = false,
    this.compact = false,
    super.key,
  });
  final PostReaction? selected;
  final int count;
  final bool enabled, inline, compact;
  final ValueChanged<PostReaction?> onSelected;
  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  final _anchor = GlobalKey();
  final _paletteFocus = FocusNode(debugLabel: 'Reaction palette');
  FocusNode? _returnFocus;
  final _targets = {for (final r in PostReaction.values) r: GlobalKey()};
  late final AnimationController _animation;
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  OverlayEntry? _entry;
  PostReaction? _hover;
  bool _pressed = false;

  Duration get _duration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);

  void _toggle() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onSelected(widget.selected == null ? PostReaction.like : null);
  }

  void _close() {
    final wasOpen = _entry != null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _hover = null;
    if (wasOpen && _returnFocus?.context != null) _returnFocus?.requestFocus();
    _returnFocus = null;
  }

  void _open() {
    if (!widget.enabled || _entry != null) return;
    _returnFocus = FocusManager.instance.primaryFocus;
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = _anchor.currentContext!.findRenderObject() as RenderBox;
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = overlayBox.size;
    final width = math.min(320.0, size.width - 24).toDouble();
    final height = widget.selected == null ? 120.0 : 168.0;
    final left = (position.dx + box.size.width / 2 - width / 2)
        .clamp(12.0, math.max(12.0, size.width - width - 12))
        .toDouble();
    final top = position.dy > height + 16
        ? position.dy - height - 8
        : position.dy + box.size.height + 8;
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top.clamp(8.0, math.max(8.0, size.height - height - 8)),
            width: width,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _animation,
                curve: Curves.easeOutBack,
              ),
              alignment: Alignment.bottomCenter,
              child: Focus(
                focusNode: _paletteFocus,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _close();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    final index = PostReaction.values.indexOf(
                      _hover ?? widget.selected ?? PostReaction.like,
                    );
                    final delta =
                        event.logicalKey == LogicalKeyboardKey.arrowRight
                        ? 1
                        : -1;
                    _hover = PostReaction
                        .values[(index + delta) % PostReaction.values.length];
                    _entry?.markNeedsBuild();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _select(_hover ?? widget.selected ?? PostReaction.like);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Material(
                  color: AppColors.surface,
                  elevation: 12,
                  shadowColor: AppColors.brandNavy.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            for (final r in PostReaction.values)
                              Expanded(
                                child: AnimatedContainer(
                                  key: _targets[r],
                                  duration: _duration,
                                  decoration: BoxDecoration(
                                    color: _hover == r
                                        ? AppColors.mint
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => _select(r),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        children: [
                                          AnimatedScale(
                                            scale: _hover == r ? 1.22 : 1,
                                            duration: _duration,
                                            child: Icon(
                                              reactionIcon(r),
                                              size: 30,
                                              color: r == PostReaction.like
                                                  ? AppColors.error
                                                  : AppColors.aquaDark,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            r.label,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (widget.selected != null)
                          TextButton(
                            onPressed: () => _select(null),
                            child: const Text('Retirar reacción'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null) _paletteFocus.requestFocus();
    });
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  void _track(Offset position) {
    PostReaction? next;
    for (final item in _targets.entries) {
      final box = item.value.currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          (box.localToGlobal(Offset.zero) & box.size).contains(position)) {
        next = item.key;
        break;
      }
    }
    if (next != _hover) {
      _hover = next;
      _entry?.markNeedsBuild();
      if (next != null) HapticFeedback.selectionClick();
    }
  }

  void _select(PostReaction? value) {
    _close();
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onSelected(value);
  }

  @override
  void didUpdateWidget(ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _close();
  }

  @override
  void dispose() {
    _close();
    _animation.dispose();
    _paletteFocus.dispose();
    super.dispose();
  }

  double _compactWidth(BuildContext context) {
    final count = TextPainter(
      text: TextSpan(
        text: '${widget.count}',
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 10),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = math.max(48.0, count.width + 28);
    count.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) => Flex(
    direction: widget.inline ? Axis.horizontal : Axis.vertical,
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        excludeSemantics: true,
        button: true,
        enabled: widget.enabled,
        selected: widget.selected != null,
        label: widget.selected?.label ?? 'Reaccionar',
        value: widget.compact ? '${widget.count} reacciones' : null,
        onTap: widget.enabled ? _toggle : null,
        customSemanticsActions: widget.enabled
            ? {CustomSemanticsAction(label: 'Elegir reacción'): _open}
            : null,
        child: FocusableActionDetector(
          enabled: widget.enabled,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown):
                _ChooseReactionIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _toggle();
                return null;
              },
            ),
            _ChooseReactionIntent: CallbackAction<_ChooseReactionIntent>(
              onInvoke: (_) {
                _open();
                return null;
              },
            ),
          },
          child: Tooltip(
            message: widget.selected?.label ?? 'Reaccionar',
            child: GestureDetector(
              onTap: _toggle,
              onSecondaryTap: _open,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onLongPressStart: (_) => _open(),
              onLongPressMoveUpdate: (d) => _track(d.globalPosition),
              onLongPressEnd: (d) {
                _track(d.globalPosition);
                final selected = _hover;
                if (selected == null) {
                  _close();
                } else {
                  _select(selected);
                }
              },
              child: AnimatedScale(
                scale: _pressed ? .88 : 1,
                duration: _duration,
                child: AnimatedContainer(
                  key: _anchor,
                  duration: _duration,
                  width: widget.compact ? _compactWidth(context) : 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: widget.selected == null
                        ? Colors.transparent
                        : AppColors.mint,
                  ),
                  child: widget.compact
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              reactionIcon(widget.selected),
                              size: 20,
                              color: widget.selected == PostReaction.like
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${widget.count}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          reactionIcon(widget.selected),
                          size: 26,
                          color: widget.selected == PostReaction.like
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (!widget.compact)
        Semantics(
          excludeSemantics: true,
          button: true,
          enabled: widget.enabled,
          label: 'Elegir reacción',
          value: '${widget.count} reacciones',
          onTap: widget.enabled ? _open : null,
          child: Tooltip(
            message: 'Elegir reacción',
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: widget.enabled ? _open : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    child: Text('${widget.count}', key: ValueKey(widget.count)),
                  ),
                  const Icon(Icons.expand_more_rounded, size: 14),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _ChooseReactionIntent extends Intent {
  const _ChooseReactionIntent();
}
