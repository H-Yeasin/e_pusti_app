import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum EpBannerTone { info, brand, clinical, destructive }

/// Inline note inside a screen, e.g. "only for Robi and Airtel" or a data
/// cost warning.
class EpBanner extends StatelessWidget {
  const EpBanner({
    super.key,
    required this.message,
    this.icon,
    this.tone = EpBannerTone.info,
    this.action,
  });

  final String message;
  final IconData? icon;
  final EpBannerTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (tone) {
      EpBannerTone.info => (EpColors.n100, EpColors.n200, EpColors.n800),
      EpBannerTone.brand => (
        EpColors.green50,
        EpColors.green200,
        EpColors.green800,
      ),
      EpBannerTone.clinical => (
        EpColors.clinicalTint,
        EpColors.clinicalLine,
        EpColors.clinicalStrong,
      ),
      EpBannerTone.destructive => (
        EpColors.destructiveTint,
        EpColors.destructiveLine,
        EpColors.destructiveStrong,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(EpSpace.s3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: EpSpace.s2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontSize: EpTextSize.bodySmall,
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: EpSpace.s2),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
