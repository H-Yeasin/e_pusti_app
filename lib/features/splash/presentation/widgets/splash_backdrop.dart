import 'package:flutter/material.dart';

import 'glow_orb.dart';

class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B926),
            Color(0xFF00A81D),
            Color(0xFF049A22),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -92,
            right: -74,
            child: GlowOrb(
              size: 250,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -92,
            child: GlowOrb(
              size: 280,
              color: const Color(0xFF7ED957).withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}
