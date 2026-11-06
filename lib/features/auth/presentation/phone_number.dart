import '../../../core/localization/digits.dart';

/// Bangladeshi mobile numbers as typed after the fixed `+880` prefix.
abstract final class PhoneNumber {
  /// Accepts `1712345678`, `01712345678`, `+8801712345678`, with spaces,
  /// dashes and Bangla digits. Returns E.164 (`+8801712345678`) or null.
  static String? normalize(String input) {
    var digits = normalizeDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('880')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!RegExp(r'^1[3-9][0-9]{8}$').hasMatch(digits)) return null;
    return '+880$digits';
  }

  /// `+8801712345678` → `+880 1712-345678`.
  static String display(String e164) {
    final local = e164.startsWith('+880') ? e164.substring(4) : e164;
    if (local.length != 10) return e164;
    return '+880 ${local.substring(0, 4)}-${local.substring(4)}';
  }
}
