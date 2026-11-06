import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/config/remote_config.dart';
import '../../core/localization/date_format.dart';
import '../../core/localization/digits.dart';
import '../../core/localization/localization.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/content/listen_button.dart';
import '../../core/widgets/feedback/ep_async_view.dart';
import '../../core/widgets/feedback/ep_banner.dart';
import '../../core/widgets/feedback/ep_state_view.dart';
import '../../core/widgets/navigation/ep_app_bar.dart';
import '../notifications/data/reminder_scheduler.dart';
import '../notifications/presentation/engagement_providers.dart';
import '../profile/presentation/profile_labels.dart';
import '../profile/presentation/profile_providers.dart';
import 'journey.dart';

/// P2-2: pregnancy and breastfeeding journey for the account holder.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final family = ref.watch(familyProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.journeyTitle),
      body: EpAsyncView(
        value: family,
        onRetry: () => ref.invalidate(familyProvider),
        data: (people) {
          final journey = journeyFor(people, DateTime.now());
          final holder = people.where((p) => p.isHolder).firstOrNull;
          if (journey == null || holder == null) {
            return EpStateView(
              key: const ValueKey('journey-none'),
              icon: Icons.pregnant_woman_outlined,
              title: l10n.journeyNoneTitle,
              body: l10n.journeyNoneBody,
              primaryLabel: l10n.editAction,
              onPrimary: () => context.push(AppRoutes.person(holder?.id ?? '')),
            );
          }
          return _JourneyBody(journey: journey, holderId: holder.id);
        },
      ),
    );
  }
}

class _JourneyBody extends ConsumerWidget {
  const _JourneyBody({required this.journey, required this.holderId});

  final JourneyState journey;
  final String holderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final week = journey.week;
    final pregnancy = journey.stage == JourneyStage.pregnancy;
    final ancWeeks = ref.watch(
      remoteConfigProvider.select((c) => c.ancContactWeeks),
    );

    final headline = week == null
        ? null
        : pregnancy
        ? l10n.journeyPregnancyWeek(context.digits(week))
        : l10n.journeyBabyWeek(
            personName(context, journey.baby!),
            context.digits(week),
          );

    return ListView(
      padding: const EdgeInsets.all(EpSpace.gutter),
      children: [
        Container(
          key: const ValueKey('journey-headline'),
          padding: const EdgeInsets.all(EpSpace.s5),
          decoration: const BoxDecoration(
            color: EpColors.green50,
            borderRadius: EpRadius.lgAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pregnancy ? l10n.journeyPregnancy : l10n.journeyBreastfeeding,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EpSpace.s1),
              Text(
                headline ??
                    (pregnancy ? l10n.journeyAddDueDate : l10n.journeyAddBaby),
                style: theme.textTheme.titleLarge,
              ),
              if (journey.trimester != null)
                Text(
                  l10n.journeyTrimester(context.digits(journey.trimester!)),
                  style: theme.textTheme.bodyMedium,
                ),
              if (journey.dueDate != null)
                Text(
                  l10n.journeyDueDate(
                    '${formatShortDate(context, journey.dueDate!)} '
                    '${context.digits(journey.dueDate!.year)}',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              if (week == null) ...[
                const SizedBox(height: EpSpace.s3),
                FilledButton(
                  onPressed: () => context.push(
                    pregnancy
                        ? AppRoutes.person(holderId)
                        : AppRoutes.newPerson,
                  ),
                  child: Text(
                    pregnancy ? l10n.editAction : l10n.familyAddAction,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EpSpace.s5),
        if (week != null) _WeekGuidance(stage: journey.stage, week: week),
        if (pregnancy && journey.dueDate != null && ancWeeks != null) ...[
          const SizedBox(height: EpSpace.s5),
          _AncContacts(dueDate: journey.dueDate!, weeks: ancWeeks),
        ],
        const SizedBox(height: EpSpace.s5),
        Text(l10n.journeyResources, style: theme.textTheme.titleMedium),
        const SizedBox(height: EpSpace.s2),
        for (final (title, route) in journeyResources[journey.stage]!)
          Card(
            margin: const EdgeInsets.only(bottom: EpSpace.s2),
            child: ListTile(
              title: Text(title),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(route),
            ),
          ),
        const SizedBox(height: EpSpace.s3),
        Text(l10n.bmiDisclaimer, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _WeekGuidance extends ConsumerWidget {
  const _WeekGuidance({required this.stage, required this.week});

  final JourneyStage stage;
  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entry = ref.watch(journeyEntryProvider((stage, week)));
    return EpAsyncView(
      value: entry,
      onRetry: () => ref.invalidate(journeyEntryProvider((stage, week))),
      data: (e) {
        if (e == null) {
          return EpBanner(
            key: const ValueKey('journey-content-soon'),
            icon: Icons.schedule_rounded,
            message: l10n.journeyContentSoon,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: EpSpace.s2),
            ListenButton(parts: [e.title, ...e.paragraphs]),
            const SizedBox(height: EpSpace.s2),
            for (final p in e.paragraphs) ...[
              Text(p, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: EpSpace.s3),
            ],
          ],
        );
      },
    );
  }
}

class _AncContacts extends ConsumerWidget {
  const _AncContacts({required this.dueDate, required this.weeks});

  final DateTime dueDate;
  final List<int> weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final contacts = upcomingContacts(dueDate, weeks, DateTime.now());
    if (contacts.isEmpty) return const SizedBox.shrink();

    Future<void> remind() async {
      final scheduler = ref.read(reminderSchedulerProvider);
      for (final (week, date) in contacts) {
        await scheduler.schedule(
          Reminder(
            key: 'anc:$week',
            at: date.subtract(const Duration(days: 1)),
            title: l10n.journeyAncReminderTitle,
            body: l10n.journeyAncReminderBody(context.digits(week)),
            route: AppRoutes.journey,
          ),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.journeyAncReminded)));
      }
    }

    return Column(
      key: const ValueKey('journey-anc'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journeyAncTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EpSpace.s2),
        for (final (week, date) in contacts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_hospital_outlined),
            title: Text(l10n.journeyAncWeek(context.digits(week))),
            subtitle: Text(
              '${formatShortDate(context, date)} ${context.digits(date.year)}',
            ),
          ),
        OutlinedButton.icon(
          onPressed: remind,
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(l10n.journeyAncRemind),
        ),
      ],
    );
  }
}
