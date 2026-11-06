import 'dart:convert';

import 'package:epushti/app/router/app_router.dart';
import 'package:epushti/core/analytics/slot_events.dart';
import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/features/assessment/domain/learning_models.dart';
import 'package:epushti/features/notifications/data/local_engagement_backend.dart';
import 'package:epushti/features/notifications/data/reminder_scheduler.dart';
import 'package:epushti/features/notifications/presentation/engagement_providers.dart';
import 'package:epushti/features/profile/domain/profile_models.dart';
import 'package:epushti/features/share/share_actions.dart';
import 'package:epushti/features/webinars/data/fixture_webinar_repository.dart';
import 'package:epushti/features/webinars/domain/webinar_models.dart';
import 'package:epushti/features/webinars/presentation/webinar_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

const _account = 'acc1';

Map<String, Object> _signedIn({
  List<ItemProgress> progress = const [],
  List<Map<String, Object?>> measurements = const [],
}) => {
  'local_backend_session': jsonEncode({
    'id': _account,
    'phone': '+8801812345678',
  }),
  'local_backend_accounts': jsonEncode({_account: '+8801812345678'}),
  'local_${_account}_consent': jsonEncode({
    'terms': '2026-11-01T10:00:00.000',
    'health': '2026-11-01T10:00:00.000',
  }),
  'local_${_account}_people': jsonEncode([
    {
      'id': 'h1',
      'relationship': 'holder',
      'name': 'Rima',
      'date_of_birth': '1992-03-12',
      'sex': 'female',
    },
  ]),
  if (progress.isNotEmpty)
    'local_${_account}_progress': jsonEncode([
      for (final p in progress) p.toJson(),
    ]),
  if (measurements.isNotEmpty)
    'local_${_account}_measurements': jsonEncode(measurements),
};

class _RecordingSink implements SlotEventSink {
  final events = <(String, SlotEventKind)>[];

  @override
  Future<void> record(
    String slotId,
    SlotEventKind kind, {
    String? creative,
  }) async => events.add((slotId, kind));
}

