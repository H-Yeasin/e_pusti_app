import 'dart:convert';

import 'package:epushti/core/config/backend_config.dart';
import 'package:epushti/features/auth/data/local_backend.dart';
import 'package:epushti/features/auth/domain/auth_repository.dart';
import 'package:epushti/features/auth/presentation/phone_number.dart';
import 'package:epushti/features/bmi/domain/entities/bmi_models.dart';
import 'package:epushti/features/profile/domain/profile_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

const _account = 'acc1';

/// Dev-backend storage for a signed-in account, optionally with consent
/// and family members.
Map<String, Object> _signedIn({
  bool consent = true,
  List<Person> people = const [],
  List<Measurement> measurements = const [],
}) => {
  'local_backend_session': jsonEncode({
    'id': _account,
    'phone': '+8801812345678',
  }),
  'local_backend_accounts': jsonEncode({_account: '+8801812345678'}),
  if (consent)
    'local_${_account}_consent': jsonEncode({
      'terms': '2026-11-01T10:00:00.000',
      'health': '2026-11-01T10:00:00.000',
    }),
  if (people.isNotEmpty)
    'local_${_account}_people': jsonEncode([
      for (final p in people) p.toJson(),
    ]),
  if (measurements.isNotEmpty)
    'local_${_account}_measurements': jsonEncode([
      for (final m in measurements) m.toJson(),
    ]),
};

final _holder = Person(
  id: 'h1',
  relationship: Relationship.holder,
  name: 'Rima',
  dateOfBirth: DateTime(1992, 3, 12),
  sex: Sex.female,
  districtId: 'dhaka',
);

final _arif = Person(
  id: 'k1',
  relationship: Relationship.child,
  name: 'Arif',
  dateOfBirth: DateTime(2017, 4, 4),
  sex: Sex.male,
);

