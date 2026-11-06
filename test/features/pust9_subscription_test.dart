import 'dart:convert';

import 'package:epushti/app/router/app_router.dart';
import 'package:epushti/app/router/app_routes.dart';
import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/features/pust9/data/local_pust9_repository.dart';
import 'package:epushti/features/pust9/domain/pust9_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

const _account = 'acc-pust9';

Map<String, Object> _signedIn({
  String phone = '+8801812345678',
  Map<String, Object?>? pust9,
}) => {
  'local_backend_session': jsonEncode({'id': _account, 'phone': phone}),
  'local_backend_accounts': jsonEncode({_account: phone}),
  'local_${_account}_consent': jsonEncode({
    'terms': '2026-11-01T10:00:00.000',
    'health': '2026-11-01T10:00:00.000',
  }),
  if (pust9 != null) 'local_${_account}_pust9': jsonEncode(pust9),
};

final _inApp = AppRemoteConfig.fromJson({
  'pust9': {'inAppSubscribe': true},
});

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  group('LocalPust9Repository', () {
    late SharedPreferences prefs;
    var now = DateTime(2026, 11, 7, 9);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime(2026, 11, 7, 9);
    });

    LocalPust9Repository repo() =>
        LocalPust9Repository(prefs, 'a', courseDays: 60, clock: () => now);

    test('OTP → subscribed → day count → stop', () async {
      final r = repo();
      expect((await r.status()).phase, Pust9Phase.notSubscribed);

      await r.requestOtp('+8801812345678');
      expect((await r.status()).phase, Pust9Phase.otpSent);

      await expectLater(
        r.verifyOtp('000000'),
        throwsA(isA<Pust9InvalidCodeFailure>()),
      );
      final ok = await r.verifyOtp('123456');
      expect(ok.isSubscribed, isTrue);
      expect(ok.day, 1);
      expect(ok.phone, '+8801812345678');

      now = now.add(const Duration(days: 9));
      expect((await r.status()).day, 10);
      now = now.add(const Duration(days: 100));
      expect((await r.status()).day, 60, reason: 'capped at the course length');

      final stopped = await r.unsubscribe();
      expect(stopped.phase, Pust9Phase.unsubscribed);
    });

    test('only Robi and Airtel numbers get a code', () async {
      await expectLater(
        repo().requestOtp('+8801712345678'),
        throwsA(isA<Pust9NotEligibleFailure>()),
      );
      await repo().requestOtp('+8801612345678');
    });

    test('verify without a requested code is expired', () async {
      await expectLater(
        repo().verifyOtp('123456'),
        throwsA(isA<Pust9CodeExpiredFailure>()),
      );
    });
  });

  group('Pust9Status / Pust9Failure from the function', () {
    test('parses the subscribed response', () {
      final s = Pust9Status.fromJson({
        'state': 'subscribed',
        'subscribedAt': '2026-11-07T03:00:00.000Z',
        'day': 4,
        'courseDays': 60,
        'phone': '+8801812345678',
      });
      expect(s.isSubscribed, isTrue);
      expect(s.day, 4);
      expect(s.since, DateTime.utc(2026, 11, 7, 3));
    });

    test('maps error codes', () {
      expect(
        Pust9Failure.fromCode('invalid_code'),
        isA<Pust9InvalidCodeFailure>(),
      );
      expect(
        Pust9Failure.fromCode('rate_limited'),
        isA<Pust9RateLimitedFailure>(),
      );
      expect(Pust9Failure.fromCode('upstream'), isA<Pust9ServiceFailure>());
    });

    test('remote config flag defaults off', () {
      expect(Pust9Config.defaults.inAppSubscribe, isFalse);
      expect(_inApp.pust9.inAppSubscribe, isTrue);
    });
  });

  test('the confirm screen needs login', () {
    expect(AppRoutes.isGated(AppRoutes.pust9Verify), isTrue);
    expect(AppRoutes.isGated(AppRoutes.pust9), isFalse);
    expect(
      resolveRedirect(
        location: Uri.parse(AppRoutes.pust9Verify),
        isLoggedIn: false,
        isDev: true,
        updateRequired: false,
      ),
      startsWith(AppRoutes.login),
    );
  });

  group('PUST9 screen, in-app subscription', () {
    testWidgets('hidden while the flag is off', (tester) async {
      await pumpAppAtHome(tester, storedValues: _signedIn());
      await pushRoute(tester, '/pust9');
      expect(find.byKey(const ValueKey('pust9-in-app')), findsNothing);
      await _scrollTo(tester, find.byKey(const ValueKey('pust9-status-note')));
      expect(find.byKey(const ValueKey('pust9-status-note')), findsOneWidget);
    });

    testWidgets('logged out: subscribe opens the login sheet', (tester) async {
      await pumpAppAtHome(tester, config: _inApp);
      await pushRoute(tester, '/pust9');
      expect(
        find.text(
          'Log in with your Robi or Airtel number, then confirm with the code we send by SMS.',
        ),
        findsOneWidget,
      );
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('pust9-in-app-subscribe')),
      );
      expect(find.text('Log in to subscribe'), findsOneWidget);
    });

    testWidgets('not offered to a Grameenphone number', (tester) async {
      await pumpAppAtHome(
        tester,
        config: _inApp,
        storedValues: _signedIn(phone: '+8801712345678'),
      );
      await pushRoute(tester, '/pust9');
      expect(find.byKey(const ValueKey('pust9-in-app')), findsNothing);
      expect(find.byKey(const ValueKey('pust9-not-eligible')), findsOneWidget);
    });

    testWidgets('subscribe with the code, see the day, then stop', (
      tester,
    ) async {
      await pumpAppAtHome(tester, config: _inApp, storedValues: _signedIn());
      await pushRoute(tester, '/pust9');
      expect(find.text('Or subscribe yourself'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('pust9-in-app-subscribe')),
      );
      expect(find.text('Confirm subscription'), findsOneWidget);
      expect(find.byKey(const ValueKey('pust9-otp-charge')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('pust9-otp-field')),
        '111111',
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('pust9-otp-error')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('pust9-otp-field')),
        '123456',
      );
      await settle(tester);

      expect(find.byKey(const ValueKey('pust9-subscribed')), findsOneWidget);
      expect(find.text('Day 1 of 60'), findsOneWidget);
      expect(find.text('Subscribe by dialling'), findsNothing);
      expect(find.byKey(const ValueKey('pust9-status-note')), findsNothing);

      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('pust9-in-app-stop')),
      );
      expect(find.text('Stop PUST9?'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('pust9-stop-confirm')),
      );

      expect(find.byKey(const ValueKey('pust9-subscribed')), findsNothing);
      expect(find.byKey(const ValueKey('pust9-unsubscribed')), findsOneWidget);
      expect(find.text('Subscribe by dialling'), findsOneWidget);
    });

    testWidgets('home card and settings show the subscription', (tester) async {
      await pumpAppAtHome(
        tester,
        config: _inApp,
        storedValues: _signedIn(
          pust9: {
            'phase': 'subscribed',
            'phone': '+8801812345678',
            'since': DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String(),
          },
        ),
      );
      await settle(tester);
      expect(find.text('Subscribed · Day 5'), findsOneWidget);

      await pushRoute(tester, '/settings');
      await _scrollTo(tester, find.byKey(const ValueKey('settings-pust9')));
      await tapAndSettle(tester, find.byKey(const ValueKey('settings-pust9')));
      expect(find.byKey(const ValueKey('pust9-subscribed')), findsOneWidget);
    });
  });
}
