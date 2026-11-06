import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum EpCardTone {
  /// BIID's own content (PUST9, house promotions).
  brand,

  /// Health tools — the clinical palette.
  clinical,
}

/// Home dashboard card: title, one line of copy and one action.
class EpPromoCard extends StatelessWidget {
  const EpPromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.tone = EpCardTone.brand,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final EpCardTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, titleColor, bodyColor) = switch (tone) {
      EpCardTone.brand => (
        EpColors.green50,
        EpColors.green200,
        EpColors.green800,
        EpColors.textSecondary,
      ),
      EpCardTone.clinical => (
        EpColors.clinicalTint,
        EpColors.clinicalLine,
        EpColors.clinicalStrong,
        EpColors.clinicalText,
      ),
    };

    final action = switch (tone) {
      EpCardTone.brand => FilledButton(
        onPressed: onAction,
        child: Text(actionLabel),
      ),
      EpCardTone.clinical => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: EpColors.clinicalStrong,
          side: const BorderSide(color: EpColors.clinicalGraphic),
        ),
        onPressed: onAction,
        child: Text(actionLabel),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(EpSpace.cardPadding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: EpTextSize.heading,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            subtitle,
            style: TextStyle(
              color: bodyColor,
              fontSize: EpTextSize.bodySmall,
              height: 1.45,
            ),
          ),
          const SizedBox(height: EpSpace.s4),
          action,
        ],
      ),
    );
  }
}
