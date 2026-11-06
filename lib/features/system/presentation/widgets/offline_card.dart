import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../library/presentation/library_providers.dart';

/// SYS-01 on the dashboard: says what still works without a connection.
/// Collapses to nothing while online.
class OfflineCard extends ConsumerWidget {
  const OfflineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    if (online) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final downloaded = ref.watch(downloadedCountProvider);

    Widget row(
      IconData icon,
      String text, {
      VoidCallback? onTap,
      bool locked = false,
    }) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: locked ? EpColors.textMuted : EpColors.green700,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: locked ? EpColors.textMuted : EpColors.textPrimary,
          ),
        ),
        trailing: locked
            ? Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: EpColors.textMuted,
                semanticLabel: l10n.offlineNotNow,
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
    }

    return Padding(
      key: const ValueKey('offline-card'),
      padding: const EdgeInsets.only(bottom: EpSpace.s5),
      child: Material(
        color: EpColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: EpRadius.mdAll,
          side: BorderSide(color: EpColors.borderDefault),
        ),
        child: Padding(
          padding: const EdgeInsets.all(EpSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: EpColors.textSecondary,
                  ),
                  const SizedBox(width: EpSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.offlineTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EpSpace.s2),
              Text(
                l10n.offlineAvailableIntro,
                style: theme.textTheme.bodyMedium,
              ),
              row(
                Icons.description_outlined,
                l10n.offlineDownloadedDocs(context.digits(downloaded)),
                onTap: () => context.push(AppRoutes.downloads),
              ),
              row(
                Icons.menu_book_outlined,
                l10n.offlineReadChapters,
                onTap: () => context.push(AppRoutes.courses),
              ),
              row(
                Icons.monitor_weight_outlined,
                l10n.offlineBmi,
                onTap: () => context.push(AppRoutes.bmi),
              ),
              row(
                Icons.play_circle_outline_rounded,
                l10n.offlineVideoWebinar,
                locked: true,
              ),
              const SizedBox(height: EpSpace.s2),
              OutlinedButton(
                onPressed: () => ref.invalidate(isOnlineProvider),
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
