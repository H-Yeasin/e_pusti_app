import 'package:epushti/app/router/app_router.dart';
import 'package:epushti/app/router/app_routes.dart';
import 'package:epushti/core/config/remote_config.dart';
import 'package:epushti/core/localization/digits.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localizeDigits', () {
    test('converts to Bangla digits for bn', () {
      expect(localizeDigits('60 · 1.0.0', const Locale('bn')), '৬০ · ১.০.০');
    });

    test('leaves English untouched', () {
      expect(localizeDigits('60', const Locale('en')), '60');
    });
  });

  group('AppRemoteConfig', () {
    test('every slot is empty by default (launch state)', () {
      for (final id in AdSlotId.values) {
        expect(AppRemoteConfig.defaults.slot(id), isA<EmptySlot>());
      }
    });

    test('parses slots and PUST9 values, ignoring unknown slots', () {
      final config = AppRemoteConfig.fromJson({
        'pust9': {'courseDays': 30},
        'slots': {
          'home_banner': {
            'type': 'partner',
            'imageUrl': 'https://example.com/a.png',
            'confirmedPartner': true,
          },
          'pust9_banner': {'type': 'house', 'promotion': 'pust9'},
          'unknown_slot': {'type': 'house', 'promotion': 'pust9'},
        },
      });

      expect(config.pust9.courseDays, 30);
      expect(config.pust9.shortcode, Pust9Config.defaults.shortcode);
      final banner = config.slot(AdSlotId.homeBanner);
      expect(banner, isA<PartnerSlot>());
      expect((banner as PartnerSlot).confirmedPartner, isTrue);
      expect(config.slot(AdSlotId.pust9Banner), isA<HouseSlot>());
      expect(config.slots.length, 2);
    });
  });

  group('resolveRedirect', () {
    String? redirect(String location, {bool loggedIn = false}) =>
        resolveRedirect(
          location: Uri.parse(location),
          isLoggedIn: loggedIn,
          isDev: false,
        );

    test('open screens never redirect', () {
      expect(redirect(AppRoutes.bmi), isNull);
      expect(redirect(AppRoutes.library), isNull);
    });

    test('gated screen sends logged-out user to login with return target', () {
      expect(
        redirect(AppRoutes.certificates),
        AppRoutes.loginReturningTo(AppRoutes.certificates),
      );
    });

    test('gated screen is reachable when logged in', () {
      expect(redirect(AppRoutes.certificates, loggedIn: true), isNull);
    });

    test('login returns a logged-in user to where they were', () {
      expect(
        redirect(AppRoutes.loginReturningTo(AppRoutes.profile), loggedIn: true),
        AppRoutes.profile,
      );
    });

    test('login ignores external or looping return targets', () {
      expect(
        redirect('/login?from=https://evil.example', loggedIn: true),
        AppRoutes.home,
      );
      expect(redirect('/login?from=//evil', loggedIn: true), AppRoutes.home);
      expect(redirect('/login?from=/login', loggedIn: true), AppRoutes.home);
    });

    test('dev catalog is closed outside dev', () {
      expect(redirect(AppRoutes.devCatalog), AppRoutes.home);
    });
  });
}
