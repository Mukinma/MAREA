import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/features/auth/presentation/intro_decorations.dart';
import 'package:marea/features/auth/presentation/intro_waves.dart';

const introBackground = Color(0xFFEFF8FC);
const introForeground = Color(0xFFF7FAFC);
const introNavy = Color(0xFF0B3045);
const introAqua = Color(0xFF19C2CC);
const introMuted = Color(0xFF6B889D);

class MobileIntroScreen extends StatefulWidget {
  const MobileIntroScreen({required this.onComplete, super.key});
  final VoidCallback onComplete;

  @override
  State<MobileIntroScreen> createState() => _MobileIntroScreenState();
}

class _MobileIntroScreenState extends State<MobileIntroScreen>
    with WidgetsBindingObserver {
  final _pages = PageController();
  int _page = 0;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: introForeground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const Key('mobile-intro'),
        backgroundColor: introBackground,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 24, 0),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Semantics(
                        label: 'MAREA',
                        image: true,
                        child: Image.asset(
                          'assets/brand/MAREA_LOGOTIPO.png',
                          width: 124,
                          height: 36,
                          excludeFromSemantics: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        key: const Key('intro-skip'),
                        onPressed: widget.onComplete,
                        style: TextButton.styleFrom(
                          foregroundColor: introNavy,
                          textStyle: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Saltar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('intro-pages'),
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (_, index) => _IntroPage(
                  key: ValueKey(index),
                  index: index,
                  active: _page == index,
                  foreground: _foreground,
                ),
              ),
            ),
            ColoredBox(
              color: introForeground,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _slides.length,
                          (index) => Semantics(
                            key: Key('intro-dot-$index'),
                            button: true,
                            selected: _page == index,
                            label: 'Pantalla ${index + 1} de 4',
                            child: InkResponse(
                              onTap: () => _goTo(index),
                              radius: 24,
                              child: SizedBox(
                                width: 28,
                                height: 48,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 250),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: index == _page
                                          ? introAqua
                                          : const Color(0xFFD2E0E7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        child: IconButton.filled(
                          key: const Key('intro-next'),
                          tooltip: _page == 3 ? 'Comenzar' : 'Siguiente',
                          style: IconButton.styleFrom(
                            backgroundColor: introNavy,
                            foregroundColor: Colors.white,
                            fixedSize: const Size(56, 56),
                          ),
                          onPressed: () => _page == 3
                              ? widget.onComplete()
                              : _goTo(_page + 1),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 27,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.title, this.description, this.alignment);
  final List<TextSpan> title;
  final String description;
  final Alignment alignment;
}

const _accent = TextStyle(color: introAqua);
const _slides = [
  _Slide(
    [
      TextSpan(text: 'Tu ciudad\ntambién '),
      TextSpan(text: 'crea.', style: _accent),
    ],
    'Conecta con artistas, emprendedores, negocios y experiencias cerca de ti.',
    Alignment(0, .75),
  ),
  _Slide(
    [
      TextSpan(text: 'Descubre\nnuevos '),
      TextSpan(text: 'lugares.', style: _accent),
    ],
    'Explora cafeterías, restaurantes, espacios culturales y más.',
    Alignment(0, .7),
  ),
  _Slide(
    [
      TextSpan(text: 'Conecta\n'),
      TextSpan(text: 'talento', style: _accent),
      TextSpan(text: ' local.'),
    ],
    'Encuentra artistas, emprendedores y colaboraciones reales.',
    Alignment(0, .5),
  ),
  _Slide(
    [
      TextSpan(text: 'Vive\nexperiencias '),
      TextSpan(text: 'reales.', style: _accent),
    ],
    'Eventos, pop-ups, bazares, sesiones en vivo y más cerca de ti.',
    Alignment(0, .7),
  ),
];

class _IntroPage extends StatefulWidget {
  const _IntroPage({
    required this.index,
    required this.active,
    required this.foreground,
    super.key,
  });
  final int index;
  final bool active;
  final bool foreground;

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage> with TickerProviderStateMixin {
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _moving = false;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    // Decode the next photo during this page, not during the swipe.
    if (widget.index < 3) {
      precacheImage(
        AssetImage('assets/onboarding/Hero${widget.index + 2}.webp'),
        context,
      );
    }
  }

  @override
  void didUpdateWidget(_IntroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final moving =
        widget.active &&
        widget.foreground &&
        !reduced &&
        TickerMode.valuesOf(context).enabled;
    if (moving != _moving) {
      _moving = moving;
      if (moving) {
        _drift.repeat();
      } else {
        _drift.stop();
        _entrance.stop();
      }
    }
    if (reduced) {
      _entrance.value = 1;
    } else if (moving && (!_wasActive || _entrance.value < 1)) {
      _entrance.forward(from: _wasActive ? _entrance.value : 0);
    }
    _wasActive = widget.active;
  }

  @override
  void dispose() {
    _drift.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[widget.index];
    final reduced = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, bounds) {
        final width = bounds.maxWidth;
        final titleSize = (width / 390 * 36).clamp(29.0, 40.0);
        return CustomScrollView(
          // Large accessibility text can scroll vertically while navigation
          // stays visible. At normal sizes, the photo fills the viewport.
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(width * .105, 20, width * .065, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text.rich(
                        TextSpan(children: slide.title),
                        style: TextStyle(
                          color: introNavy,
                          fontSize: titleSize,
                          height: 1.15,
                          letterSpacing: -.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: introMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox(
                height: 200,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _drift,
                          child: Image.asset(
                            'assets/onboarding/Hero${widget.index + 1}.webp',
                            fit: BoxFit.cover,
                            alignment: slide.alignment,
                            excludeFromSemantics: true,
                            filterQuality: FilterQuality.medium,
                          ),
                          builder: (_, child) => Transform.scale(
                            scale: reduced
                                ? 1
                                : 1.012 +
                                      math.sin(_drift.value * math.pi * 2) *
                                          .006,
                            alignment: slide.alignment,
                            child: child,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: (width * .25).clamp(80.0, 110.0),
                        child: const IgnorePointer(
                          child: DecoratedBox(
                            key: Key('intro-photo-fade'),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  introBackground,
                                  Color(0xD9EFF8FC),
                                  Color(0x00EFF8FC),
                                ],
                                stops: [0, .25, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: IntroDecorations(
                            page: widget.index,
                            drift: _drift,
                            entrance: _entrance,
                            reducedMotion: reduced,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        height: width * 2063 / 9055,
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _drift,
                              builder: (_, _) => CustomPaint(
                                painter: IntroWavesPainter(
                                  drift: reduced
                                      ? 0
                                      : math.sin(_drift.value * math.pi * 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
