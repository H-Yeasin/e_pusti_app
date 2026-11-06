import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';

/// Configurable ad / partner placements named in the design (group SLOT).
enum AdSlotId {
  homeBanner('home_banner'),
  pust9Banner('pust9_banner'),
  chapterHeader('chapter_header'),
  certFooter('cert_footer'),
  libraryHeader('library_header'),
  viewerFooter('viewer_footer');

  const AdSlotId(this.key);

  final String key;

  static AdSlotId? fromKey(String key) {
    for (final id in values) {
      if (id.key == key) {
        return id;
      }
    }
    return null;
  }
}

/// What a slot shows. The launch state for every slot is [EmptySlot].
sealed class SlotContent {
  const SlotContent();

  factory SlotContent.fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'house' => HouseSlot(
        HousePromotion.fromKey(json['promotion'] as String? ?? ''),
      ),
      'partner' => PartnerSlot(
        imageUrl: json['imageUrl'] as String? ?? '',
        clickUrl: json['clickUrl'] as String?,
        confirmedPartner: json['confirmedPartner'] == true,
      ),
      _ => const EmptySlot(),
    };
  }
}

/// Unsold slot: renders nothing at all (0 px, no placeholder, no label).
final class EmptySlot extends SlotContent {
  const EmptySlot();
}

/// The slot serving BIID's own content, in brand tint.
final class HouseSlot extends SlotContent {
  const HouseSlot(this.promotion);

  final HousePromotion? promotion;
}

/// Advertiser creative. Rendered only when [confirmedPartner] is true.
final class PartnerSlot extends SlotContent {
  const PartnerSlot({
    required this.imageUrl,
    required this.confirmedPartner,
    this.clickUrl,
  });

  final String imageUrl;
  final String? clickUrl;
  final bool confirmedPartner;
}

enum HousePromotion {
  pust9('pust9');

  const HousePromotion(this.key);

  final String key;

  static HousePromotion? fromKey(String key) {
    for (final promotion in values) {
      if (promotion.key == key) {
        return promotion;
      }
    }
    return null;
  }
}

/// PUST9 commercial details. Open items O-01 / O-02: values are provisional
/// and must come from the server once confirmed.
class Pust9Config {
  const Pust9Config({
    required this.courseDays,
    required this.ussdCode,
    required this.shortcode,
    required this.keyword,
    required this.pricePerDayTaka,
    this.stopShortcode,
    this.stopKeyword,
    this.inAppSubscribe = false,
  });

  /// Wireframe V4 says 60 days; the earlier app copy said 30 (decision A1).
  static const defaults = Pust9Config(
    courseDays: 60,
    ussdCode: '*213*02025#',
    shortcode: '21213',
    keyword: 'START PUST9',
    pricePerDayTaka: 1,
  );

  final int courseDays;
  final String ussdCode;
  final String shortcode;
  final String keyword;

  /// Before VAT, supplementary duty and surcharge.
  final num pricePerDayTaka;

  /// How to unsubscribe; shown only once confirmed with the operators.
  final String? stopShortcode;
  final String? stopKeyword;

  /// Offer subscribing inside the app through the bdapps OTP API. Off until
  /// the `pust9-subscribe` function is deployed with the bdapps credentials.
  final bool inAppSubscribe;

  factory Pust9Config.fromJson(Map<String, Object?> json) {
    const d = defaults;
    return Pust9Config(
      courseDays: (json['courseDays'] as num?)?.toInt() ?? d.courseDays,
      ussdCode: json['ussdCode'] as String? ?? d.ussdCode,
      shortcode: json['shortcode'] as String? ?? d.shortcode,
      keyword: json['keyword'] as String? ?? d.keyword,
      pricePerDayTaka: json['pricePerDayTaka'] as num? ?? d.pricePerDayTaka,
      stopShortcode: json['stopShortcode'] as String?,
      stopKeyword: json['stopKeyword'] as String?,
      inAppSubscribe: json['inAppSubscribe'] as bool? ?? d.inAppSubscribe,
    );
  }
}

/// How long after the last measurement a reminder is due. Pending
/// clinical confirmation (O-13 / O-17).
class MeasurementReminderDays {
  const MeasurementReminderDays({
    required this.underFive,
    required this.child,
    required this.adult,
  });

  static const defaults = MeasurementReminderDays(
    underFive: 30,
    child: 90,
    adult: 180,
  );

  final int underFive;
  final int child;
  final int adult;

  int forAgeMonths(int? months) {
    if (months == null || months >= 19 * 12) return adult;
    return months < 60 ? underFive : child;
  }

  factory MeasurementReminderDays.fromJson(Map<String, Object?> json) =>
      MeasurementReminderDays(
        underFive: (json['underFive'] as num?)?.toInt() ?? defaults.underFive,
        child: (json['child'] as num?)?.toInt() ?? defaults.child,
        adult: (json['adult'] as num?)?.toInt() ?? defaults.adult,
      );
}

