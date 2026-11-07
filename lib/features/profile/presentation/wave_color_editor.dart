import 'package:flutter/material.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';

/// Edits a local draft. Only the caller's existing profile save persists it.
class WaveColorEditor extends StatefulWidget {
  const WaveColorEditor({required this.colors, required this.cover, super.key});
  final List<int> colors;
  final Widget cover;

  @override
  State<WaveColorEditor> createState() => _WaveColorEditorState();
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({required this.color, required this.selected});
  final int color;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Color(color),
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? const Color(0xFF07345C) : const Color(0xFF9AAAB8),
        width: selected ? 3 : 1,
      ),
    ),
    child: selected
        ? Icon(
            Icons.check_rounded,
            size: 24,
            color: Color(color).computeLuminance() > .4
                ? Colors.black
                : Colors.white,
          )
        : null,
  );
}

/// A touchable color field plus a light/dark strip; no numeric controls.
class _VisualColorDialog extends StatefulWidget {
  const _VisualColorDialog({
    required this.colors,
    required this.layer,
    required this.onChanged,
  });
  final List<int> colors;
  final int layer;
  final ValueChanged<int> onChanged;

  @override
  State<_VisualColorDialog> createState() => _VisualColorDialogState();
}

class _VisualColorDialogState extends State<_VisualColorDialog> {
  late HSVColor _color = HSVColor.fromColor(Color(widget.colors[widget.layer]));

  void _change(HSVColor color) {
    setState(() => _color = color);
    widget.onChanged(color.toColor().toARGB32());
  }

  Widget _field({required bool lightness}) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = lightness ? 48.0 : 176.0;
      void choose(Offset position) {
        final x = (position.dx / width).clamp(0.0, 1.0);
        final y = (position.dy / height).clamp(0.0, 1.0);
        _change(
          lightness
              ? _color.withValue(x)
              : _color
                    .withHue(x * 360)
                    .withSaturation(1 - y)
                    .withValue(_color.value == 0 ? 1 : _color.value),
        );
      }

      return Semantics(
        label: lightness
            ? 'Elegir un color más claro o más oscuro'
            : 'Elegir cualquier color',
        child: GestureDetector(
          key: ValueKey(
            lightness ? 'wave-color-lightness' : 'wave-color-field',
          ),
          onTapDown: (details) => choose(details.localPosition),
          onPanStart: (details) => choose(details.localPosition),
          onPanUpdate: (details) => choose(details.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _ColorFieldPainter(
                  color: _color,
                  lightness: lightness,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Más colores'),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: ProfileWaves(
                colors: List.of(widget.colors)
                  ..[widget.layer] = _color.toColor().toARGB32(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Toca o desliza para elegir'),
            const SizedBox(height: 8),
            _field(lightness: false),
            const SizedBox(height: 16),
            const Text('Más oscuro o más claro'),
            const SizedBox(height: 8),
            _field(lightness: true),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Usar color'),
      ),
    ],
  );
}

class _ColorFieldPainter extends CustomPainter {
  const _ColorFieldPainter({required this.color, required this.lightness});
  final HSVColor color;
  final bool lightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (lightness) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.black, color.withValue(1).toColor()],
          ).createShader(rect),
      );
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              for (var h = 0; h <= 360; h += 60)
                HSVColor.fromAHSV(1, h.toDouble(), 1, color.value).toColor(),
            ],
          ).createShader(rect),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              HSVColor.fromAHSV(1, 0, 0, color.value).toColor(),
            ],
          ).createShader(rect),
      );
    }
    final position = Offset(
      ((lightness ? color.value : color.hue / 360) * size.width).clamp(
        8.0,
        size.width - 8,
      ),
      lightness
          ? size.height / 2
          : ((1 - color.saturation) * size.height).clamp(8.0, size.height - 8),
    );
    canvas.drawCircle(
      position,
      7,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      position,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorFieldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.lightness != lightness;
}

class _WaveColorEditorState extends State<WaveColorEditor> {
  late List<int> _colors = List.of(widget.colors);
  int _layer = 0;
  static const _waveNames = [
    'Color de la ola superior',
    'Color de la ola inferior',
  ];
  static final _palette = <int>[
    ...ProfileWaves.defaultColors,
    for (final hue in [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lime,
      Colors.yellow,
      Colors.orange,
      Colors.brown,
    ])
      for (final shade in [100, 300, 500, 800]) hue[shade]!.toARGB32(),
    for (final color in [
      Colors.white,
      Colors.grey.shade300,
      Colors.grey.shade600,
      Colors.grey.shade900,
      Colors.black,
    ])
      color.toARGB32(),
  ];

  void _select(List<int> colors) => setState(() => _colors = List.of(colors));

  void _chooseColor(int color) => setState(() {
    _colors = List.of(_colors)..[_layer] = color;
  });

  Future<void> _moreColors() async {
    final original = _colors[_layer];
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => _VisualColorDialog(
        colors: List.of(_colors),
        layer: _layer,
        onChanged: _chooseColor,
      ),
    );
    if (accepted != true && mounted) _chooseColor(original);
  }

  Widget _manualColors() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < 2; i++) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: _layer == i ? const Color(0xFFE1F7F7) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _layer == i
                    ? const Color(0xFF009FAC)
                    : const Color(0xFFD9E5F0),
                width: _layer == i ? 2 : 1,
              ),
            ),
            child: ListTile(
              key: ValueKey('wave-layer-$i'),
              selected: _layer == i,
              leading: _ColorCircle(color: _colors[i], selected: false),
              title: Text(
                _waveNames[i],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: _layer == i
                  ? const Icon(Icons.check_circle, color: Color(0xFF087F80))
                  : null,
              onTap: () => setState(() => _layer = i),
            ),
          ),
        ),
      ],
      const SizedBox(height: 4),
      const Text(
        'Toca un color',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final color in {..._palette, _colors[_layer]})
            Semantics(
              label: 'Elegir ${_waveNames[_layer].toLowerCase()}',
              button: true,
              selected: _colors[_layer] == color,
              child: InkResponse(
                key: ValueKey('wave-swatch-$color'),
                onTap: () => _chooseColor(color),
                radius: 24,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: _ColorCircle(
                      color: color,
                      selected: _colors[_layer] == color,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _moreColors,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Más colores'),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Personalizar olitas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                key: const Key('wave-live-preview'),
                height: 156,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.cover,
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 110,
                      child: ProfileWaves(colors: _colors),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _manualColors(),
                  const Text(
                    'Combinaciones',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in wavePalettes.entries)
                          SizedBox(
                            width: (constraints.maxWidth - 8) / 2,
                            child: Semantics(
                              selected:
                                  _colors[0] == entry.value[0] &&
                                  _colors[1] == entry.value[1],
                              child: OutlinedButton(
                                onPressed: () => _select(entry.value),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color:
                                        _colors[0] == entry.value[0] &&
                                            _colors[1] == entry.value[1]
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                    width:
                                        _colors[0] == entry.value[0] &&
                                            _colors[1] == entry.value[1]
                                        ? 2
                                        : 1,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      width: double.infinity,
                                      child: ProfileWaves(colors: entry.value),
                                    ),
                                    Text(
                                      entry.key,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _select(ProfileWaves.defaultColors),
                    child: const Text('Restablecer colores predeterminados'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cancel = TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                );
                final apply = FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, List<int>.of(_colors)),
                  child: const Text('Aplicar colores'),
                );
                if (constraints.maxWidth < 348 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [apply, cancel],
                  );
                }
                return Row(
                  children: [
                    cancel,
                    const SizedBox(width: 12),
                    Expanded(child: apply),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
