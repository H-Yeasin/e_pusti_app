import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/webinar_models.dart';
import '../../../notifications/presentation/engagement_providers.dart';

/// WEB-01 — upcoming first, then past events with recordings.
class WebinarListScreen extends ConsumerWidget {
  const WebinarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final webinars = ref.watch(webinarsWithSeatsProvider);
    final registered = {
      for (final r in ref.watch(registrationsProvider).value ?? const [])
        r.webinarId,
    };

    return Scaffold(
      appBar: EpAppBar(title: l10n.homeWebinar),
      body: EpAsyncView(
        value: webinars,
        onRetry: () => ref.invalidate(webinarsWithSeatsProvider),
        data: (all) {
          final now = DateTime.now();
          final upcoming = all.where((w) => !w.isPast(now)).toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          final past = all.where((w) => w.isPast(now)).toList()
            ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              if (upcoming.isEmpty)
                EpBanner(
                  key: const ValueKey('webinars-none-upcoming'),
                  icon: Icons.event_busy_outlined,
                  message: l10n.webinarNoUpcoming,
                )
              else ...[
                Text(l10n.webinarUpcoming, style: theme.textTheme.titleLarge),
                const SizedBox(height: EpSpace.s3),
                for (final w in upcoming)
                  _UpcomingCard(
                    webinar: w,
                    registered: registered.contains(w.id),
                  ),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: EpSpace.s5),
                Text(l10n.webinarPast, style: theme.textTheme.titleLarge),
                const SizedBox(height: EpSpace.s3),
                for (final w in past)
                  Card(
                    margin: const EdgeInsets.only(bottom: EpSpace.s2),
                    child: ListTile(
                      title: Text(w.title, style: theme.textTheme.titleMedium),
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
                          : Text(
                              l10n.webinarNoRecording,
                              style: theme.textTheme.bodySmall,
                            ),
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

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard({required this.webinar, required this.registered});

  final Webinar webinar;
  final bool registered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final seats = context.digits(webinar.seatsLeft);
    final seatText = registered
        ? l10n.webinarRegisteredBadge
        : webinar.isFull
        ? l10n.webinarFull
        : webinar.isAlmostFull
        ? l10n.webinarOnlySeatsLeft(seats)
        : l10n.webinarSeatsLeft(seats);
    final details = [
      formatEventDateTime(context, webinar.startsAt),
      ?webinar.speaker,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: EpSpace.s3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.webinar(webinar.id)),
        child: Padding(
          padding: const EdgeInsets.all(EpSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(webinar.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: EpSpace.s1),
              Text(details, style: theme.textTheme.bodyMedium),
              const SizedBox(height: EpSpace.s1),
              Text(
                seatText,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: registered
                      ? EpColors.green700
                      : webinar.isFull || webinar.isAlmostFull
                      ? EpColors.destructiveText
                      : EpColors.green700,
                ),
              ),
              if (!webinar.isFull && !registered) ...[
                const SizedBox(height: EpSpace.s3),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.webinar(webinar.id)),
                  child: Text(l10n.webinarReserveSeat),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