class AppRemoteConfig {
  const AppRemoteConfig({
    required this.pust9,
    required this.slots,
    required this.minSupportedVersion,
    this.latestVersion,
    this.updateSizeMb,
    this.storeUrl,
    this.supportEmail = 'support@epushti.org',
    this.privacyUrl,
    this.termsUrl,
    this.verifyBaseUrl,
    this.shareBaseUrl,
    this.measurementReminderDays = MeasurementReminderDays.defaults,
    this.ancContactWeeks,
  });

  /// Bundled defaults used until (and whenever) the server config is not
  /// available. Every slot is empty: that is the launch state.
  static const defaults = AppRemoteConfig(
    pust9: Pust9Config.defaults,
    slots: {},
    minSupportedVersion: '1.0.0',
  );

  final Pust9Config pust9;
  final Map<AdSlotId, SlotContent> slots;
  final String minSupportedVersion;

  /// Shown on the forced-update screen (SYS-04).
  final String? latestVersion;
  final double? updateSizeMb;
  final String? storeUrl;

  /// From the INF-02 design.
  final String supportEmail;

  /// Not published yet; the rows say "coming soon" while null.
  final String? privacyUrl;
  final String? termsUrl;

  /// Public certificate verification page, e.g. `https://verify.epushti.org`
  /// (open item O-15). While null, certificates show the code but no QR.
  final String? verifyBaseUrl;

  /// Public web base for shared links, e.g. `https://epushti.org`. While
  /// null, shares carry text and the in-app `epushti://` link only.
  final String? shareBaseUrl;

  final MeasurementReminderDays measurementReminderDays;

  /// Pregnancy weeks of antenatal care contacts. Null until the schedule is
  /// confirmed for Bangladesh; the journey then shows no visit reminders.
  final List<int>? ancContactWeeks;

  SlotContent slot(AdSlotId id) => slots[id] ?? const EmptySlot();

  factory AppRemoteConfig.fromJson(Map<String, Object?> json) {
    final rawSlots = json['slots'];
    final slots = <AdSlotId, SlotContent>{};
    if (rawSlots is Map) {
      for (final entry in rawSlots.entries) {
        final id = AdSlotId.fromKey('${entry.key}');
        final value = entry.value;
        if (id != null && value is Map) {
          slots[id] = SlotContent.fromJson(value.cast<String, Object?>());
        }
      }
    }
    final rawPust9 = json['pust9'];
    return AppRemoteConfig(
      pust9: rawPust9 is Map
          ? Pust9Config.fromJson(rawPust9.cast<String, Object?>())
          : Pust9Config.defaults,
      slots: slots,
      minSupportedVersion:
          json['minSupportedVersion'] as String? ??
          defaults.minSupportedVersion,
      latestVersion: json['latestVersion'] as String?,
      updateSizeMb: (json['updateSizeMb'] as num?)?.toDouble(),
      storeUrl: json['storeUrl'] as String?,
      supportEmail: json['supportEmail'] as String? ?? defaults.supportEmail,
      privacyUrl: json['privacyUrl'] as String?,
      termsUrl: json['termsUrl'] as String?,
      verifyBaseUrl: json['verifyBaseUrl'] as String?,
      shareBaseUrl: json['shareBaseUrl'] as String?,
      measurementReminderDays: json['measurementReminderDays'] is Map
          ? MeasurementReminderDays.fromJson(
              (json['measurementReminderDays'] as Map).cast<String, Object?>(),
            )
          : MeasurementReminderDays.defaults,
      ancContactWeeks: json['ancContactWeeks'] is List
          ? [
              for (final w in json['ancContactWeeks'] as List)
                if (w is num) w.toInt(),
            ]
          : null,
    );
  }
}

/// Fetches the raw config document from the backend; null when there is
/// no backend. Overridden in `bootstrap`.
final remoteConfigFetcherProvider =
    Provider<Future<Map<String, Object?>?> Function()?>((ref) => null);

/// Last fetched config, else bundled defaults; refreshed in the background
/// at start-up. A failed fetch keeps what the app already has.
class RemoteConfigController extends Notifier<AppRemoteConfig> {
  static const cacheKey = 'remote_config_cache';

  @override
  AppRemoteConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final fetch = ref.watch(remoteConfigFetcherProvider);
    if (fetch != null) Future.microtask(() => _refresh(fetch, prefs));
    final cached = prefs.getString(cacheKey);
    if (cached == null) return AppRemoteConfig.defaults;
    try {
      return AppRemoteConfig.fromJson(
        (jsonDecode(cached) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return AppRemoteConfig.defaults;
    }
  }

  Future<void> _refresh(
    Future<Map<String, Object?>?> Function() fetch,
    SharedPreferences prefs,
  ) async {
    try {
      final json = await fetch();
      if (json == null) return;
      state = AppRemoteConfig.fromJson(json);
      await prefs.setString(cacheKey, jsonEncode(json));
    } catch (_) {
      // Keep the cached or bundled config.
    }
  }
}

final remoteConfigControllerProvider =
    NotifierProvider<RemoteConfigController, AppRemoteConfig>(
      RemoteConfigController.new,
    );

/// Current remote configuration (override directly in tests).
final remoteConfigProvider = Provider<AppRemoteConfig>(
  (ref) => ref.watch(remoteConfigControllerProvider),
);
