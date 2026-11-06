import 'dart:convert';

import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/errors/app_failure.dart';
import 'package:epushti/features/assessment/data/fixture_assessments.dart';
import 'package:epushti/features/assessment/data/local_learning_backend.dart';
import 'package:epushti/features/assessment/domain/learning_models.dart';
import 'package:epushti/features/assessment/presentation/learning_providers.dart';
import 'package:epushti/features/auth/presentation/providers/auth_controller.dart';
import 'package:epushti/features/certificates/domain/certificate_models.dart';
import 'package:epushti/features/digiskills/data/fixture_module_repository.dart';
import 'package:epushti/features/digiskills/domain/module_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

const _account = 'acc1';

Map<String, Object> _signedIn({
  String? holderName = 'Rima Akter',
  List<ItemProgress> progress = const [],
  List<Map<String, Object?>> certificates = const [],
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
    {'id': 'h1', 'relationship': 'holder', 'name': holderName},
  ]),
  if (progress.isNotEmpty)
    'local_${_account}_progress': jsonEncode([
      for (final p in progress) p.toJson(),
    ]),
  if (certificates.isNotEmpty)
    LocalLearningBackend.certificateRegistryKey: jsonEncode(certificates),
};

/// Correct answers for a fixture assessment, read from the dev key.
Map<String, int> _correct(String assessmentId) => {
  for (final e in fixtureAssessments[assessmentId]!.keys.entries)
    e.key: e.value.correctIndex,
};

Future<void> _answerAll(WidgetTester tester, List<int> picks) async {
  for (final pick in picks) {
    final options = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(InkWell),
    );
    await tapAndSettle(tester, options.at(pick));
    await tapAndSettle(tester, find.byKey(const ValueKey('assessment-next')));
  }
}

class _DownModules implements ModuleRepository {
  @override
  Future<List<SkillModuleSummary>> fetchModules() async =>
      throw const ContentServerUnavailableFailure();

  @override
  Future<SkillModule> fetchModule(String id) async =>
      throw const ContentServerUnavailableFailure();
}

