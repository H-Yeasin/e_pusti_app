import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';

/// SYS-04. No dismiss and no back: the installed version is unsupported.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(remoteConfigProvider);
    final latest = config.latestVersion;
    final size = config.updateSizeMb;
    final storeUrl = config.storeUrl;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: EpColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(EpSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/logo/e-pusti_logo.png',
                  height: 72,
                  errorBuilder: (context, error, stackTrace) =>
                      Text(l10n.homeAppTitle, textAlign: TextAlign.center),
                ),
                const SizedBox(height: EpSpace.s8),
                Text(
                  l10n.updateTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: EpSpace.s3),
                Text(
                  l10n.updateBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (latest != null && size != null) ...[
                  const SizedBox(height: EpSpace.s4),
                  Text(
                    l10n.updateVersionSize(latest, size.toStringAsFixed(0)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: storeUrl == null
                      ? null
                      : () => Launcher.web(context, storeUrl),
                  child: Text(l10n.updateAction),
                ),
                const SizedBox(height: EpSpace.s3),
                Text(
                  context.digits(l10n.updateRequiredNote),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
