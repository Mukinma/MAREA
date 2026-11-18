import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/intro_decorations.dart';
import 'package:marea/features/auth/presentation/intro_waves.dart';

const _introCanvas = Color(0xFFF7FAFC);

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
        duration: const Duration(milliseconds: 240),
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
    final nextLabel = _page == _slides.length - 1 ? 'Comenzar' : 'Siguiente';
    void next() =>
        _page == _slides.length - 1 ? widget.onComplete() : _goTo(_page + 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _introCanvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const Key('mobile-intro'),
        backgroundColor: _introCanvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: AccessHeader(
                      brandWidth: 120,
                      end: TextButton(
                        key: const Key('intro-skip'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: widget.onComplete,
                        child: const Text(
                          'Saltar',
                          textAlign: TextAlign.center,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final labelFits =
                            bounds.maxWidth >= 324 &&
                            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                        const nextKey = Key('intro-next');
                        const arrow = Icon(
                          Icons.arrow_forward_rounded,
                          size: 21,
                        );
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < _slides.length;
                                  index++
                                )
                                  _pageButton(index),
                              ],
                            ),
                            if (labelFits)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: FilledButton(
                                    key: nextKey,
                                    onPressed: next,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 8,
                                      children: [
                                        Flexible(child: Text(nextLabel)),
                                        arrow,
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              IconButton.filled(
                                key: nextKey,
                                tooltip: nextLabel,
                                onPressed: next,
                                icon: arrow,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageButton(int index) {
    final selected = _page == index;
    return Semantics(
      key: Key('intro-dot-$index'),
      button: true,
      selected: selected,
      label: 'Pantalla ${index + 1} de ${_slides.length}',
      child: InkResponse(
        onTap: () => _goTo(index),
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              width: selected ? 24 : 9,
              height: 9,
              decoration: BoxDecoration(
                color: selected ? AppColors.aquaDark : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.title, this.description, this.alignment);

  final String title, description;
  final Alignment alignment;
}

const _slides = [
  _Slide(
    'Tu ciudad\ntambién crea',
    'Descubre a las personas y los proyectos que le dan vida a tu comunidad.',
    Alignment(0, .75),
  ),
  _Slide(
    'Descubre nuevos lugares',
    'Encuentra cafeterías, restaurantes y espacios culturales cerca de ti.',
    Alignment(0, .7),
  ),
  _Slide(
    'Conecta con talento local',
    'Conoce a artistas, emprendedores y negocios con quienes puedes colaborar.',
    Alignment(0, .5),
  ),
  _Slide(
    'Encuentra tu próxima misión',
    'Explora oportunidades para crear, aprender o participar en tu ciudad.',
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
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.hero),
              child: SizedBox(
                height: (bounds.maxHeight * .66).clamp(164, 520),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/onboarding/Hero${widget.index + 1}.webp',
                      fit: BoxFit.cover,
                      alignment: slide.alignment,
                      excludeFromSemantics: true,
                      filterQuality: FilterQuality.medium,
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
                    const Positioned(
                      bottom: -1,
                      left: 0,
                      right: 0,
                      height: 28,
                      child: IgnorePointer(
                        child: CustomPaint(painter: IntroWavesPainter()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                slide.title,
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 34),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              slide.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
