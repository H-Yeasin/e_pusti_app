import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../profile/presentation/profile_providers.dart';

/// INF-07 (added to the design): consent can be withdrawn as easily as it
/// was given.
class PrivacyCentreScreen extends ConsumerWidget {
  const PrivacyCentreScreen({super.key});

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.privacyWithdrawConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: EpColors.destructiveFill,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.withdrawAction),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(consentProvider.notifier).withdrawHealthData();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final consent = ref.watch(consentProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.privacyCentreTitle),
      body: EpAsyncView(
        value: consent,
        onRetry: () => ref.invalidate(consentProvider),
        data: (record) {
          final accepted = record.termsAcceptedAt;
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              Text(
                l10n.consentBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: EpSpace.s5),
              if (accepted != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(
                    l10n.privacyTermsAccepted(
                      '${formatShortDate(context, accepted)} '
                      '${context.digits(accepted.year)}',
                    ),
                  ),
                ),
              ListTile(
                key: const ValueKey('privacy-health-status'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text(
                  record.canStoreHealthData
                      ? l10n.privacyHealthOn
                      : l10n.privacyHealthOff,
                ),
              ),
              const SizedBox(height: EpSpace.s4),
              if (record.canStoreHealthData)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EpColors.destructiveFill,
                    side: const BorderSide(color: EpColors.destructiveFill),
                  ),
                  onPressed: () => _withdraw(context, ref),
                  child: Text(l10n.privacyWithdraw),
                )
              else
                FilledButton(
                  onPressed: () => context.push(
                    AppRoutes.consentReturningTo(AppRoutes.privacyCentre),
                  ),
                  child: Text(l10n.privacyGiveConsent),
                ),
            ],
          );
        },
      ),
    );
  }
}
