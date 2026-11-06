import 'package:flutter/widgets.dart';

const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Replaces ASCII digits with Bangla digits when [locale] is Bangla.
String localizeDigits(String value, Locale locale) {
  if (locale.languageCode != 'bn') {
    return value;
  }
  final buffer = StringBuffer();
  for (final unit in value.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      buffer.write(_banglaDigits[unit - 0x30]);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Converts Bangla digits to ASCII so user input can be parsed.
String normalizeDigits(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0x09E6 && rune <= 0x09EF) {
      buffer.writeCharCode(0x30 + rune - 0x09E6);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Parses a decimal number typed with Bangla or ASCII digits.
double? parseLocalizedNumber(String value) {
  final cleaned = normalizeDigits(value.trim()).replaceAll(',', '.');
  if (cleaned.isEmpty) {
    return null;
  }
  return double.tryParse(cleaned);
}

extension LocalizedDigitsX on BuildContext {
  String digits(Object value) =>
      localizeDigits('$value', Localizations.localeOf(this));
}
