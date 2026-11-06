/// Bangladeshi mobile operators, detected from the number prefix.
///
/// Numbers can be ported between operators, so detection is a hint used to
/// warn — never to block the subscription paths.
enum MobileOperator {
  grameenphone,
  robi,
  airtel,
  banglalink,
  teletalk,
  unknown;

  bool get supportsPust9 => this == robi || this == airtel;

  /// Accepts `+8801XXXXXXXXX`, `8801…`, `01…`, with spaces or dashes and
  /// Bangla or ASCII digits.
  static MobileOperator fromPhoneNumber(String phoneNumber) {
    final digits = StringBuffer();
    for (final rune in phoneNumber.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        digits.writeCharCode(rune);
      } else if (rune >= 0x09E6 && rune <= 0x09EF) {
        digits.writeCharCode(0x30 + rune - 0x09E6);
      }
    }
    var number = digits.toString();
    if (number.startsWith('880')) {
      number = number.substring(2);
    }
    if (number.length != 11 || !number.startsWith('01')) {
      return unknown;
    }
    return switch (number.substring(0, 3)) {
      '013' || '017' => grameenphone,
      '018' => robi,
      '016' => airtel,
      '014' || '019' => banglalink,
      '015' => teletalk,
      _ => unknown,
    };
  }
}
