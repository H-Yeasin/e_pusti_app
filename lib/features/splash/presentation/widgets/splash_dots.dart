import 'package:flutter/material.dart';

class SplashDots extends StatelessWidget {
  const SplashDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: index == 0 ? 9 : 8,
          height: index == 0 ? 9 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: index == 0 ? 1 : 0.46),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
