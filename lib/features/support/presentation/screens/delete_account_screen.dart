import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// INF-05 — states what is deleted and what survives before acting.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _deleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _failed = false;
    });
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = context.l10n.accountDeletedToast;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      router.go(AppRoutes.home);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget item(String text) => Padding(
      padding: const EdgeInsets.only(bottom: EpSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Scaffold(
      appBar: EpAppBar(title: l10n.deleteAccountTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          EpBanner(
            tone: EpBannerTone.destructive,
            icon: Icons.warning_amber_rounded,
            message: l10n.deleteAccountWarning,
          ),
          const SizedBox(height: EpSpace.s5),
          Text(l10n.deleteAccountDeletes, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          item(l10n.deleteAccountProfiles),
          item(l10n.deleteAccountRecords),
          item(l10n.deleteAccountProgress),
          item(l10n.deleteAccountRegistrations),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.deleteAccountStays, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          item(l10n.deleteAccountCertificates),
          item(l10n.deleteAccountPust9),
          if (_failed) ...[
            const SizedBox(height: EpSpace.s3),
            EpBanner(
              tone: EpBannerTone.destructive,
              message: l10n.deleteAccountFailed,
            ),
          ],
          const SizedBox(height: EpSpace.s8),
          FilledButton(
            key: const ValueKey('delete-account-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: EpColors.destructiveFill,
            ),
            onPressed: _deleting ? null : _delete,
            child: Text(l10n.deleteAccountTitle),
          ),
          const SizedBox(height: EpSpace.s2),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.cancelAction),
          ),
        ],
      ),
    );
  }
}
