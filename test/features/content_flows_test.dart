import 'package:epushti/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

class _LoggedIn extends AuthController {
  _LoggedIn(this.phone);

  final String phone;

  @override
  AuthSession build() =>
      AuthSession.loggedIn(userId: 'test-user', phoneNumber: phone);
}

void main() {
  group('PUST9 (SMS-01)', () {
    testWidgets('shows both paths as peers with charge and steps', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('Subscribe'));

      expect(find.text('60-day nutrition curriculum'), findsOneWidget);
      expect(find.text('*213*02025#'), findsOneWidget);
      expect(find.text('START PUST9'), findsOneWidget);
      expect(find.text('Dial'), findsOneWidget);
      expect(find.text('Open SMS app'), findsOneWidget);
      expect(find.text('Copy'), findsNWidgets(2));
      expect(find.textContaining('৳1/day + VAT'), findsOneWidget);
      expect(find.byKey(const ValueKey('pust9-not-eligible')), findsNothing);
    });

    testWidgets('non-Robi/Airtel number is never a dead end', (tester) async {
      await pumpAppAtHome(
        tester,
        overrides: [
          authControllerProvider.overrideWith(
            () => _LoggedIn('+880 1712-345678'),
          ),
        ],
      );
      await tapAndSettle(tester, find.text('Subscribe'));

      expect(find.byKey(const ValueKey('pust9-not-eligible')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('content is open to you'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('content is open to you'), findsOneWidget);
    });
  });

  group('BMI (BMI-01 / BMI-02)', () {
    testWidgets('adult without age uses the adult standard', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('View now'));

      await tester.enterText(
        find.byKey(const ValueKey('bmi-height-cm')),
        '163',
      );
      await tester.enterText(find.byKey(const ValueKey('bmi-weight')), '57');
      await tapAndSettle(tester, find.text('Show result'));

      expect(find.text('21.5'), findsOneWidget);
      expect(find.text('On the adult standard'), findsOneWidget);
      expect(find.text('Add age'), findsOneWidget);
    });

    testWidgets('feet and inches input works', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('View now'));

      await tapAndSettle(tester, find.text('ft + in'));
      await tester.enterText(find.byKey(const ValueKey('bmi-height-ft')), '5');
      await tester.enterText(find.byKey(const ValueKey('bmi-height-in')), '4');
      await tester.enterText(find.byKey(const ValueKey('bmi-weight')), '57');
      await tapAndSettle(tester, find.text('Show result'));

      // 162.56 cm, 57 kg → 21.6
      expect(find.text('21.6'), findsOneWidget);
    });

    testWidgets('implausible height is flagged', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('View now'));

      await tester.enterText(find.byKey(const ValueKey('bmi-height-cm')), '16');
      await tester.enterText(find.byKey(const ValueKey('bmi-weight')), '57');
      await tapAndSettle(tester, find.text('Show result'));

      expect(find.text('Check the height'), findsOneWidget);
    });

    testWidgets('adult with age shows WHO bands', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/bmi/result?h=163&w=57&a=408&s=female');

      expect(find.text('21.5'), findsOneWidget);
      expect(find.text('Adult standard (WHO)'), findsOneWidget);
      expect(find.text('18.5 – 24.9'), findsOneWidget);
    });

    testWidgets('under five shows no number', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/bmi/result?h=95&w=14&a=38&s=female');

      expect(find.text("BMI doesn't apply"), findsOneWidget);
      expect(find.byKey(const ValueKey('bmi-value')), findsNothing);
    });

    testWidgets('sex "other" under 19 shows no number', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/bmi/result?h=155&w=45&a=168&s=other');

      expect(find.text("An age-based result can't be shown"), findsOneWidget);
      expect(find.byKey(const ValueKey('bmi-value')), findsNothing);
    });

    testWidgets('child 5–19 is classified on WHO BMI-for-age', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/bmi/result?h=132&w=27.5&a=112&s=male');

      expect(find.text('15.8'), findsOneWidget);
      expect(find.text('Position for age'), findsOneWidget);
      expect(
        find.textContaining("isn't available in this version"),
        findsNothing,
      );
      expect(find.text('Normal'), findsWidgets);
    });

    testWidgets('saving while logged out asks to log in', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/bmi/result?h=163&w=57&a=408&s=female');
      await tapAndSettle(tester, find.text('Save'));

      expect(find.text('Save your progress'), findsOneWidget);
    });
  });

  group('Academy (CRS-01 / CRS-02)', () {
    testWidgets('chapters are browsable logged out', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('Course'));

      expect(find.textContaining('All chapters can be read'), findsOneWidget);
      expect(find.text('3. স্বাস্থ্যসম্মত জীবনধারা'), findsOneWidget);
    });

    testWidgets('video states its size; failure keeps text readable', (
      tester,
    ) async {
      await pumpAppAtHome(tester, onWifi: true);
      await pushRoute(tester, '/courses/c3');

      expect(find.text('8:24 · 12.4 MB'), findsOneWidget);
      expect(
        find.text('Playing the video uses about 12 MB of data'),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.byIcon(Icons.play_circle_fill_rounded));

      expect(find.byKey(const ValueKey('video-failed')), findsOneWidget);
      expect(find.textContaining('সুস্থ থাকতে হলে'), findsOneWidget);
    });

    testWidgets('video is held back on mobile data by default', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/courses/c3');

      expect(find.textContaining('Wi-Fi only'), findsOneWidget);
    });

    testWidgets('quiz asks to log in when logged out', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/courses/c2');
      await tapAndSettle(tester, find.text('Take the quiz'));

      expect(find.textContaining('Log in to take the quiz'), findsOneWidget);
    });
  });

  group('Library (LIB-01 / LIB-02 / LIB-03)', () {
    testWidgets('search with no results offers a way out', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('Library'));
      await tapAndSettle(tester, find.byIcon(Icons.search_rounded));
      await tester.enterText(
        find.byKey(const ValueKey('library-search')),
        'ডায়াবেটিস',
      );
      await settle(tester);

      expect(find.text('No documents found'), findsOneWidget);
      await tapAndSettle(tester, find.text('See all documents'));
      expect(find.text('সুষম খাদ্য পিরামিড'), findsOneWidget);
    });

    testWidgets('large file asks first; later on Wi-Fi queues it', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/library/doc/d6');

      expect(find.byKey(const ValueKey('doc-large-consent')), findsOneWidget);
      await tapAndSettle(tester, find.text('Read later on Wi-Fi'));
      expect(find.textContaining('it will download on Wi-Fi'), findsOneWidget);

      await pushRoute(tester, '/library/downloads');
      expect(find.text('বার্ষিক প্রতিবেদন ২০২৫'), findsOneWidget);
      expect(find.textContaining('Waiting for Wi-Fi'), findsOneWidget);
    });

    testWidgets('small file opens without asking', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/library/doc/d1');

      expect(find.byKey(const ValueKey('doc-large-consent')), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);
    });
  });

  group('Webinars (WEB-01 / WEB-02)', () {
    testWidgets('lists upcoming and past events', (tester) async {
      await pumpAppAtHome(tester);
      await tapAndSettle(tester, find.text('Webinar'));

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('National Nutrition Week'), findsOneWidget);
      expect(find.text('8 seats left'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Past events'), 200);
      expect(find.text('Breastfeeding Week'), findsOneWidget);
    });

    testWidgets('full session offers the recording instead', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/webinars/w2');

      expect(find.byKey(const ValueKey('webinar-full')), findsOneWidget);
      expect(find.text('Tell me about the recording'), findsOneWidget);
    });

    testWidgets('reserving a seat asks to log in', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/webinars/w1');
      await tapAndSettle(tester, find.text('Reserve a seat'));

      expect(find.textContaining('Log in to reserve a seat'), findsOneWidget);
    });
  });

  group('Information (INF-01 / INF-02 / INF-04)', () {
    testWidgets('support states its scope before the message box', (
      tester,
    ) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/support');

      final scope = tester.getTopLeft(
        find.byKey(const ValueKey('support-scope')),
      );
      final box = tester.getTopLeft(
        find.byKey(const ValueKey('support-details')),
      );
      expect(scope.dy, lessThan(box.dy));
      expect(find.text('support@epushti.org'), findsOneWidget);
    });

    testWidgets('settings switches language', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/settings');
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('settings-language')),
      );
      await tapAndSettle(tester, find.text('বাংলা').last);

      expect(find.text('সেটিংস'), findsOneWidget);
    });

    testWidgets('about lists partners', (tester) async {
      await pumpAppAtHome(tester);
      await pushRoute(tester, '/about');

      expect(find.text('• UNICEF Bangladesh'), findsOneWidget);
    });
  });
}
