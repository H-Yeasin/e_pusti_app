import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  /// Wireframe V4 says 60 days; the earlier app copy said 30 (decision A1).
  static const defaults = Pust9Config(
    courseDays: 60,
    ussdCode: '*213*02025#',
    shortcode: '21213',
    keyword: 'START PUST9',
  );

  final int courseDays;
  final String ussdCode;
  final String shortcode;
  final String keyword;

  factory Pust9Config.fromJson(Map<String, Object?> json) {
    const d = defaults;
    return Pust9Config(
      courseDays: (json['courseDays'] as num?)?.toInt() ?? d.courseDays,
      ussdCode: json['ussdCode'] as String? ?? d.ussdCode,
      shortcode: json['shortcode'] as String? ?? d.shortcode,
      keyword: json['keyword'] as String? ?? d.keyword,
    );
  }
}

class AppRemoteConfig {
  const AppRemoteConfig({
    required this.pust9,
    required this.slots,
    required this.minSupportedVersion,
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
    );
  }
}

/// Current remote configuration. Returns bundled defaults until a config
/// endpoint exists; override in tests or once fetched at startup.
final remoteConfigProvider = Provider<AppRemoteConfig>(
  (ref) => AppRemoteConfig.defaults,
);
