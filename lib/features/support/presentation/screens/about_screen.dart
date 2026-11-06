import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';

/// INF-01.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _partners = [
    'Bangladesh Food Safety Authority',
    'Institute of Public Health Nutrition',
    'UNICEF Bangladesh',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final config = ref.watch(remoteConfigProvider);
    final version = ref.watch(appInfoProvider).version;

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuAbout),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          Center(
            child: Image.asset(
              'assets/logo/e-pusti_logo.png',
              height: 72,
              errorBuilder: (context, error, stackTrace) =>
                  Text(l10n.homeAppTitle, style: theme.textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          Center(
            child: Image.asset(
              'assets/logo/BIID foundation_Logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('BIID Foundation'),
            ),
          ),
          const SizedBox(height: EpSpace.s5),
          Text(l10n.aboutBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: EpSpace.s5),
          Text(l10n.aboutPartners, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          for (final partner in _partners)
            Padding(
              padding: const EdgeInsets.only(bottom: EpSpace.s1),
              child: Text('• $partner'),
            ),
          const SizedBox(height: EpSpace.s4),
          const Divider(),
          _LinkRow(label: l10n.privacyPolicy, url: config.privacyUrl),
          _LinkRow(label: l10n.termsOfUse, url: config.termsUrl),
          const SizedBox(height: EpSpace.s4),
          Center(
            child: Text(
              l10n.versionLabel(version),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        final link = url;
        if (link == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.comingSoonTitle)),
            );
          return;
        }
        Launcher.web(context, link);
      },
    );
  }
}
