import 'dart:math' as math;
import 'package:flutter/material.dart';

const _navy = Color(0xFF0B3045);
const _muted = Color(0xFF6B889D);
const _aqua = Color(0xFF19C2CC);

/// Separate, illustrative elements; the parent excludes gestures and semantics.
class IntroDecorations extends StatelessWidget {
  const IntroDecorations({
    required this.page,
    required this.drift,
    required this.entrance,
    required this.reducedMotion,
    super.key,
  });
  final int page;
  final Animation<double> drift;
  final Animation<double> entrance;
  final bool reducedMotion;

  Widget _float({
    required double x,
    required double y,
    required double width,
    required int order,
    required Widget child,
    double amplitude = 4,
  }) => Positioned(
    left: x,
    top: y,
    width: width,
    child: _FloatingElement(
      drift: drift,
      entrance: entrance,
      reducedMotion: reducedMotion,
      order: order,
      amplitude: amplitude,
      child: child,
    ),
  );

  Widget _pin(double x, double y, int order) => _float(
    x: x,
    y: y,
    width: 44,
    order: order,
    amplitude: 2.5,
    child: _LocationPin(
      drift: drift,
      reducedMotion: reducedMotion,
      phase: order,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (page == 0) return const SizedBox.expand();
    final elements = switch (page) {
      1 => [
        _float(
          x: 76,
          y: 82,
          width: 192,
          order: 0,
          child: const _PlaceCard(
            image: 'brava',
            name: 'Brava',
            rating: '4.8',
            category: 'Cafetería',
          ),
        ),
        _pin(165, 176, 1),
        _float(
          x: 186,
          y: 228,
          width: 174,
          order: 2,
          child: const _TerraceCard(),
        ),
        _pin(285, 300, 3),
        _float(
          x: 198,
          y: 366,
          width: 174,
          order: 4,
          child: const _PlaceCard(
            image: 'chopdeli',
            name: 'ChopDeli',
            rating: '4.6',
            category: 'Comida',
          ),
        ),
        _pin(166, 440, 5),
      ],
      2 => [
        _float(
          x: 26,
          y: 92,
          width: 112,
          order: 0,
          child: const _CategoryChip(
            label: 'Pintura',
            icon: Icons.palette_outlined,
            color: Color(0xFFEEE5F8),
          ),
        ),
        _pin(54, 150, 1),
        _float(
          x: 228,
          y: 62,
          width: 138,
          order: 2,
          child: const _CategoryChip(
            label: 'Fotografía',
            icon: Icons.camera_alt_outlined,
            color: Color(0xFFE6F6F4),
          ),
        ),
        _float(
          x: 264,
          y: 268,
          width: 102,
          order: 3,
          child: const _CategoryChip(
            label: 'Moda',
            icon: Icons.checkroom_outlined,
            color: Color(0xFFF9E1EC),
          ),
        ),
        _float(
          x: 30,
          y: 412,
          width: 114,
          order: 4,
          child: const _CategoryChip(
            label: 'Comida',
            icon: Icons.restaurant_outlined,
            color: Color(0xFFE6F6F4),
          ),
        ),
      ],
      _ => [
        _float(
          x: 38,
          y: 66,
          width: 314,
          order: 0,
          amplitude: 3,
          child: const _EventCard(),
        ),
      ],
    };
    // These are decorative UI previews. Keep their text proportionate to the
    // scene; the actual title, description and controls follow system scaling.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 390,
          height: 540,
          child: Stack(clipBehavior: Clip.none, children: elements),
        ),
      ),
    );
  }
}

class _FloatingElement extends StatelessWidget {
  const _FloatingElement({
    required this.drift,
    required this.entrance,
    required this.reducedMotion,
    required this.order,
    required this.amplitude,
    required this.child,
  });
  final Animation<double> drift;
  final Animation<double> entrance;
  final bool reducedMotion;
  final int order;
  final double amplitude;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion) return child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([drift, entrance]),
        child: child,
        builder: (_, child) {
          final progress = Interval(
            order * .085,
            .55 + order * .085,
            curve: Curves.easeOutCubic,
          ).transform(entrance.value);
          final wave = math.sin(drift.value * math.pi * 2 + order * 1.3);
          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(
                0,
                16 * (1 - progress) + wave * amplitude * progress,
              ),
              child: Transform.scale(
                scale: .94 + .06 * Curves.easeOutBack.transform(progress),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  const _LocationPin({
    required this.drift,
    required this.reducedMotion,
    required this.phase,
  });
  final Animation<double> drift;
  final bool reducedMotion;
  final int phase;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: drift,
    builder: (_, _) {
      final pulse = reducedMotion ? 0.0 : (drift.value + phase * .17) % 1;
      return SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!reducedMotion)
              Positioned(
                top: 3,
                child: Transform.scale(
                  scale: .7 + pulse * 1.3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _aqua.withValues(alpha: .24 * (1 - pulse)),
                    ),
                    child: const SizedBox(width: 28, height: 28),
                  ),
                ),
              ),
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF45CFD7),
              size: 34,
              shadows: [
                Shadow(
                  color: Color(0x350B3045),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            const Positioned(
              top: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 7, height: 7),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(8),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140B3045),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.image,
    required this.name,
    required this.rating,
    required this.category,
  });
  final String image;
  final String name;
  final String rating;
  final String category;

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/onboarding/$image.webp',
            width: 66,
            height: 70,
            fit: BoxFit.cover,
            alignment: image == 'brava'
                ? const Alignment(-.35, .5)
                : const Alignment(.25, 0),
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: Color(0xFFEFA43A),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TerraceCard extends StatelessWidget {
  const _TerraceCard();

  @override
  Widget build(BuildContext context) => _Card(
    color: const Color(0xFFDEEBFC),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    child: const Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: _navy, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terraza 6–10 pm',
                style: TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Live Session',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100B3045),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: _navy, size: 22),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard();

  @override
  Widget build(BuildContext context) => _Card(
    color: const Color(0xFFF0EBFC),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 88,
            height: 96,
            child: Transform.scale(
              scale: 1.8,
              child: Image.asset(
                'assets/onboarding/Hero4.webp',
                fit: BoxFit.cover,
                alignment: const Alignment(0, .6),
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sesión en vivo',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Sáb, 18 oct • 7:00 pm',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              SizedBox(height: 6),
              Text(
                'Terraza Brava',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
      ],
    ),
  );
}
