import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'digits.dart';

/// Event date with weekday, e.g. "Thu, 12 September · 10:00 AM" /
/// "বৃহস্পতিবার, ১২ সেপ্টেম্বর · ১০:০০ AM".
String formatEventDateTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context);
  final tag = locale.toLanguageTag();
  final date = DateFormat('EEE, d MMMM', tag).format(value);
  final time = DateFormat.jm(tag).format(value);
  return localizeDigits('$date · $time', locale);
}

/// Short date for past items, e.g. "7 August".
String formatShortDate(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context);
  return localizeDigits(
    DateFormat('d MMMM', locale.toLanguageTag()).format(value),
    locale,
  );
}
