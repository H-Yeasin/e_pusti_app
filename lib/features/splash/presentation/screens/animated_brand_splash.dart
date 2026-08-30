import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/localization/localization.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../language/presentation/screens/language_selection_screen.dart';
import '../widgets/brand_splash_animation.dart';

class AnimatedBrandSplash extends StatefulWidget {
  const AnimatedBrandSplash({
    super.key,
    required this.environment,
    required this.localeController,
  });

  final AppEnvironment environment;
  final AppLocaleController localeController;

  @override
  State<AnimatedBrandSplash> createState() => _AnimatedBrandSplashState();
}

class _AnimatedBrandSplashState extends State<AnimatedBrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _haloScale;
  late final Animation<double> _haloOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _contentSlide;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();

    _haloScale = Tween<double>(begin: 0.62, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.86, curve: Curves.easeOutCubic),
      ),
    );
    _haloOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 34),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.68), weight: 66),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.92, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.74, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.44, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.66, curve: Curves.easeOutCubic),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 2500), _resolveFirstScreen);
  }

  void _resolveFirstScreen() {
    if (!mounted) {
      return;
    }

    setState(() {
      _nextScreen = widget.localeController.hasChosenLanguage
          ? HomeScreen(environment: widget.environment)
          : LanguageSelectionScreen(
              environment: widget.environment,
              localeController: widget.localeController,
            );
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
      child: _nextScreen ??
          BrandSplashAnimation(
            key: const ValueKey('brand-splash'),
            haloScale: _haloScale,
            haloOpacity: _haloOpacity,
            logoScale: _logoScale,
            logoOpacity: _logoOpacity,
            logoSlide: _logoSlide,
            contentSlide: _contentSlide,
          ),
    );
  }
}
