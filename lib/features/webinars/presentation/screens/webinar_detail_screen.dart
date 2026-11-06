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
import '../webinar_actions.dart';
import '../webinar_providers.dart';

/// WEB-02 — open with seats, or full (offers the recording). The
/// "lost the last seat" race state arrives with registration in Phase 4.
class WebinarDetailScreen extends ConsumerWidget {
  const WebinarDetailScreen({super.key, required this.webinarId});

  final String webinarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final webinar = ref.watch(webinarProvider(webinarId));

    return Scaffold(
      appBar: EpAppBar(title: l10n.homeWebinar),
      body: EpAsyncView(
        value: webinar,
        onRetry: () => ref.invalidate(webinarProvider(webinarId)),
        data: (w) {
          final theme = Theme.of(context);
          final past = w.isPast(DateTime.now());
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(w.title, style: theme.textTheme.titleLarge),
                  ),
                  if (w.isFull && !past)
                    Chip(
                      label: Text(l10n.webinarFull),
                      backgroundColor: EpColors.destructiveTint,
                      labelStyle: const TextStyle(
                        color: EpColors.destructiveStrong,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
              if (w.description != null) ...[
                const SizedBox(height: EpSpace.s2),
                Text(w.description!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: EpSpace.s4),
              _InfoRow(
                icon: Icons.event_outlined,
                text: formatEventDateTime(context, w.startsAt),
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                text: l10n.webinarMinutes(context.digits(w.durationMinutes)),
              ),
              if (w.speaker != null)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: [w.speaker!, ?w.speakerRole].join(' · '),
                ),
              if (!past && !w.isFull)
                _InfoRow(
                  icon: Icons.event_seat_outlined,
                  text: l10n.webinarSeatsOfTotal(
                    context.digits(w.seatsLeft),
                    context.digits(w.capacity),
                  ),
                ),
              const SizedBox(height: EpSpace.s6),
              if (past) ...[
                if (w.hasRecording)
                  FilledButton(
                    onPressed: () => requireLoginForWebinar(context, ref, w.id),
                    child: Text(l10n.webinarWatchRecording),
                  )
                else
                  Text(l10n.webinarNoRecording),
              ] else if (w.isFull) ...[
                EpBanner(
                  key: const ValueKey('webinar-full'),
                  icon: Icons.info_outline_rounded,
                  message: l10n.webinarFullBody,
                ),
                const SizedBox(height: EpSpace.s4),
                FilledButton(
                  onPressed: () => requireLoginForWebinar(context, ref, w.id),
                  child: Text(l10n.webinarNotifyRecording),
                ),
                const SizedBox(height: EpSpace.s2),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.webinars),
                  child: Text(l10n.webinarSeeOthers),
                ),
              ] else
                FilledButton(
                  onPressed: () => requireLoginForWebinar(context, ref, w.id),
                  child: Text(l10n.webinarReserveSeat),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EpSpace.s2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: EpColors.textSecondary),
          const SizedBox(width: EpSpace.s2),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
