import 'dart:convert';
import 'dart:io';

import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/platform/narrator.dart';
import 'package:epushti/features/bmi/data/who_bmi_for_age_reference.dart';
import 'package:epushti/features/bmi/domain/entities/bmi_models.dart';
import 'package:epushti/features/bmi/presentation/widgets/growth_chart.dart';
import 'package:epushti/features/journey/journey.dart';
import 'package:epushti/features/notifications/data/reminder_scheduler.dart';
import 'package:epushti/features/notifications/presentation/engagement_providers.dart';
import 'package:epushti/features/profile/domain/profile_models.dart';
import 'package:epushti/features/search/search_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

const _account = 'acc1';

Map<String, Object> _signedIn({
  List<Person> people = const [],
  List<Measurement> measurements = const [],
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
  'local_${_account}_people': jsonEncode([for (final p in people) p.toJson()]),
  if (measurements.isNotEmpty)
    'local_${_account}_measurements': jsonEncode([
      for (final m in measurements) m.toJson(),
    ]),
};

class _FakeNarrator implements Narrator {
  _FakeNarrator({required this.hasBangla});

  final bool hasBangla;
  final spoken = <String>[];

  @override
  Future<bool> prepareBangla() async => hasBangla;

  @override
  Future<void> speak(List<String> parts) async => spoken.addAll(parts);

  @override
  Future<void> stop() async {}
}

final _rima = Person(
  id: 'h1',
  relationship: Relationship.holder,
  name: 'Rima',
  dateOfBirth: DateTime(1992, 3, 12),
  sex: Sex.female,
);

void main() {
  group('unit', () {
    test('snippet shows the text around the match', () {
      const text =
          'প্রতিদিন অন্তত ৩০ মিনিট হাঁটা, পর্যাপ্ত পানি পান এবং নিয়মিত ঘুম';
      expect(snippetFor(text, 'পানি'), contains('পানি'));
      expect(snippetFor(text, 'xyz'), isNull);
      // Bangla and ASCII digits match each other.
      expect(snippetFor(text, '30'), contains('৩০'));
    });

    test('pregnancy week from the due date', () {
      final due = DateTime(2027, 3, 1);
      expect(pregnancyWeek(due, due), 41);
      expect(pregnancyWeek(due, due.subtract(const Duration(days: 280))), 1);
      expect(pregnancyWeek(due, due.subtract(const Duration(days: 112))), 25);
      expect(pregnancyWeek(due, due.add(const Duration(days: 60))), 42);
    });

    test('journey: pregnant holder, breastfeeding with youngest baby', () {
      final now = DateTime(2026, 11, 6);
      final pregnant = _rima.copyWith(
        pregnant: true,
        expectedDueDate: DateTime(2027, 3, 1),
      );
      final j = journeyFor([pregnant], now)!;
      expect(j.stage, JourneyStage.pregnancy);
      expect(j.week, 24);
      expect(j.trimester, 2);

      final nursing = _rima.copyWith(breastfeeding: true);
      final baby = Person(
        id: 'b1',
        relationship: Relationship.child,
        name: 'Nadia',
        dateOfBirth: DateTime(2026, 9, 25),
      );
      final older = Person(
        id: 'k1',
        relationship: Relationship.child,
        dateOfBirth: DateTime(2017, 4, 4),
      );
      final b = journeyFor([nursing, older, baby], now)!;
      expect(b.stage, JourneyStage.breastfeeding);
      expect(b.baby!.id, 'b1');
      expect(b.week, 6);

      expect(journeyFor([_rima], now), isNull);
    });

    test('antenatal contacts: only upcoming ones, input not mutated', () {
      final weeks = [36, 12, 20, 26];
      final contacts = upcomingContacts(
        DateTime(2027, 3, 1),
        weeks,
        DateTime(2026, 11, 6), // week 24
      );
      expect(contacts.map((c) => c.$1), [26, 36]);
      expect(weeks, [36, 12, 20, 26]);
    });

    test('growth chart curves match the WHO table', () {
      final table = WhoBmiForAgeReference.parse(
        File(WhoBmiForAgeReference.assetPath).readAsStringSync(),
      );
      final lms = table.lookup(Sex.male, 61)!;
      // Published WHO values for boys, 61 months.
      expect(bmiAtZ(lms, 0), closeTo(15.264, 0.001));
      expect(bmiAtZ(lms, 2), closeTo(18.259, 0.001));
      expect(bmiAtZ(lms, -2), closeTo(13.031, 0.001));
    });

    test('due date survives a JSON round trip', () {
      final p = _rima.copyWith(
        pregnant: true,
        expectedDueDate: DateTime(2027, 3, 1),
      );
      expect(Person.fromJson(p.toJson()).expectedDueDate, DateTime(2027, 3, 1));
      expect(p.copyWith(clearDueDate: true).expectedDueDate, isNull);
    });
  });

  group('search and saved', () {
    testWidgets('search finds chapter text, documents and webinars', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey('home-search')));
      expect(find.text('What are you looking for?'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('global-search')),
        'পানি',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);
      // Chapter 3 text ("পর্যাপ্ত পানি") and the "নিরাপদ পানি সংরক্ষণ" poster.
      expect(find.text('স্বাস্থ্যসম্মত জীবনধারা'), findsOneWidget);
      expect(find.text('নিরাপদ পানি সংরক্ষণ'), findsOneWidget);

      await tapAndSettle(tester, find.text('নিরাপদ পানি সংরক্ষণ'));
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('no results offers the library and courses', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/search');
      await tester.enterText(
        find.byKey(const ValueKey('global-search')),
        'zzzz',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);

      expect(find.byKey(const ValueKey('search-empty')), findsOneWidget);
    });

    testWidgets('bookmark a document, find it in Saved, remove it', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/library/doc/d1');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('bookmark-document-d1')),
      );
      expect(find.text('Added to saved'), findsOneWidget);

      await pushRoute(tester, '/saved');
      expect(find.text('সুষম খাদ্য পিরামিড'), findsOneWidget);
      await tester.drag(find.text('সুষম খাদ্য পিরামিড'), const Offset(-500, 0));
      await settle(tester);
      expect(find.byKey(const ValueKey('saved-empty')), findsOneWidget);
    });
  });

  group('listen (audio narration)', () {
    testWidgets('reads the chapter aloud with a Bangla voice', (tester) async {
      final narrator = _FakeNarrator(hasBangla: true);
      await pumpAppAtHome(
        tester,
        overrides: [narratorProvider.overrideWithValue(narrator)],
      );
      await pushRoute(tester, '/courses/c3');
      await tapAndSettle(tester, find.byKey(const ValueKey('listen-button')));

      expect(narrator.spoken.first, 'স্বাস্থ্যসম্মত জীবনধারা');
      expect(narrator.spoken, hasLength(4));
    });

    testWidgets('says so when the phone has no Bangla voice', (tester) async {
      await pumpAppAtHome(
        tester,
        overrides: [
          narratorProvider.overrideWithValue(_FakeNarrator(hasBangla: false)),
        ],
      );
      await pushRoute(tester, '/courses/c3');
      await tapAndSettle(tester, find.byKey(const ValueKey('listen-button')));

      expect(find.byKey(const ValueKey('listen-unavailable')), findsOneWidget);
    });
  });

  group('growth chart and journey', () {
    testWidgets('child history shows the WHO growth chart', (tester) async {
      final arif = Person(
        id: 'k1',
        relationship: Relationship.child,
        name: 'Arif',
        dateOfBirth: DateTime(2017, 4, 4),
        sex: Sex.male,
      );
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          people: [_rima, arif],
          measurements: [
            Measurement(
              id: 'm1',
              personId: 'k1',
              measuredAt: DateTime(2025, 11, 18),
              heightCm: 127,
              weightKg: 25.4,
            ),
            Measurement(
              id: 'm2',
              personId: 'k1',
              measuredAt: DateTime(2026, 8, 29),
              heightCm: 132,
              weightKg: 27.5,
            ),
          ],
        ),
      );
      await pushRoute(tester, '/bmi/history?p=k1');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('growth-chart')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.byKey(const ValueKey('growth-chart')), findsOneWidget);
      expect(find.text('Growth chart coming soon'), findsNothing);
    });

    testWidgets('pregnant holder: journey week and "For you" row', (
      tester,
    ) async {
      final due = DateTime.now().add(const Duration(days: 112));
      await pumpAppAtHome(
        tester,
        config: AppRemoteConfig.fromJson({
          'ancContactWeeks': [12, 20, 26, 30, 34, 36, 38, 40],
        }),
        storedValues: _signedIn(
          people: [_rima.copyWith(pregnant: true, expectedDueDate: due)],
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('for-you-journey')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Pregnancy · Week 25'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const ValueKey('for-you-journey')));
      expect(find.text('Week 25'), findsOneWidget);
      expect(find.text('Trimester 2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('journey-content-soon')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('journey-anc')), findsOneWidget);
    });

    testWidgets('antenatal reminders are scheduled the day before', (
      tester,
    ) async {
      final scheduler = RecordingReminderScheduler();
      final due = DateTime.now().add(const Duration(days: 112));
      await pumpAppAtHome(
        tester,
        config: AppRemoteConfig.fromJson({
          'ancContactWeeks': [26, 30],
        }),
        storedValues: _signedIn(
          people: [_rima.copyWith(pregnant: true, expectedDueDate: due)],
        ),
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      await pushRoute(tester, '/journey');
      await tester.scrollUntilVisible(
        find.text('Remind me before check-ups'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tapAndSettle(tester, find.text('Remind me before check-ups'));

      expect(scheduler.scheduled.keys, containsAll(['anc:26', 'anc:30']));
    });

    testWidgets('no ANC section until the schedule is configured', (
      tester,
    ) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          people: [
            _rima.copyWith(
              pregnant: true,
              expectedDueDate: DateTime.now().add(const Duration(days: 112)),
            ),
          ],
        ),
      );
      await pushRoute(tester, '/journey');

      expect(find.byKey(const ValueKey('journey-anc')), findsNothing);
    });

    testWidgets('not pregnant or breastfeeding: journey explains itself', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_rima]));
      await pushRoute(tester, '/journey');

      expect(find.byKey(const ValueKey('journey-none')), findsOneWidget);
    });
  });
}