void main() {
  group('unit', () {
    test('calendar file has UTC times, escaping and a 15-minute alarm', () {
      final w = Webinar(
        id: 'w1',
        title: 'Food, safety; home',
        startsAt: DateTime.utc(2026, 9, 12, 4),
        durationMinutes: 60,
        capacity: 50,
        seatsLeft: 8,
      );
      final ics = webinarIcs(w, now: DateTime.utc(2026, 9, 1));
      expect(ics, contains('DTSTART:20260912T040000Z'));
      expect(ics, contains('DTEND:20260912T050000Z'));
      expect(ics, contains(r'SUMMARY:Food\, safety\; home'));
      expect(ics, contains('TRIGGER:-PT15M'));
    });

    test('reminder ids are stable and positive', () {
      expect(reminderId('webinar:w1:24h'), reminderId('webinar:w1:24h'));
      expect(reminderId('webinar:w1:24h'), isNot(reminderId('webinar:w1:15m')));
      expect(reminderId('measure:k1'), greaterThanOrEqualTo(0));
    });

    test('epushti:// links open the matching screen', () {
      String? go(String uri) => resolveRedirect(
        location: Uri.parse(uri),
        isLoggedIn: false,
        isDev: false,
      );
      expect(go('epushti://webinars/w1'), '/webinars/w1');
      expect(go('epushti://library/doc/d1'), '/library/doc/d1');
      expect(go('epushti://bmi?p=k1'), '/bmi?p=k1');
      expect(go('epushti://'), '/home');
    });

    test('share links use the web base once configured', () {
      expect(
        shareLinkFor(AppRemoteConfig.defaults, '/webinars/w1'),
        'epushti://webinars/w1',
      );
      expect(
        shareLinkFor(
          AppRemoteConfig.fromJson({'shareBaseUrl': 'https://e.example/'}),
          '/webinars/w1',
        ),
        'https://e.example/webinars/w1',
      );
    });

    test('measurement reminder intervals by age', () {
      const d = MeasurementReminderDays.defaults;
      expect(d.forAgeMonths(30), 30);
      expect(d.forAgeMonths(112), 90);
      expect(d.forAgeMonths(400), 180);
      expect(d.forAgeMonths(null), 180);
    });

    test('dev backend enforces capacity and writes the inbox', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final catalogue = FixtureWebinarRepository();
      LocalEngagementBackend backend(String id) =>
          LocalEngagementBackend(prefs, id, catalogue: catalogue.fetchWebinars);
      final webinars = await catalogue.fetchWebinars();
      final w1 = webinars.firstWhere((w) => w.id == 'w1'); // 8 seats

      for (var i = 0; i < 8; i++) {
        expect(await backend('u$i').register('w1'), RegisterOutcome.registered);
      }
      expect(await backend('late').register('w1'), RegisterOutcome.full);
      expect((await backend('u0').seatsLeft([w1]))['w1'], 0);

      await backend('u0').cancel('w1');
      expect((await backend('u0').seatsLeft([w1]))['w1'], 1);
      expect(await backend('late').register('w1'), RegisterOutcome.registered);

      final inbox = await backend('late').list();
      expect(inbox.single.route, '/webinars/w1');
      expect(inbox.single.isRead, isFalse);
      await backend('late').markAllRead();
      expect((await backend('late').list()).single.isRead, isTrue);

      // A week before the event there is no join link yet.
      expect(await backend('late').joinLink('w1'), isNull);
    });
  });

  group('webinars (WEB-02 / WEB-03)', () {
    testWidgets('register: reminders, inbox item, badge, registered state', (
      tester,
    ) async {
      final scheduler = RecordingReminderScheduler();
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(),
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/webinars/w1');
      expect(find.text('8 seats left · 50 total'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );

      expect(find.byKey(const ValueKey('webinar-registered')), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(
        scheduler.scheduled.keys,
        containsAll(['webinar:w1:24h', 'webinar:w1:15m']),
      );

      await pushRoute(tester, '/home');
      await tapAndSettle(tester, find.byIcon(Icons.menu_rounded));
      expect(find.byKey(const ValueKey('sidebar-unread')), findsOneWidget);
      await tapAndSettle(tester, find.text('Notifications'));
      expect(find.textContaining('রেজিস্ট্রেশন সম্পন্ন'), findsOneWidget);
      await tapAndSettle(tester, find.textContaining('রেজিস্ট্রেশন সম্পন্ন'));
      expect(find.byKey(const ValueKey('webinar-registered')), findsOneWidget);
    });

    testWidgets('losing the last seat during the tap is its own state', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/webinars/w1');
      expect(find.byKey(const ValueKey('webinar-register')), findsOneWidget);

      // Someone else takes every seat after the screen loaded.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LocalEngagementBackend.seatsTakenKey,
        jsonEncode({'w1': 8}),
      );
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );

      expect(find.byKey(const ValueKey('webinar-lost-seat')), findsOneWidget);
      expect(
        find.textContaining('the last seat was just taken'),
        findsOneWidget,
      );
    });

    testWidgets('full session: ask to hear about the recording', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/webinars/w2');
      expect(find.byKey(const ValueKey('webinar-full')), findsOneWidget);
      await tapAndSettle(tester, find.text('Tell me about the recording'));

      expect(find.byKey(const ValueKey('recording-alert-on')), findsOneWidget);
    });

    testWidgets('cancel after confirming frees the seat', (tester) async {
      final scheduler = RecordingReminderScheduler();
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(),
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/webinars/w1');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );
      await tapAndSettle(tester, find.text('Cancel registration'));
      await tapAndSettle(tester, find.text('Cancel registration').last);

      expect(find.text('8 seats left · 50 total'), findsOneWidget);
      expect(scheduler.scheduled, isEmpty);
    });

    testWidgets('my registrations: empty, then listed', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/registrations');
      expect(find.byKey(const ValueKey('registrations-empty')), findsOneWidget);

      await pushRoute(tester, '/webinars/w1');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );
      await pushRoute(tester, '/registrations');
      expect(find.text('National Nutrition Week'), findsOneWidget);
      expect(find.text('Link shown before the event'), findsOneWidget);
    });

    testWidgets('logged out: reserving asks to log in', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/webinars/w1');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );

      expect(find.textContaining('Log in to reserve a seat'), findsOneWidget);
    });
  });

  group('notifications (NOT-01 / NOT-02)', () {
    testWidgets('empty inbox', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/notifications');

      expect(find.byKey(const ValueKey('inbox-empty')), findsOneWidget);
    });

    testWidgets('permission trap is explained and opens phone settings', (
      tester,
    ) async {
      final scheduler = RecordingReminderScheduler(permitted: false);
      await pumpAppAtHome(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/settings/notifications');

      expect(find.byKey(const ValueKey('permission-denied')), findsOneWidget);
      await tapAndSettle(tester, find.text('Open phone settings'));
      expect(scheduler.openedSettings, isTrue);
    });

    testWidgets('turning webinars off stops webinar reminders', (tester) async {
      final scheduler = RecordingReminderScheduler();
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(),
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/settings/notifications');
      expect(find.byKey(const ValueKey('permission-denied')), findsNothing);
      await tapAndSettle(tester, find.byKey(const ValueKey('pref-webinar')));

      await pushRoute(tester, '/webinars/w1');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('webinar-register')),
      );
      expect(scheduler.scheduled, isEmpty);
    });

    testWidgets('saving a measurement schedules the next reminder', (
      tester,
    ) async {
      final scheduler = RecordingReminderScheduler();
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(),
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/bmi/result?h=163&w=57&a=414&s=female&p=h1');
      await tapAndSettle(tester, find.text('Save'));

      final reminder = scheduler.scheduled['measure:h1']!;
      expect(reminder.route, '/bmi?p=h1');
      final days = reminder.at.difference(DateTime.now()).inDays;
      expect(days, inInclusiveRange(178, 180));
    });

    testWidgets('tapping a shown reminder opens its screen', (tester) async {
      final scheduler = RecordingReminderScheduler();
      await pumpAppAtHome(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      scheduler.simulateTap('/webinars/w1');
      await settle(tester);

      expect(find.text('National Nutrition Week'), findsOneWidget);
    });
  });

  group('home, PUST9 and partner slots', () {
    testWidgets(
      '"For you" shows continue, next webinar and a due measurement',
      (tester) async {
        final old = DateTime.now().subtract(const Duration(days: 200));
        await pumpAppAtHome(
          tester,
          storedValues: _signedIn(
            progress: const [
              ItemProgress(
                type: LearningItemType.chapter,
                itemId: 'c3',
                status: ProgressStatus.inProgress,
              ),
            ],
            measurements: [
              Measurement(
                id: 'm1',
                personId: 'h1',
                measuredAt: old,
                heightCm: 163,
                weightKg: 57,
              ).toJson(),
            ],
          ),
        );
        await pushRoute(tester, '/webinars/w1');
        await tapAndSettle(
          tester,
          find.byKey(const ValueKey('webinar-register')),
        );
        await pushRoute(tester, '/home');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('for-you')),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byKey(const ValueKey('for-you-continue')), findsOneWidget);
        expect(find.text('স্বাস্থ্যসম্মত জীবনধারা'), findsOneWidget);
        expect(find.byKey(const ValueKey('for-you-webinar')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('for-you-measure-h1')),
          findsOneWidget,
        );
      },
    );

    testWidgets('logged out home has no "For you" card', (tester) async {
      await pumpAppAtHome(tester);

      expect(find.byKey(const ValueKey('for-you')), findsNothing);
    });

    testWidgets('PUST9: status note, tips archive, stop when configured', (
      tester,
    ) async {
      await pumpAppAtHome(
        tester,
        config: AppRemoteConfig.fromJson({
          'pust9': {'stopShortcode': '21213', 'stopKeyword': 'STOP PUST9'},
        }),
      );
      await pushRoute(tester, '/pust9');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pust9-stop')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Send STOP PUST9 to 21213'), findsOneWidget);
      expect(find.byKey(const ValueKey('pust9-status-note')), findsOneWidget);

      await tapAndSettle(tester, find.text('See earlier tips'));
      expect(find.byKey(const ValueKey('pust9-archive-empty')), findsOneWidget);
    });

    testWidgets('stop instructions stay hidden until confirmed', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/pust9');

      expect(find.byKey(const ValueKey('pust9-stop')), findsNothing);
    });

    testWidgets('confirmed partner creative records one impression', (
      tester,
    ) async {
      final sink = _RecordingSink();
      await pumpAppAtHome(
        tester,
        config: AppRemoteConfig.fromJson({
          'slots': {
            'home_banner': {
              'type': 'partner',
              'imageUrl': 'https://cdn.example/creative-a.png',
              'clickUrl': 'https://partner.example',
              'confirmedPartner': true,
            },
          },
        }),
        overrides: [slotEventSinkProvider.overrideWithValue(sink)],
      );

      expect(sink.events, [('home_banner', SlotEventKind.impression)]);
    });
  });
}
