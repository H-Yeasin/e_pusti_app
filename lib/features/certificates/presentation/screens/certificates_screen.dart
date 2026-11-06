import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../assessment/presentation/learning_providers.dart';

/// CRT-01 — populated, or empty with a route to the modules.
class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final certificates = ref.watch(certificatesProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuCertificates),
      body: EpAsyncView(
        value: certificates,
        onRetry: () => ref.invalidate(certificatesProvider),
        data: (items) {
          if (items.isEmpty) {
            return EpStateView(
              key: const ValueKey('certificates-empty'),
              icon: Icons.workspace_premium_outlined,
              title: l10n.certificatesEmptyTitle,
              body: l10n.certificatesEmptyBody,
              primaryLabel: l10n.seeModulesAction,
              onPrimary: () => context.push(AppRoutes.digiSkills),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              for (final c in items)
                Card(
                  margin: const EdgeInsets.only(bottom: EpSpace.s2),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      Icons.workspace_premium_rounded,
                      color: c.isRevoked ? EpColors.n500 : EpColors.green700,
                    ),
                    title: Text(
                      c.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${c.code} · ${c.isRevoked ? l10n.revokedStamp : '${formatShortDate(context, c.issuedAt)} ${context.digits(c.issuedAt.year)}'}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.certificate(c.code)),
                  ),
                ),
              const SizedBox(height: EpSpace.s3),
              Text(
                l10n.certificatesNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
