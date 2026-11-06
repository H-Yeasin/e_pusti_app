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
import '../../../auth/presentation/providers/auth_controller.dart';
import '../course_providers.dart';

/// CRS-01. All chapters are browsable without an account. The progress
/// header (logged-in variant) arrives with synced progress in Phase 3.
class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chapters = ref.watch(chaptersProvider);
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final read = ref.watch(readChaptersProvider).value ?? const <String>{};

    return Scaffold(
      appBar: EpAppBar(title: l10n.academyTitle),
      body: EpAsyncView(
        value: chapters,
        onRetry: () => ref.invalidate(chaptersProvider),
        data: (items) => ListView(
          padding: const EdgeInsets.all(EpSpace.gutter),
          children: [
            const AdSlot(
              id: AdSlotId.chapterHeader,
              padding: EdgeInsets.only(bottom: EpSpace.s4),
            ),
            if (!isLoggedIn) ...[
              EpBanner(
                icon: Icons.info_outline_rounded,
                message: l10n.coursesLoggedOutNote,
              ),
              const SizedBox(height: EpSpace.s4),
            ],
            for (final chapter in items)
              Padding(
                padding: const EdgeInsets.only(bottom: EpSpace.s2),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: read.contains(chapter.id)
                          ? EpColors.green100
                          : EpColors.n100,
                      foregroundColor: read.contains(chapter.id)
                          ? EpColors.green800
                          : EpColors.textSecondary,
                      child: read.contains(chapter.id)
                          ? const Icon(Icons.check_rounded, size: 20)
                          : Text(context.digits(chapter.number)),
                    ),
                    title: Text(
                      l10n.chapterNumbered(
                        context.digits(chapter.number),
                        chapter.title,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      l10n.minutesShort(context.digits(chapter.minutes)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.chapter(chapter.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
