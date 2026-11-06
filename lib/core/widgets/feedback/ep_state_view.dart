import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum EpStateTone { neutral, destructive }

/// Full-area message for empty, offline, error and "coming soon" states.
///
/// Every state says what happened and offers a next step — never a dead end.
class EpStateView extends StatelessWidget {
  const EpStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tone = EpStateTone.neutral,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final EpStateTone tone;

  /// Small print such as an error code and time (SYS-03).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (iconBackground, iconColor) = switch (tone) {
      EpStateTone.neutral => (EpColors.n100, EpColors.n600),
      EpStateTone.destructive => (
        EpColors.destructiveTint,
        EpColors.destructiveFill,
      ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: EpSpace.s6,
          vertical: EpSpace.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: EpSpace.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: EpSpace.s2),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (primaryLabel != null) ...[
              const SizedBox(height: EpSpace.s6),
              FilledButton(onPressed: onPrimary, child: Text(primaryLabel!)),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: EpSpace.s2),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
            if (footnote != null) ...[
              const SizedBox(height: EpSpace.s4),
              Text(footnote!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