void main() {
  group('grading (dev backend mirrors submit_assessment)', () {
    late LocalLearningBackend backend;
    var now = DateTime(2026, 11, 6, 10);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 11, 6, 10);
      backend = LocalLearningBackend(
        await SharedPreferences.getInstance(),
        _account,
        clock: () => now,
      );
    });

    test('passing issues one certificate and completes the module', () async {
      final result = await backend.submit(
        'a-m1',
        _correct('a-m1'),
        holderName: 'Rima Akter',
      );
      expect(result.passed, isTrue);
      expect(result.percent, 100);
      expect(result.certificateCode, matches(RegExp(r'^EP-2026-[2-9A-Z]{8}$')));

      final again = await backend.submit(
        'a-m1',
        _correct('a-m1'),
        holderName: 'Rima Akter',
      );
      expect(again.certificateCode, result.certificateCode);
      expect(await backend.list(), hasLength(1));

      final progress = await backend.load();
      expect(progress.single.itemId, 'm1');
      expect(progress.single.isCompleted, isTrue);
      expect(progress.single.scorePercent, 100);
    });

    test(
      '70% pass mark; every answer comes back with an explanation',
      () async {
        final answers = _correct('a-m1');
        answers['q-safe'] = 0; // wrong
        final fourOfFive = await backend.submit(
          'a-m1',
          answers,
          holderName: 'R',
        );
        expect(fourOfFive.percent, 80);
        expect(fourOfFive.passed, isTrue);
        expect(fourOfFive.review.where((r) => !r.isCorrect), hasLength(1));
        expect(
          fourOfFive.review.every((r) => r.explanation.isNotEmpty),
          isTrue,
        );

        answers['q-2h'] = 0; // second wrong → 60%
        final threeOfFive = await backend.submit(
          'a-m2',
          answers,
          holderName: 'R',
        );
        expect(threeOfFive.percent, 60);
        expect(threeOfFive.passed, isFalse);
        expect(threeOfFive.certificateCode, isNull);
      },
    );

    test('three attempts, then a 24-hour wait', () async {
      for (var i = 0; i < 3; i++) {
        final r = await backend.submit('a-m1', const {}, holderName: 'R');
        expect(r.attemptsLeft, 2 - i);
      }
      final status = await backend.status('a-m1');
      expect(status.isLocked(now), isTrue);
      expect(status.lockedUntil, DateTime(2026, 11, 7, 10));
      await expectLater(
        backend.submit('a-m1', _correct('a-m1'), holderName: 'R'),
        throwsA(isA<AttemptsExhaustedFailure>()),
      );

      now = DateTime(2026, 11, 7, 10, 1);
      expect((await backend.status('a-m1')).attemptsLeft, 3);
    });

    test('certificate assessments need a name', () async {
      await expectLater(
        backend.submit('a-m1', _correct('a-m1'), holderName: ' '),
        throwsA(isA<NameRequiredFailure>()),
      );
      // Chapter quizzes issue no certificate, so no name is needed.
      final r = await backend.submit('a-c2', _correct('a-c2'), holderName: '');
      expect(r.passed, isTrue);
      expect(r.certificateCode, isNull);
    });

    test('certificate codes avoid look-alike characters', () {
      for (var i = 0; i < 200; i++) {
        final code = generateCertificateCode(DateTime(2026));
        expect(code.substring(8), matches(RegExp(r'^[2-9A-HJKMNP-Z]{8}$')));
      }
    });

    test('the app-side assessment carries no answer key', () async {
      final a = await backend.fetch('a-m1');
      expect(a.questions, hasLength(5));
      // Question exposes only id, prompt and options.
      expect(a.questions.first.options, hasLength(4));
    });
  });

  group('Academy and Digi Skills screens', () {
    testWidgets('logged-in academy shows progress', (tester) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          progress: const [
            ItemProgress(
              type: LearningItemType.chapter,
              itemId: 'c2',
              status: ProgressStatus.completed,
              scorePercent: 100,
            ),
            ItemProgress(
              type: LearningItemType.chapter,
              itemId: 'c3',
              status: ProgressStatus.inProgress,
            ),
          ],
        ),
      );
      await pushRoute(tester, '/courses');

      expect(find.text('Your progress · 1/6 complete'), findsOneWidget);
      expect(find.text('11 min · Completed'), findsOneWidget);
      expect(find.text('16 min · In progress'), findsOneWidget);
    });

    testWidgets('module list shows sources and a locked assessment', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await tapAndSettle(tester, find.text('Digi Skills'));

      expect(find.text('BFSA'), findsNWidgets(2));
      expect(find.text('UNICEF'), findsOneWidget);
      expect(find.text('Finish the previous module first'), findsWidgets);
    });

    testWidgets('content server down: list and progress still render', (
      tester,
    ) async {
      await pumpAppAtHome(
        tester,
        storedValues: {
          ..._signedIn(),
          'digiskills_module_cache': jsonEncode([
            for (final m in FixtureModuleRepository.modules) m.toJson(),
          ]),
        },
        overrides: [
          moduleRepositoryProvider.overrideWith(
            (ref) => CachingModuleRepository(
              _DownModules(),
              ref.watch(sharedPreferencesProvider),
            ),
          ),
        ],
      );
      await pushRoute(tester, '/digi-skills');

      expect(find.byKey(const ValueKey('digi-offline')), findsOneWidget);
      expect(find.text('খাদ্য সংরক্ষণ ও হাইজিন'), findsOneWidget);
    });

    testWidgets('module content unavailable says progress is safe', (
      tester,
    ) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(),
        overrides: [moduleRepositoryProvider.overrideWithValue(_DownModules())],
      );
      await pushRoute(tester, '/digi-skills/m2');

      expect(
        find.textContaining('Your progress is safely saved'),
        findsOneWidget,
      );
    });
  });

  group('assessment (ASM-01 / ASM-02) and certificates (CRT-01 / CRT-02)', () {
    testWidgets('pass → certificate issued → detail with code', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/digi-skills/m1');
      await tapAndSettle(tester, find.text('Take the assessment'));

      expect(find.text('Question 1 / 5'), findsOneWidget);
      final key = fixtureAssessments['a-m1']!;
      await _answerAll(tester, [
        for (final q in key.assessment.questions) key.keys[q.id]!.correctIndex,
      ]);

      expect(find.byKey(const ValueKey('result-passed')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      await tapAndSettle(tester, find.text('View certificate'));

      expect(find.text('Rima Akter'), findsOneWidget);
      expect(find.textContaining('EP-'), findsOneWidget);
      expect(find.text('Online verification link coming soon'), findsOneWidget);
      expect(find.byKey(const ValueKey('certificate-qr')), findsNothing);
    });

    testWidgets('fail shows explanations and attempts left', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/assessment/a-c2');
      final key = fixtureAssessments['a-c2']!;
      await _answerAll(tester, [
        for (final q in key.assessment.questions)
          (key.keys[q.id]!.correctIndex + 1) % q.options.length,
      ]);

      expect(find.byKey(const ValueKey('result-failed')), findsOneWidget);
      expect(find.textContaining('2 attempts left'), findsOneWidget);
      expect(find.textContaining('Correct answer:'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Try again'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('leaving keeps answers and resumes where it stopped', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/assessment/a-m1');
      await _answerAll(tester, [1]);
      expect(find.text('Question 2 / 5'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('assessment-close')),
      );
      expect(find.text('Leave the assessment?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Leave'));

      await pushRoute(tester, '/assessment/a-m1');
      expect(find.text('Question 2 / 5'), findsOneWidget);
    });

    testWidgets('missing name is asked before a certificate is issued', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(holderName: null));
      await pushRoute(tester, '/assessment/a-m1');
      final key = fixtureAssessments['a-m1']!;
      await _answerAll(tester, [
        for (final q in key.assessment.questions) key.keys[q.id]!.correctIndex,
      ]);

      expect(find.text('Name on the certificate'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('certificate-name')),
        'Nadia Islam',
      );
      await tapAndSettle(tester, find.text('Save'));
      await tapAndSettle(tester, find.text('View certificate'));
      expect(find.text('Nadia Islam'), findsOneWidget);
    });

    testWidgets('no certificates routes to the modules', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/certificates');

      expect(find.byKey(const ValueKey('certificates-empty')), findsOneWidget);
      await tapAndSettle(tester, find.text('See modules'));
      expect(find.text('নিরাপদ খাদ্য: মৌলিক ধারণা'), findsOneWidget);
    });

    testWidgets('revoked certificate is shown as revoked', (tester) async {
      final cert = Certificate(
        code: 'EP-2026-P2V8TR6X',
        holderName: 'Rima Akter',
        title: 'খাদ্য সংরক্ষণ ও হাইজিন',
        sourceLabel: 'BFSA',
        issuedAt: DateTime(2026, 8, 29),
        revokedAt: DateTime(2026, 10, 1),
      );
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          certificates: [
            {...cert.toJson(), 'account': _account, 'assessment': 'a-m2'},
          ],
        ),
      );
      await pushRoute(tester, '/certificates');
      expect(find.textContaining('Revoked'), findsOneWidget);
      await tapAndSettle(tester, find.text('খাদ্য সংরক্ষণ ও হাইজিন'));

      expect(find.byKey(const ValueKey('certificate-revoked')), findsOneWidget);
      expect(find.byKey(const ValueKey('certificate-pdf')), findsNothing);
    });

    testWidgets('QR appears once a verification domain is configured', (
      tester,
    ) async {
      final cert = Certificate(
        code: 'EP-2026-K4M9XQ2A',
        holderName: 'Rima Akter',
        title: 'নিরাপদ খাদ্য: মৌলিক ধারণা',
        sourceLabel: 'BFSA',
        issuedAt: DateTime(2026, 7, 12),
      );
      await pumpAppAtHome(
        tester,
        config: AppRemoteConfig.fromJson({
          'verifyBaseUrl': 'https://verify.example.org',
        }),
        storedValues: _signedIn(
          certificates: [
            {...cert.toJson(), 'account': _account, 'assessment': 'a-m1'},
          ],
        ),
      );
      await pushRoute(tester, '/certificates/EP-2026-K4M9XQ2A');

      expect(find.byKey(const ValueKey('certificate-qr')), findsOneWidget);
      expect(
        find.text('Verify at https://verify.example.org/EP-2026-K4M9XQ2A'),
        findsOneWidget,
      );
    });

    testWidgets('certificates survive account deletion', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/assessment/a-m1');
      final key = fixtureAssessments['a-m1']!;
      await _answerAll(tester, [
        for (final q in key.assessment.questions) key.keys[q.id]!.correctIndex,
      ]);
      await pushRoute(tester, '/settings/delete-account');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('delete-account-confirm')),
      );

      final prefs = await SharedPreferences.getInstance();
      final registry = prefs.getString(
        LocalLearningBackend.certificateRegistryKey,
      );
      expect(registry, contains('Rima Akter'));
      expect(prefs.getString('local_${_account}_progress'), isNull);
    });
  });
}
