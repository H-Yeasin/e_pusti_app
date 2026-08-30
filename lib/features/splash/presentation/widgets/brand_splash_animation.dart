import 'package:flutter/material.dart';

import 'splash_backdrop.dart';
import 'splash_dots.dart';

class BrandSplashAnimation extends StatelessWidget {
  const BrandSplashAnimation({
    super.key,
    required this.haloScale,
    required this.haloOpacity,
    required this.logoScale,
    required this.logoOpacity,
    required this.logoSlide,
    required this.contentSlide,
  });

  final Animation<double> haloScale;
  final Animation<double> haloOpacity;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
  final Animation<Offset> logoSlide;
  final Animation<Offset> contentSlide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02A91F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 30),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: Listenable.merge([haloScale, haloOpacity]),
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: haloScale.value,
                            child: Opacity(
                              opacity: haloOpacity.value,
                              child: const _LogoHalo(),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: SlideTransition(
                      position: logoSlide,
                      child: FadeTransition(
                        opacity: logoOpacity,
                        child: ScaleTransition(
                          scale: logoScale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF006E1A,
                                  ).withValues(alpha: 0.28),
                                  blurRadius: 28,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo/e-pusti_logo.png',
                              width: 206,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: contentSlide,
                    child: FadeTransition(
                      opacity: logoOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'আপনার ব্যক্তিগত পুষ্টি গাইড',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 92),
                          Image.asset(
                            'assets/logo/BIID foundation_Logo.png',
                            width: 232,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'এর একটি উদ্যোগ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: logoOpacity,
                    child: const SplashDots(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoHalo extends StatelessWidget {
  const _LogoHalo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  const Color(0xFF8DEB73).withValues(alpha: 0.13),
                  Colors.transparent,
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          Container(
            width: 214,
            height: 214,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

