import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../assessment/domain/learning_models.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../../domain/module_models.dart';
import '../module_lock.dart';

/// DGS-02. Content from the VPS; when it can't be fetched the failure view
/// says progress is safe.
class ModuleScreen extends ConsumerStatefulWidget {
  const ModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(authControllerProvider).isLoggedIn) {
      ref
          .read(progressProvider.notifier)
          .markStarted(LearningItemType.module, widget.moduleId);
    }
  }

  void _assess(String assessmentId) {
    if (!ref.read(authControllerProvider).isLoggedIn) {
      showLoginPrompt(
        context,
        returnTo: GoRouterState.of(context).uri.toString(),
        body: context.l10n.assessmentLoginBody,
      );
      return;
    }
    context.push(AppRoutes.assessment(assessmentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final module = ref.watch(moduleProvider(widget.moduleId));
    final loggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final list = ref.watch(modulesProvider).value?.modules ?? const [];
    final progress = loggedIn
        ? ref.watch(progressProvider).value ?? const <ItemProgress>[]
        : const <ItemProgress>[];

    return Scaffold(
      appBar: EpAppBar(
        title: module.value?.summary.title ?? l10n.homeDigiSkill,
      ),
      body: EpAsyncView(
        value: module,
        onRetry: () => ref.invalidate(moduleProvider(widget.moduleId)),
        data: (m) {
          final summary = m.summary;
          final locked =
              loggedIn && isAssessmentLocked(summary, list, progress);
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              if (summary.issuesCertificate)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(
                    avatar: const Icon(
                      Icons.workspace_premium_outlined,
                      size: 18,
                      color: EpColors.green800,
                    ),
                    label: Text(l10n.digiApprovedCert(summary.source.label)),
                    backgroundColor: EpColors.green50,
                    side: BorderSide.none,
                  ),
                ),
              const SizedBox(height: EpSpace.s3),
              for (final p in m.paragraphs) ...[
                Text(p, style: theme.textTheme.bodyLarge),
                const SizedBox(height: EpSpace.s4),
              ],
              const SizedBox(height: EpSpace.s2),
              if (summary.assessmentId == null)
                EpBanner(
                  icon: Icons.schedule_rounded,
                  message: l10n.assessmentSoon,
                )
              else if (locked)
                EpBanner(
                  key: const ValueKey('module-locked'),
                  icon: Icons.lock_outline_rounded,
                  message: l10n.digiLockedHint,
                )
              else ...[
                if (summary.issuesCertificate)
                  Text(
                    l10n.digiPassToCert(context.digits(70)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: EpSpace.s2),
                FilledButton(
                  onPressed: () => _assess(summary.assessmentId!),
                  child: Text(l10n.takeAssessmentAction),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
