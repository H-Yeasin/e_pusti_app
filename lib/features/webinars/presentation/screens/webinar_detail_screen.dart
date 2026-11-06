import 'package:flutter/material.dart';
import '../../../search/search_index.dart';
import '../../../bookmarks/bookmarks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../notifications/presentation/engagement_providers.dart';
import '../../../share/share_actions.dart';
import '../../domain/webinar_models.dart';
import '../webinar_actions.dart';

/// WEB-02 — open with seats, registered, full (offers the recording), or
/// "lost the last seat": full is known before the tap, the race happens
/// during it.
class WebinarDetailScreen extends ConsumerStatefulWidget {
  const WebinarDetailScreen({super.key, required this.webinarId});

  final String webinarId;

  @override
  ConsumerState<WebinarDetailScreen> createState() =>
      _WebinarDetailScreenState();
}

class _WebinarDetailScreenState extends ConsumerState<WebinarDetailScreen> {
  bool _lostSeat = false;
  bool _busy = false;

  Future<void> _register(Webinar w) async {
    if (!ensureLoggedInForWebinar(context, ref, w.id)) return;
    setState(() => _busy = true);
    try {
      final outcome = await registerForWebinar(context, ref, w);
      // Seats were shown when the user tapped; "full" now means the race
      // was lost.
      if (outcome == RegisterOutcome.full && mounted) {
        setState(() => _lostSeat = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _alert(Webinar w) async {
    if (!ensureLoggedInForWebinar(context, ref, w.id)) return;
    await requestRecordingAlert(ref, w.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final webinar = ref.watch(webinarWithSeatsProvider(widget.webinarId));
    final registrations = ref.watch(registrationsProvider).value ?? const [];
    final alerts = ref.watch(recordingAlertsProvider).value ?? const <String>{};

    return Scaffold(
      appBar: EpAppBar(
        title: l10n.homeWebinar,
        actions: [
          if (webinar.value case final w?)
            BookmarkButton(
              kind: SearchKind.webinar,
              id: w.id,
              title: w.title,
              route: AppRoutes.webinar(w.id),
            ),
          if (webinar.value case final w?)
            IconButton(
              tooltip: l10n.shareAction,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareInAppLink(
                context,
                ref,
                title: w.title,
                route: AppRoutes.webinar(w.id),
              ),
            ),
        ],
      ),
      body: EpAsyncView(
        value: webinar,
        onRetry: () => ref.invalidate(webinarsWithSeatsProvider),
        data: (w) {
          final theme = Theme.of(context);
          final now = DateTime.now();
          final past = w.isPast(now);
          final registered = registrations.any((r) => r.webinarId == w.id);
          final alertOn = alerts.contains(w.id);
          final showFull = !past && !registered && (w.isFull || _lostSeat);

          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(w.title, style: theme.textTheme.titleLarge),
                  ),
                  if (registered && !past)
                    _Pill(l10n.webinarRegisteredBadge, brand: true)
                  else if (showFull)
                    _Pill(l10n.webinarFull),
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
              if (!past && !showFull)
                _InfoRow(
                  icon: Icons.event_seat_outlined,
                  text: l10n.webinarSeatsOfTotal(
                    context.digits(w.seatsLeft),
                    context.digits(w.capacity),
                  ),
                ),
              const SizedBox(height: EpSpace.s6),
              if (past)
                ..._pastActions(context, w)
              else if (registered)
                ..._registeredActions(context, w, now)
              else if (showFull) ...[
                EpBanner(
                  key: ValueKey(
                    _lostSeat ? 'webinar-lost-seat' : 'webinar-full',
                  ),
                  icon: Icons.info_outline_rounded,
                  tone: _lostSeat
                      ? EpBannerTone.destructive
                      : EpBannerTone.info,
                  message: _lostSeat
                      ? '${l10n.webinarLostSeatTitle}\n${l10n.webinarLostSeatBody}'
                      : l10n.webinarFullBody,
                ),
                const SizedBox(height: EpSpace.s4),
                if (alertOn)
                  EpBanner(
                    key: const ValueKey('recording-alert-on'),
                    tone: EpBannerTone.brand,
                    icon: Icons.notifications_active_outlined,
                    message: l10n.webinarAlertOn,
                  )
                else
                  FilledButton(
                    onPressed: () => _alert(w),
                    child: Text(l10n.webinarNotifyRecording),
                  ),
                const SizedBox(height: EpSpace.s2),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.webinars),
                  child: Text(l10n.webinarSeeOthers),
                ),
              ] else
                FilledButton(
                  key: const ValueKey('webinar-register'),
                  onPressed: _busy ? null : () => _register(w),
                  child: Text(l10n.webinarReserveSeat),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _registeredActions(
    BuildContext context,
    Webinar w,
    DateTime now,
  ) {
    final l10n = context.l10n;
    final link = ref.watch(joinLinkProvider(w.id)).value;
    return [
      if (link != null && w.isJoinable(now))
        FilledButton.icon(
          key: const ValueKey('webinar-join'),
          onPressed: () => Launcher.web(context, link),
          icon: const Icon(Icons.videocam_outlined),
          label: Text(l10n.webinarJoin),
        )
      else
        EpBanner(
          key: const ValueKey('webinar-registered'),
          tone: EpBannerTone.brand,
          icon: Icons.event_available_outlined,
          message: '${l10n.webinarYoureIn}\n${l10n.webinarYoureInBody}',
        ),
      const SizedBox(height: EpSpace.s3),
      OutlinedButton.icon(
        onPressed: () => addToCalendar(w),
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(l10n.webinarAddToCalendar),
      ),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: EpColors.destructiveFill),
        onPressed: () => cancelRegistration(context, ref, w),
        child: Text(l10n.webinarCancelRegistration),
      ),
    ];
  }

  List<Widget> _pastActions(BuildContext context, Webinar w) {
    final l10n = context.l10n;
    final url = w.recordingUrl;
    if (!w.hasRecording) return [Text(l10n.webinarNoRecording)];
    if (url == null) {
      return [
        EpBanner(
          icon: Icons.schedule_rounded,
          message: l10n.webinarRecordingNotYet,
        ),
      ];
    }
    return [
      FilledButton.icon(
        onPressed: () => Launcher.web(context, url),
        icon: const Icon(Icons.play_circle_outline_rounded),
        label: Text(l10n.webinarWatchRecording),
      ),
    ];
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.brand = false});

  final String label;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: brand ? EpColors.green50 : EpColors.destructiveTint,
        borderRadius: const BorderRadius.all(Radius.circular(EpRadius.pill)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: EpTextSize.caption,
          color: brand ? EpColors.green800 : EpColors.destructiveStrong,
        ),
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
