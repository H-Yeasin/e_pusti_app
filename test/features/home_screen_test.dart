import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/widgets/commercial/ad_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('home matches HOM-01 with the slot empty', (tester) async {
    await pumpAppAtHome(tester);

    expect(find.text('Daily nutrition SMS — PUST9'), findsOneWidget);
    expect(
      find.text('60-day course, daily tips straight to your SMS'),
      findsOneWidget,
    );
    for (final label in ['Webinar', 'Course', 'Digi Skills', 'Library']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('BMI Calculator'), findsOneWidget);

    // No always-on operator carousel; the unsold slot takes no space.
    expect(find.byType(ListView), findsNothing);
    expect(tester.getSize(find.byType(AdSlot)).height, 0);
  });

  testWidgets('Bangla copy and digits follow the design', (tester) async {
    await pumpAppAtHome(tester, language: 'bn');

    expect(
      find.text('৬০ দিনের কোর্স, দৈনিক টিপস সরাসরি SMS-এ'),
      findsOneWidget,
    );
    expect(find.text('ডিজি স্কিলস'), findsOneWidget);
  });

  testWidgets('house promotion fills the home banner slot', (tester) async {
    await pumpAppAtHome(
      tester,
      config: const AppRemoteConfig(
        pust9: Pust9Config.defaults,
        slots: {AdSlotId.homeBanner: HouseSlot(HousePromotion.pust9)},
        minSupportedVersion: '1.0.0',
      ),
    );

    expect(find.text('Daily nutrition SMS — PUST9'), findsNWidgets(2));
  });

  testWidgets('unconfirmed partner creative never renders', (tester) async {
    await pumpAppAtHome(
      tester,
      config: const AppRemoteConfig(
        pust9: Pust9Config.defaults,
        slots: {
          AdSlotId.homeBanner: PartnerSlot(
            imageUrl: 'https://example.com/creative.png',
            confirmedPartner: false,
          ),
        },
        minSupportedVersion: '1.0.0',
      ),
    );

    expect(
      find.byType(Image).evaluate().where((e) {
        final image = e.widget as Image;
        return image.image is NetworkImage;
      }),
      isEmpty,
    );
    expect(tester.getSize(find.byType(AdSlot)).height, 0);
  });

  testWidgets('dashboard tile opens its destination', (tester) async {
    await pumpAppAtHome(tester);

    await tester.tap(find.text('Library'));
    await settle(tester);

    expect(find.widgetWithText(AppBar, 'Library'), findsOneWidget);
    expect(find.text('সুষম খাদ্য পিরামিড'), findsOneWidget);
  });

  testWidgets('logged-out sidebar marks gated items and returns after login', (
    tester,
  ) async {
    await pumpAppAtHome(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await settle(tester);

    expect(find.text('Log in →'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(4));

    await tester.tap(find.text('My certificates'));
    await settle(tester);

    // LAU-05 sheet over the context, not a hard redirect.
    expect(find.text('Save your progress'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle(tester);

    await logInThroughScreens(tester);
    // First login asks for consent once, then returns to the destination.
    expect(find.text('How your information is used'), findsOneWidget);
    await acceptConsent(tester);

    expect(find.widgetWithText(AppBar, 'My certificates'), findsOneWidget);

    // Back returns to home, and the sidebar now shows the account.
    await tester.pageBack();
    await settle(tester);
    expect(find.text('BMI Calculator'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await settle(tester);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.text('+880 1712-345678'), findsOneWidget);
  });

  testWidgets('offline card lists what still works', (tester) async {
    await pumpAppAtHome(tester, online: false);

    expect(find.byKey(const ValueKey('offline-card')), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('BMI calculator'), findsOneWidget);
  });

  testWidgets('no offline card while online', (tester) async {
    await pumpAppAtHome(tester);

    expect(find.byKey(const ValueKey('offline-card')), findsNothing);
  });

  testWidgets('unsupported version sees only the update screen', (
    tester,
  ) async {
    await pumpAppAtHome(
      tester,
      appVersion: '0.9.0',
      config: AppRemoteConfig.fromJson({'minSupportedVersion': '1.0.0'}),
    );

    expect(find.text('Update the app'), findsOneWidget);
    expect(find.text('BMI Calculator'), findsNothing);
  });

  testWidgets('"Not now" keeps the user on home', (tester) async {
    await pumpAppAtHome(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await settle(tester);
    await tester.tap(find.text('Notifications'));
    await settle(tester);
    await tester.tap(find.text('Not now'));
    await settle(tester);

    expect(find.text('Save your progress'), findsNothing);
    expect(find.text('BMI Calculator'), findsOneWidget);
  });
}
