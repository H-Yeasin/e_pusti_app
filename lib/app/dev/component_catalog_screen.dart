import 'package:flutter/material.dart';

import '../../core/localization/localization.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/display/ep_promo_card.dart';
import '../../core/widgets/feedback/ep_state_view.dart';
import '../../core/widgets/navigation/ep_app_bar.dart';

/// Dev-only page for checking tokens and shared widgets against the design.
class ComponentCatalogScreen extends StatelessWidget {
  const ComponentCatalogScreen({super.key});

  static const _swatches = <(String, Color)>[
    ('green-50', EpColors.green50),
    ('green-200', EpColors.green200),
    ('green-500 brand', EpColors.green500),
    ('green-600 primary', EpColors.green600),
    ('green-800', EpColors.green800),
    ('n-50 bg', EpColors.n50),
    ('n-200', EpColors.n200),
    ('n-600', EpColors.n600),
    ('n-900 text', EpColors.n900),
    ('clinical tint', EpColors.clinicalTint),
    ('clinical graphic', EpColors.clinicalGraphic),
    ('clinical strong', EpColors.clinicalStrong),
    ('destructive fill', EpColors.destructiveFill),
    ('destructive tint', EpColors.destructiveTint),
    ('partner red (slot only)', EpColors.partnerRed),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: EpAppBar(title: context.l10n.devCatalogTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          Text('Colours', style: theme.textTheme.titleLarge),
          const SizedBox(height: EpSpace.s2),
          Wrap(
            spacing: EpSpace.s2,
            runSpacing: EpSpace.s2,
            children: [
              for (final (name, color) in _swatches)
                SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: EpRadius.smAll,
                          border: Border.all(color: EpColors.borderSubtle),
                        ),
                      ),
                      Text(name, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: EpSpace.s6),
          Text('Buttons', style: theme.textTheme.titleLarge),
          const SizedBox(height: EpSpace.s2),
          Wrap(
            spacing: EpSpace.s2,
            runSpacing: EpSpace.s2,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Primary')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
              OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
              TextButton(onPressed: () {}, child: const Text('Ghost')),
            ],
          ),
          const SizedBox(height: EpSpace.s6),
          Text('Cards', style: theme.textTheme.titleLarge),
          const SizedBox(height: EpSpace.s2),
          EpPromoCard(
            title: 'Brand card',
            subtitle: 'House content such as PUST9.',
            actionLabel: 'Action',
            onAction: () {},
          ),
          const SizedBox(height: EpSpace.s3),
          EpPromoCard(
            tone: EpCardTone.clinical,
            title: 'Clinical card',
            subtitle: 'Health tools use the clinical palette only.',
            actionLabel: 'Action',
            onAction: () {},
          ),
          const SizedBox(height: EpSpace.s6),
          Text('States', style: theme.textTheme.titleLarge),
          const SizedBox(
            height: 320,
            child: EpStateView(
              icon: Icons.wifi_off_rounded,
              title: 'No internet connection',
              body: 'Downloaded documents are still available.',
              primaryLabel: 'Try again',
            ),
          ),
          const SizedBox(
            height: 340,
            child: EpStateView(
              tone: EpStateTone.destructive,
              icon: Icons.warning_amber_rounded,
              title: 'Something went wrong',
              body: "It's not your fault. Please try again shortly.",
              primaryLabel: 'Try again',
              secondaryLabel: 'Tell support',
              footnote: 'ERR-503 · 2026-08-30 09:41',
            ),
          ),
        ],
      ),
    );
  }
}