void main() {
  group('unit', () {
    test('phone numbers normalise to E.164', () {
      expect(PhoneNumber.normalize('1712345678'), '+8801712345678');
      expect(PhoneNumber.normalize('01712-345678'), '+8801712345678');
      expect(PhoneNumber.normalize('+880 1712 345678'), '+8801712345678');
      expect(PhoneNumber.normalize('০১৮১২৩৪৫৬৭৮'), '+8801812345678');
      expect(PhoneNumber.normalize('1212345678'), isNull);
      expect(PhoneNumber.normalize('17123'), isNull);
      expect(PhoneNumber.display('+8801712345678'), '+880 1712-345678');
    });

    test('age in completed months', () {
      final p = Person(
        id: 'x',
        relationship: Relationship.child,
        dateOfBirth: DateTime(2017, 4, 4),
      );
      expect(p.ageMonthsAt(DateTime(2026, 8, 29)), 112);
      expect(p.ageMonthsAt(DateTime(2026, 8, 3)), 111);
      expect(
        const Person(
          id: 'y',
          relationship: Relationship.child,
        ).ageMonthsAt(DateTime(2026)),
        isNull,
      );
    });

    test('person survives a JSON round trip', () {
      final p = _holder.copyWith(
        pregnant: true,
        interests: {Interest.balancedDiet, Interest.childNutrition},
        occupation: Occupation.homemaker,
      );
      final back = Person.fromJson(p.toJson());
      expect(back.name, 'Rima');
      expect(back.dateOfBirth, DateTime(1992, 3, 12));
      expect(back.sex, Sex.female);
      expect(back.districtId, 'dhaka');
      expect(back.occupation, Occupation.homemaker);
      expect(back.pregnant, isTrue);
      expect(back.interests, {Interest.balancedDiet, Interest.childNutrition});
    });

    test('dev backend locks out after repeated wrong codes', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalAuthRepository(await SharedPreferences.getInstance());
      await repo.requestCode('+8801712345678');
      for (var i = 0; i < LocalAuthRepository.maxWrongAttempts - 1; i++) {
        await expectLater(
          repo.verifyCode('+8801712345678', '000000'),
          throwsA(isA<InvalidCodeFailure>()),
        );
      }
      await expectLater(
        repo.verifyCode('+8801712345678', '000000'),
        throwsA(isA<TooManyAttemptsFailure>()),
      );
      await expectLater(
        repo.verifyCode('+8801712345678', LocalBackend.devOtpCode),
        throwsA(isA<TooManyAttemptsFailure>()),
      );
      // A new code resets the lock.
      await repo.requestCode('+8801712345678');
      final user = await repo.verifyCode(
        '+8801712345678',
        LocalBackend.devOtpCode,
      );
      expect(user.phone, '+8801712345678');
    });
  });

  group('login (LAU-03 / LAU-04)', () {
    testWidgets('invalid number is flagged before sending', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/login');
      await tester.enterText(
        find.byKey(const ValueKey('login-phone')),
        '12345',
      );
      await tapAndSettle(tester, find.text('Send code'));

      expect(
        find.text('Enter a valid Bangladeshi mobile number'),
        findsOneWidget,
      );
      expect(find.text('Verify code'), findsNothing);
    });

    testWidgets('wrong code is explained and can be retried', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/login');
      await tester.enterText(
        find.byKey(const ValueKey('login-phone')),
        '1712345678',
      );
      await tapAndSettle(tester, find.text('Send code'));

      expect(find.text('+880 1712-345678'), findsOneWidget);
      expect(find.textContaining('Resend code —'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('otp-field')), '111111');
      await settle(tester);

      expect(find.text("That code isn't right — try again"), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
      await settle(tester);
      expect(find.text('How your information is used'), findsOneWidget);
    });

    testWidgets('resend appears after the countdown', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/login');
      await tester.enterText(
        find.byKey(const ValueKey('login-phone')),
        '1712345678',
      );
      await tapAndSettle(tester, find.text('Send code'));
      await tester.pump(const Duration(seconds: 61));
      await settle(tester);

      expect(find.text('Resend code'), findsOneWidget);
      expect(find.textContaining('Code taking long?'), findsOneWidget);
    });

    testWidgets('production build without keys says login is unavailable', (
      tester,
    ) async {
      await pumpAppAtHome(tester, backend: BackendKind.none);
      await pushRoute(tester, '/login');

      expect(
        find.textContaining("Login isn't available in this version"),
        findsOneWidget,
      );
      expect(find.text('Send code'), findsNothing);
    });

    testWidgets('consent "Not now" still lets the user in', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/login?from=/profile');
      await logInThroughScreens(tester);
      await tapAndSettle(tester, find.text('Not now'));

      expect(
        find.byKey(const ValueKey('profile-consent-banner')),
        findsOneWidget,
      );
    });
  });

  group('profile and family (PRO-01 / PRO-02 / PRO-04)', () {
    testWidgets('holder only shows the add-family invitation', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/profile');

      expect(find.text('Rima'), findsOneWidget);
      expect(find.textContaining('34 years · Female · Dhaka'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-add-family')), findsOneWidget);
    });

    testWidgets('holder record is created on first visit', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/profile');

      expect(find.text('Add your details'), findsOneWidget);
    });

    testWidgets('add a dependant with relationship and sex', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/profile');
      await tapAndSettle(tester, find.text('Add member'));

      await tester.enterText(
        find.byKey(const ValueKey('person-name')),
        'Nadia',
      );
      await tapAndSettle(tester, find.byKey(const ValueKey('person-sex')));
      // The sex picker states the BMI consequence of "Other".
      expect(find.textContaining('With "Other"'), findsOneWidget);
      await tapAndSettle(tester, find.text('Female'));
      await tapAndSettle(tester, find.byKey(const ValueKey('person-save')));

      expect(find.text('Your family · 1'), findsOneWidget);
      expect(find.text('Nadia'), findsOneWidget);
    });

    testWidgets('district picker searches and groups by division', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/profile');
      await tapAndSettle(tester, find.text('Edit'));
      await tapAndSettle(tester, find.byKey(const ValueKey('person-district')));

      expect(find.text('Dhaka Division'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('district-search')),
        'syl',
      );
      await settle(tester);
      expect(find.text('Sylhet Division'), findsOneWidget);
      await tapAndSettle(tester, find.text('Sylhet'));
      await tapAndSettle(tester, find.byKey(const ValueKey('person-save')));

      expect(find.textContaining('Female · Sylhet'), findsOneWidget);
    });

    testWidgets('remove a dependant after confirming', (tester) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(people: [_holder, _arif]),
      );
      await pushRoute(tester, '/profile');
      await tapAndSettle(tester, find.text('Arif'));
      await tapAndSettle(tester, find.text('Remove member'));
      await tapAndSettle(tester, find.text('Delete'));

      expect(find.text('Arif'), findsNothing);
      expect(find.byKey(const ValueKey('profile-add-family')), findsOneWidget);
    });

    testWidgets('saving without consent asks for it first', (tester) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(consent: false, people: [_holder]),
      );
      await pushRoute(tester, '/profile/person/h1');
      await tapAndSettle(tester, find.byKey(const ValueKey('person-save')));

      expect(find.text('How your information is used'), findsOneWidget);
    });
  });

  group('BMI for the family (BMI-01 / BMI-02 / BMI-03)', () {
    testWidgets('choosing a child fills age and sex from the profile', (
      tester,
    ) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(people: [_holder, _arif]),
      );
      await pushRoute(tester, '/bmi');

      expect(find.text('Who is this for?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Arif'));
      await tester.enterText(
        find.byKey(const ValueKey('bmi-height-cm')),
        '132',
      );
      await tester.enterText(find.byKey(const ValueKey('bmi-weight')), '27.5');
      await tapAndSettle(tester, find.text('Show result'));

      expect(find.text('Position for age'), findsOneWidget);
      expect(
        find.textContaining('Arif ·'),
        findsNothing,
      ); // child line uses age · group
    });

    testWidgets('save, see history, correct and delete a record', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/bmi/result?h=163&w=57&a=414&s=female&p=h1');
      await tapAndSettle(tester, find.text('Save'));
      expect(find.text('Saved to records'), findsOneWidget);

      await pushRoute(tester, '/bmi/history?p=h1');
      expect(find.textContaining('1 records'), findsOneWidget);
      expect(find.text('21.5'), findsOneWidget);

      await tapAndSettle(tester, find.text('21.5'));
      await tester.enterText(find.byKey(const ValueKey('edit-weight')), '60');
      await tapAndSettle(tester, find.text('Save').last);
      expect(find.text('22.6'), findsOneWidget);

      await tapAndSettle(tester, find.text('22.6'));
      await tapAndSettle(tester, find.text('Delete').last);
      await tapAndSettle(tester, find.text('Delete').last);
      expect(find.byKey(const ValueKey('history-empty')), findsOneWidget);
    });

    testWidgets('anonymous result asks whom to save for', (tester) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(people: [_holder, _arif]),
      );
      await pushRoute(tester, '/bmi/result?h=163&w=57');
      await tapAndSettle(tester, find.text('Save'));

      expect(find.text('Save for whom?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Rima'));
      expect(find.text('Saved to records'), findsOneWidget);
    });

    testWidgets('under-five history shows no BMI number', (tester) async {
      final nadia = Person(
        id: 'k2',
        relationship: Relationship.child,
        name: 'Nadia',
        dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 3)),
        sex: Sex.female,
      );
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          people: [_holder, nadia],
          measurements: [
            Measurement(
              id: 'm1',
              personId: 'k2',
              measuredAt: DateTime.now(),
              heightCm: 95,
              weightKg: 14,
            ),
          ],
        ),
      );
      await pushRoute(tester, '/bmi/history?p=k2');

      expect(find.text('—'), findsOneWidget);
    });
  });

  group('settings and privacy (INF-04 / INF-05 / INF-06 / INF-07)', () {
    testWidgets('withdrawing consent deletes records', (tester) async {
      await pumpAppAtHome(
        tester,
        storedValues: _signedIn(
          people: [_holder],
          measurements: [
            Measurement(
              id: 'm1',
              personId: 'h1',
              measuredAt: DateTime(2026, 8, 29),
              heightCm: 163,
              weightKg: 57,
            ),
          ],
        ),
      );
      await pushRoute(tester, '/settings/privacy');
      expect(find.text('Health data storage: on'), findsOneWidget);
      await tapAndSettle(tester, find.text('Withdraw health data consent'));
      await tapAndSettle(tester, find.text('Withdraw'));

      expect(find.text('Health data storage: off'), findsOneWidget);
      await pushRoute(tester, '/bmi/history?p=h1');
      expect(find.byKey(const ValueKey('history-empty')), findsOneWidget);
    });

    testWidgets('logout asks first and keeps the user on home', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/settings');
      await tapAndSettle(tester, find.byKey(const ValueKey('settings-logout')));
      expect(find.textContaining('Downloaded files stay'), findsOneWidget);
      await tapAndSettle(tester, find.text('Log out').last);

      expect(find.text('BMI Calculator'), findsOneWidget);
      await tapAndSettle(tester, find.byIcon(Icons.menu_rounded));
      expect(find.text('Log in →'), findsOneWidget);
    });

    testWidgets('delete account states what survives, then removes data', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/settings/delete-account');

      expect(
        find.textContaining('Issued certificates stay verifiable'),
        findsOneWidget,
      );
      expect(find.textContaining('PUST9 subscription stays'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('delete-account-confirm')),
      );

      expect(find.text('Account deleted'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('local_${_account}_people'), isNull);
      expect(prefs.getString('local_backend_session'), isNull);
    });

    testWidgets('change number moves the account', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn(people: [_holder]));
      await pushRoute(tester, '/settings');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('settings-change-number')),
      );
      expect(find.text('Enter your new mobile number'), findsOneWidget);
      await logInThroughScreens(tester, phone: '1612345678');

      expect(find.text('Number changed'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-change-number')),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('local_backend_session'),
        contains('+8801612345678'),
      );
    });
  });
}
