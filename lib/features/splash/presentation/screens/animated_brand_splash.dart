import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../widgets/brand_splash_animation.dart';

class AnimatedBrandSplash extends StatefulWidget {
  const AnimatedBrandSplash({super.key, required this.environment});

  final AppEnvironment environment;

  @override
  State<AnimatedBrandSplash> createState() => _AnimatedBrandSplashState();
}

class _AnimatedBrandSplashState extends State<AnimatedBrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _contentSlide;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    _glowScale = Tween<double>(begin: 0.78, end: 1.16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.50, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 2350), () {
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
          ? HomeScreen(environment: widget.environment)
          : BrandSplashAnimation(
              key: const ValueKey('brand-splash'),
              glowScale: _glowScale,
              logoScale: _logoScale,
              logoOpacity: _logoOpacity,
              contentSlide: _contentSlide,
            ),
    );
  }
}
