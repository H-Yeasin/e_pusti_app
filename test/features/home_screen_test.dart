import 'package:epushti/app/providers/app_environment_provider.dart';
import 'package:epushti/app/providers/app_locale_controller_provider.dart';
import 'package:epushti/app/view/e_pusti_app.dart';
import 'package:epushti/core/config/app_environment.dart';
import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/localization/localization.dart';
import 'package:epushti/core/widgets/commercial/ad_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the real app with a stored language so the splash goes to home.
Future<void> pumpAppAtHome(
  WidgetTester tester, {
  String language = 'en',
  AppRemoteConfig config = AppRemoteConfig.defaults,
}) async {
  SharedPreferences.setMockInitialValues({
    AppLanguageStore.languageCodeKey: language,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.dev),
        appLocaleControllerProvider.overrideWithValue(
          AppLocaleController(AppLanguageStore(preferences)),
        ),
        remoteConfigProvider.overrideWithValue(config),
      ],
      child: const EPustiApp(),
    ),
  );
  // Splash hands over after 2.5 s.
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Library'), findsOneWidget);
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

    expect(find.text('Simulate login (dev only)'), findsOneWidget);
    await tester.tap(find.text('Simulate login (dev only)'));
    await settle(tester);

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
