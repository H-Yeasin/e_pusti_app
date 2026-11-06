import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../../notifications/presentation/engagement_providers.dart';
import '../domain/webinar_models.dart';

/// Logged out: ask to log in at this moment and return to the webinar.
bool ensureLoggedInForWebinar(
  BuildContext context,
  WidgetRef ref,
  String webinarId,
) {
  if (ref.read(authControllerProvider).isLoggedIn) return true;
  showLoginPrompt(
    context,
    returnTo: AppRoutes.webinar(webinarId),
    body: context.l10n.webinarRegisterLoginBody,
  );
  return false;
}

void _refresh(WidgetRef ref, String webinarId) {
  ref.invalidate(registrationsProvider);
  ref.invalidate(webinarsWithSeatsProvider);
  ref.invalidate(joinLinkProvider(webinarId));
  ref.invalidate(inboxProvider);
}

/// Reserves a seat; capacity is checked by the backend in a transaction.
Future<RegisterOutcome?> registerForWebinar(
  BuildContext context,
  WidgetRef ref,
  Webinar webinar,
) async {
  final backend = ref.read(engagementBackendProvider);
  if (backend == null) return null;
  final l10n = context.l10n;
  final outcome = await backend.$1.register(webinar.id);
  _refresh(ref, webinar.id);
  if (outcome == RegisterOutcome.registered) {
    await ref
        .read(reminderPlannerProvider)
        .planWebinar(
          webinar,
          title24h: l10n.reminderWebinar24h,
          title15m: l10n.reminderWebinar15m,
        );
  }
  return outcome;
}

Future<bool> cancelRegistration(
  BuildContext context,
  WidgetRef ref,
  Webinar webinar,
) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.webinarCancelConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.webinarKeepAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.webinarCancelRegistration),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(engagementBackendProvider)?.$1.cancel(webinar.id);
  await ref.read(reminderPlannerProvider).cancelWebinar(webinar.id);
  _refresh(ref, webinar.id);
  return true;
}

Future<void> requestRecordingAlert(WidgetRef ref, String webinarId) async {
  await ref
      .read(engagementBackendProvider)
      ?.$1
      .requestRecordingAlert(webinarId);
  ref.invalidate(recordingAlertsProvider);
}

/// iCalendar event, shared as a file so the phone's calendar app opens it.
String webinarIcs(Webinar w, {DateTime? now}) {
  String stamp(DateTime d) {
    final u = d.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}T'
        '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  String esc(String v) => v
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//BIID Foundation//e-Pushti//EN',
    'BEGIN:VEVENT',
    'UID:${w.id}@epushti',
    'DTSTAMP:${stamp(now ?? DateTime.now())}',
    'DTSTART:${stamp(w.startsAt)}',
    'DTEND:${stamp(w.endsAt)}',
    'SUMMARY:${esc(w.title)}',
    if (w.description != null) 'DESCRIPTION:${esc(w.description!)}',
    'BEGIN:VALARM',
    'TRIGGER:-PT15M',
    'ACTION:DISPLAY',
    'DESCRIPTION:${esc(w.title)}',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
}

Future<void> addToCalendar(Webinar w) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/webinar-${w.id}.ics');
  await file.writeAsString(webinarIcs(w));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/calendar')],
      title: w.title,
    ),
  );
}
