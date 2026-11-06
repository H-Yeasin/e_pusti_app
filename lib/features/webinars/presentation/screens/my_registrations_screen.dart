import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../notifications/presentation/engagement_providers.dart';
import '../../domain/webinar_models.dart';
import '../webinar_actions.dart';

/// WEB-03 — upcoming registrations (calendar, link timing, cancel) and past
/// ones (recording).
class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final registrations = ref.watch(registrationsProvider);
    final webinars = ref.watch(webinarsWithSeatsProvider);

    final combined = switch ((registrations, webinars)) {
      (AsyncData(value: final r), AsyncData(value: final w)) => AsyncData((
        r,
        w,
      )),
      (AsyncError(:final error, :final stackTrace), _) ||
      (
        _,
        AsyncError(:final error, :final stackTrace),
      ) => AsyncError<(List<WebinarRegistration>, List<Webinar>)>(
        error,
        stackTrace,
      ),
      _ => const AsyncLoading<(List<WebinarRegistration>, List<Webinar>)>(),
    };

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuRegistrations),
      body: EpAsyncView(
        value: combined,
        onRetry: () {
          ref.invalidate(registrationsProvider);
          ref.invalidate(webinarsWithSeatsProvider);
        },
        data: (data) {
          final (regs, all) = data;
          final mine = [
            for (final r in regs)
              ?all.where((w) => w.id == r.webinarId).firstOrNull,
          ];
          if (mine.isEmpty) {
            return EpStateView(
              key: const ValueKey('registrations-empty'),
              icon: Icons.event_note_outlined,
              title: l10n.registrationsEmptyTitle,
              body: l10n.registrationsEmptyBody,
              primaryLabel: l10n.seeWebinarsAction,
              onPrimary: () => context.push(AppRoutes.webinars),
            );
          }
          final now = DateTime.now();
          final upcoming = mine.where((w) => !w.isPast(now)).toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          final past = mine.where((w) => w.isPast(now)).toList()
            ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              if (upcoming.isNotEmpty) ...[
                Text(l10n.webinarUpcoming, style: theme.textTheme.titleLarge),
                const SizedBox(height: EpSpace.s2),
                for (final w in upcoming)
                  Card(
                    margin: const EdgeInsets.only(bottom: EpSpace.s3),
                    child: Padding(
                      padding: const EdgeInsets.all(EpSpace.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => context.push(AppRoutes.webinar(w.id)),
                            child: Text(
                              w.title,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: EpSpace.s1),
                          Text(
                            '${formatEventDateTime(context, w.startsAt)} · '
                            '${l10n.webinarRegisteredBadge}',
                          ),
                          const SizedBox(height: EpSpace.s1),
                          Text(
                            l10n.webinarLinkBeforeEvent,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: EpSpace.s2),
                          Wrap(
                            spacing: EpSpace.s2,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => addToCalendar(w),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: Text(l10n.webinarAddToCalendar),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: EpColors.destructiveFill,
                                ),
                                onPressed: () =>
                                    cancelRegistration(context, ref, w),
                                child: Text(l10n.cancelAction),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: EpSpace.s4),
                Text(l10n.registrationsPast, style: theme.textTheme.titleLarge),
                const SizedBox(height: EpSpace.s2),
                for (final w in past)
                  Card(
                    margin: const EdgeInsets.only(bottom: EpSpace.s2),
                    child: ListTile(
                      title: Text(w.title),
                      subtitle: Text(
                        '${formatShortDate(context, w.startsAt)} · '
                        '${l10n.webinarCompleted}',
                      ),
                      trailing: w.hasRecording
                          ? TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.webinar(w.id)),
                              child: Text(l10n.webinarWatchRecording),
                            )
                          : null,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
