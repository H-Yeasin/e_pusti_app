import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_environment.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError('App environment must be overridden at bootstrap.');
});

void bootstrap(AppEnvironment environment) {
  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
      ],
      child: const EPustiApp(),
    ),
  );
}

class EPustiApp extends ConsumerWidget {
  const EPustiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);

    return MaterialApp(
      title: 'e-Pushti',
      debugShowCheckedModeBanner: environment != AppEnvironment.prod,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F9D55)),
        useMaterial3: true,
      ),
      home: _AnimatedBrandSplash(environment: environment),
    );
  }
}

class _AnimatedBrandSplash extends StatefulWidget {
  const _AnimatedBrandSplash({required this.environment});

  final AppEnvironment environment;

  @override
  State<_AnimatedBrandSplash> createState() => _AnimatedBrandSplashState();
}

class _AnimatedBrandSplashState extends State<_AnimatedBrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _glowScale = Tween<double>(begin: 0.78, end: 1.16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.46, curve: Curves.easeOut),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 1850), () {
      if (mounted) {
        setState(() => _showHome = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showHome
          ? _HomeScreen(environment: widget.environment)
          : _BrandSplashAnimation(
              key: const ValueKey('brand-splash'),
              glowScale: _glowScale,
              logoScale: _logoScale,
              logoOpacity: _logoOpacity,
            ),
    );
  }
}

class _BrandSplashAnimation extends StatelessWidget {
  const _BrandSplashAnimation({
    super.key,
    required this.glowScale,
    required this.logoScale,
    required this.logoOpacity,
  });

  final Animation<double> glowScale;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FFF8),
      body: Center(
        child: AnimatedBuilder(
          animation: glowScale,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: glowScale.value,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7ED957).withValues(alpha: 0.38),
                          const Color(0xFF1F9D55).withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2FBF71)
                              .withValues(alpha: 0.28),
                          blurRadius: 56,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: FadeTransition(
            opacity: logoOpacity,
            child: ScaleTransition(
              scale: logoScale,
              child: Image.asset(
                'assets/logo/e-pusti_logo.png',
                width: 168,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.environment});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('e-Pushti')),
      body: Center(child: Text('Running ${environment.label}')),
    );
  }
}
