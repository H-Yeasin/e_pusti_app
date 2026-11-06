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

extension LocalizedDigitsX on BuildContext {
  String digits(Object value) =>
      localizeDigits('$value', Localizations.localeOf(this));
}
