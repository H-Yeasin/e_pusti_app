import 'package:flutter/material.dart';

import 'splash_backdrop.dart';
import 'splash_dots.dart';

class BrandSplashAnimation extends StatelessWidget {
  const BrandSplashAnimation({
    super.key,
    required this.glowScale,
    required this.logoScale,
    required this.logoOpacity,
    required this.contentSlide,
  });

  final Animation<double> glowScale;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
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
                                    Colors.white.withValues(alpha: 0.48),
                                    const Color(
                                      0xFF7ED957,
                                    ).withValues(alpha: 0.30),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    blurRadius: 58,
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
                          width: 202,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SlideTransition(
                    position: contentSlide,
                    child: FadeTransition(
                      opacity: logoOpacity,
                      child: Column(
                        children: [
                          const Text(
                            '\u{986}\u{9AA}\u{9A8}\u{9BE}\u{9B0} \u{9AC}\u{9CD}\u{9AF}\u{995}\u{9CD}\u{9A4}\u{9BF}\u{997}\u{9A4} \u{9AA}\u{9C1}\u{9B7}\u{9CD}\u{99F}\u{9BF} \u{997}\u{9BE}\u{987}\u{9A1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 100),
                          Image.asset(
                            'assets/logo/BIID foundation_Logo.png',
                            width: 232,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '\u{98F}\u{9B0} \u{98F}\u{995}\u{99F}\u{9BF} \u{989}\u{9A6}\u{9CD}\u{9AF}\u{9CB}\u{997}',
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
