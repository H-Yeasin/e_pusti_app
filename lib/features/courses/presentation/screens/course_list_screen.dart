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
import '../../../assessment/domain/learning_models.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../domain/course_models.dart';
import '../course_providers.dart';

/// CRS-01. All chapters are browsable without an account; logged in, the
/// list shows synced progress (a chapter completes when its quiz is passed).
class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chapters = ref.watch(chaptersProvider);
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final read = ref.watch(readChaptersProvider).value ?? const <String>{};
    final progress = isLoggedIn
        ? ref.watch(progressProvider).value ?? const <ItemProgress>[]
        : const <ItemProgress>[];

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
            ] else ...[
              _ProgressHeader(
                done: items
                    .where(
                      (c) =>
                          progressFor(
                            progress,
                            LearningItemType.chapter,
                            c.id,
                          )?.isCompleted ??
                          false,
                    )
                    .length,
                total: items.length,
              ),
              const SizedBox(height: EpSpace.s4),
            ],
            for (final chapter in items)
              _ChapterTile(
                chapter: chapter,
                progress: isLoggedIn
                    ? progressFor(
                        progress,
                        LearningItemType.chapter,
                        chapter.id,
                      )
                    : null,
                read: !isLoggedIn && read.contains(chapter.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('academy-progress'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.academyProgress(
            context.digits(done),
            context.digits(total),
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EpSpace.s2),
        ClipRRect(
          borderRadius: EpRadius.smAll,
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            backgroundColor: EpColors.n100,
            color: EpColors.fillPrimary,
          ),
        ),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.progress,
    required this.read,
  });

  final ChapterSummary chapter;
  final ItemProgress? progress;

  /// Logged out: opened on this device.
  final bool read;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final completed = progress?.isCompleted ?? false;
    final started = progress != null && !completed;
    final ticked = completed || read;
    final minutes = l10n.minutesShort(context.digits(chapter.minutes));
    final subtitle = completed
        ? '$minutes · ${l10n.statusCompleted}'
        : started
        ? '$minutes · ${l10n.statusInProgress}'
        : minutes;

    return Padding(
      padding: const EdgeInsets.only(bottom: EpSpace.s2),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: ticked
                ? EpColors.green100
                : started
                ? EpColors.green50
                : EpColors.n100,
            foregroundColor: ticked
                ? EpColors.green800
                : EpColors.textSecondary,
            child: ticked
                ? const Icon(Icons.check_rounded, size: 20)
                : Text(context.digits(chapter.number)),
          ),
          title: Text(
            l10n.chapterNumbered(context.digits(chapter.number), chapter.title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.chapter(chapter.id)),
        ),
      ),
    );
  }
}
