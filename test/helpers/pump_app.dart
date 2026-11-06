import 'package:epushti/app/bootstrap.dart';
import 'package:epushti/app/providers/app_environment_provider.dart';
import 'package:epushti/app/providers/app_locale_controller_provider.dart';
import 'package:epushti/app/router/app_router.dart';
import 'package:epushti/app/view/e_pusti_app.dart';
import 'package:epushti/core/config/app_environment.dart';
import 'package:epushti/core/config/app_info.dart';
import 'package:epushti/core/config/backend_config.dart';
import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/localization/localization.dart';
import 'package:epushti/core/network/connectivity_provider.dart';
import 'package:epushti/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the real app with a stored language so the splash goes to home.
Future<void> pumpAppAtHome(
  WidgetTester tester, {
  String language = 'en',
  AppRemoteConfig config = AppRemoteConfig.defaults,
  String appVersion = '1.0.0',
  bool online = true,
  bool onWifi = false,
  List<Override> overrides = const [],
  BackendKind backend = BackendKind.local,
  Map<String, Object> storedValues = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    AppLanguageStore.languageCodeKey: language,
    ...storedValues,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.dev),
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendKindProvider.overrideWithValue(backend),
        appLocaleControllerProvider.overrideWithValue(
          AppLocaleController(AppLanguageStore(preferences)),
        ),
        appInfoProvider.overrideWithValue(AppInfo(version: appVersion)),
        remoteConfigProvider.overrideWithValue(config),
        isOnlineProvider.overrideWith((ref) => Stream.value(online)),
        isOnWifiProvider.overrideWith((ref) => Stream.value(onWifi)),
        ...overrides,
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

/// Pushes [location] on the real router, as a tap would.
Future<void> pushRoute(WidgetTester tester, String location) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(EPustiApp)),
  );
  container.read(appRouterProvider).push(location);
  await settle(tester);
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Logs in through the real LAU-03 / LAU-04 screens with the dev code.
Future<void> logInThroughScreens(
  WidgetTester tester, {
  String phone = '1712345678',
}) async {
  await tester.enterText(find.byKey(const ValueKey('login-phone')), phone);
  await tapAndSettle(tester, find.text('Send code'));
  await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
  await settle(tester);
}

/// Completes PRO-03 with both boxes ticked.
Future<void> acceptConsent(WidgetTester tester) async {
  await tapAndSettle(tester, find.byKey(const ValueKey('consent-terms')));
  await tapAndSettle(tester, find.byKey(const ValueKey('consent-health')));
  await tapAndSettle(tester, find.text('Agree and continue'));
}
