import 'package:flutter/material.dart';
import '../../../../core/localization/digits.dart';
import '../../../journey/journey.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../assessment/domain/learning_models.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../courses/presentation/course_providers.dart';
import '../../../notifications/presentation/engagement_providers.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/profile_labels.dart';
import '../../../profile/presentation/profile_providers.dart';

/// P1-2: one extra card for signed-in users — continue learning, the next
/// registered webinar, family measurements that are due. The rest of the
/// dashboard stays identical logged in or out.
class ForYouCard extends ConsumerWidget {
  const ForYouCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final rows = <Widget>[];
    final now = DateTime.now();

    // Continue learning: the most recent thing started and not finished.
    final progress = ref.watch(progressProvider).value ?? const [];
    final started = progress.where((p) => !p.isCompleted).toList();
    if (started.isNotEmpty) {
      final item = started.last;
      String? title;
      String? route;
      if (item.type == LearningItemType.chapter) {
        title = (ref.watch(chaptersProvider).value ?? const [])
            .where((c) => c.id == item.itemId)
            .firstOrNull
            ?.title;
        route = AppRoutes.chapter(item.itemId);
      } else {
        title = (ref.watch(modulesProvider).value?.modules ?? const [])
            .where((m) => m.id == item.itemId)
            .firstOrNull
            ?.title;
        route = AppRoutes.module(item.itemId);
      }
      if (title != null) {
        rows.add(
          _Row(
            key: const ValueKey('for-you-continue'),
            icon: Icons.play_lesson_outlined,
            label: l10n.homeContinue,
            text: title,
            onTap: () => context.push(route!),
          ),
        );
      }
    }

    // Next registered webinar.
    final registered = {
      for (final r in ref.watch(registrationsProvider).value ?? const [])
        r.webinarId,
    };
    final next =
        (ref.watch(webinarsWithSeatsProvider).value ?? const [])
            .where((w) => registered.contains(w.id) && !w.isPast(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    if (next.isNotEmpty) {
      final w = next.first;
      rows.add(
        _Row(
          key: const ValueKey('for-you-webinar'),
          icon: Icons.videocam_outlined,
          label: l10n.homeNextWebinar,
          text: '${w.title}\n${formatEventDateTime(context, w.startsAt)}',
          onTap: () => context.push(AppRoutes.webinar(w.id)),
        ),
      );
    }

    final family = ref.watch(familyProvider).value ?? const <Person>[];

    // Pregnancy / breastfeeding journey.
    final journey = journeyFor(family, now);
    if (journey != null) {
      final week = journey.week;
      rows.add(
        _Row(
          key: const ValueKey('for-you-journey'),
          icon: Icons.pregnant_woman_outlined,
          label: l10n.journeyTitle,
          text: week == null
              ? (journey.stage == JourneyStage.pregnancy
                    ? l10n.journeyAddDueDate
                    : l10n.journeyAddBaby)
              : journey.stage == JourneyStage.pregnancy
              ? '${l10n.journeyPregnancy} · ${l10n.journeyPregnancyWeek(context.digits(week))}'
              : '${l10n.journeyBreastfeeding} · ${l10n.journeyBabyWeek(personName(context, journey.baby!), context.digits(week))}',
          onTap: () => context.push(AppRoutes.journey),
        ),
      );
    }

    // Family measurements that are due.
    final planner = ref.watch(reminderPlannerProvider);
    for (final person in family) {
      final records =
          ref.watch(measurementsProvider(person.id)).value ?? const [];
      if (records.isEmpty) continue;
      if (planner.dueDate(person, records.first).isAfter(now)) continue;
      rows.add(
        _Row(
          key: ValueKey('for-you-measure-${person.id}'),
          icon: Icons.monitor_weight_outlined,
          label: l10n.homeMeasureDue(personName(context, person)),
          action: l10n.homeMeasureAction,
          onTap: () => context.push(
            Uri(
              path: AppRoutes.bmi,
              queryParameters: {'p': person.id},
            ).toString(),
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('for-you'),
      padding: const EdgeInsets.only(top: EpSpace.s5),
      child: Material(
        color: EpColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: EpRadius.mdAll,
          side: BorderSide(color: EpColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EpSpace.s4,
                EpSpace.s3,
                EpSpace.s4,
                0,
              ),
              child: Text(
                l10n.homeForYou,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.text,
    this.action,
  });

  final IconData icon;
  final String label;
  final String? text;
  final String? action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: EpColors.green700),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: text == null
          ? null
          : Text(text!, style: Theme.of(context).textTheme.titleMedium),
      trailing: action == null
          ? const Icon(Icons.chevron_right_rounded)
          : TextButton(onPressed: onTap, child: Text(action!)),
      onTap: onTap,
    );
  }
}
