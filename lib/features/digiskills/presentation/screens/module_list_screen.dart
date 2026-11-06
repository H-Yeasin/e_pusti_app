import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/commercial/ad_slot.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../assessment/domain/learning_models.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/module_models.dart';
import '../module_lock.dart';

/// DGS-01. When the content server is unreachable the list (last known)
/// and progress still render; only opening a module is blocked.
class ModuleListScreen extends ConsumerWidget {
  const ModuleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final modules = ref.watch(modulesProvider);
    final loggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final progress = loggedIn
        ? ref.watch(progressProvider).value ?? const <ItemProgress>[]
        : const <ItemProgress>[];

    return Scaffold(
      appBar: EpAppBar(title: l10n.homeDigiSkill),
      body: EpAsyncView(
        value: modules,
        onRetry: () => ref.invalidate(modulesProvider),
        data: (list) => ListView(
          padding: const EdgeInsets.all(EpSpace.gutter),
          children: [
            if (list.fromCache) ...[
              EpBanner(
                key: const ValueKey('digi-offline'),
                icon: Icons.cloud_off_rounded,
                message: l10n.digiOfflineBanner,
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(modulesProvider),
                  child: Text(l10n.retryAction),
                ),
              ),
              const SizedBox(height: EpSpace.s4),
            ] else ...[
              Text(
                l10n.digiIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: EpSpace.s4),
            ],
            for (final m in list.modules)
              _ModuleTile(
                module: m,
                progress: progressFor(progress, LearningItemType.module, m.id),
                locked:
                    loggedIn && isAssessmentLocked(m, list.modules, progress),
                enabled: !list.fromCache,
              ),
            const AdSlot(id: AdSlotId.certFooter),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.progress,
    required this.locked,
    required this.enabled,
  });

  final SkillModuleSummary module;
  final ItemProgress? progress;
  final bool locked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final completed = progress?.isCompleted ?? false;
    final started = progress != null && !completed;
    final minutes = l10n.minutesShort(context.digits(module.minutes));
    final status = completed
        ? l10n.digiCompletedScore(context.digits(progress?.scorePercent ?? 0))
        : locked
        ? l10n.digiLockedHint
        : started
        ? '$minutes · ${l10n.statusInProgress}'
        : minutes;

    return Padding(
      padding: const EdgeInsets.only(bottom: EpSpace.s2),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: enabled,
          leading: CircleAvatar(
            backgroundColor: completed ? EpColors.green100 : EpColors.n100,
            foregroundColor: completed
                ? EpColors.green800
                : EpColors.textSecondary,
            child: completed
                ? const Icon(Icons.check_rounded, size: 20)
                : Text(context.digits(module.order)),
          ),
          title: Text(
            module.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Wrap(
            spacing: EpSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(module.source.label),
              if (completed && module.issuesCertificate)
                _Chip(l10n.digiCertBadge, brand: true),
              Text(status),
            ],
          ),
          trailing: locked
              ? Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: EpColors.textMuted,
                  semanticLabel: l10n.digiLockedHint,
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.module(module.id)),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.brand = false});

  final String label;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: brand ? EpColors.green50 : EpColors.n100,
        borderRadius: EpRadius.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: EpTextSize.caption,
          fontWeight: FontWeight.w700,
          color: brand ? EpColors.green800 : EpColors.textSecondary,
        ),
      ),
    );
  }
}
