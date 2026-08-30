import 'package:flutter/widgets.dart';

enum AppLanguage {
  bangla('bn', Locale('bn')),
  english('en', Locale('en'));

  const AppLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.bangla,
    );
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}
