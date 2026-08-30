import 'package:flutter/widgets.dart';

import 'app_language.dart';

class EPustiLocalizations {
  const EPustiLocalizations(this.language);

  final AppLanguage language;

  static const delegate = _EPustiLocalizationsDelegate();

  static EPustiLocalizations of(BuildContext context) {
    final localizations = Localizations.of<EPustiLocalizations>(
      context,
      EPustiLocalizations,
    );

    assert(localizations != null, 'EPustiLocalizations is missing.');
    return localizations!;
  }

  bool get isBangla => language == AppLanguage.bangla;

  String get languageSelectionTitle => isBangla
      ? 'ভাষা নির্বাচন করুন'
      : 'Select language';

  String get chooseLanguage => isBangla
      ? 'আপনার ভাষা বেছে নিন'
      : 'Choose your language';

  String get banglaName => 'বাংলা';

  String get banglaLabel => 'Bangla';

  String get englishName => 'English';

  String get englishLabel => 'ইংরেজি';

  String get languageCanChangeLater => isBangla
      ? 'সেটিংস থেকে যেকোনো সময় পরিবর্তন করা যাবে'
      : 'You can change this anytime from Settings';

  String get continueLabel => isBangla
      ? 'চালিয়ে যান'
      : 'Continue';

  String runningEnvironment(String environmentLabel) {
    return isBangla
        ? '$environmentLabel পরিবেশে চলছে'
        : 'Running $environmentLabel';
  }
}

extension EPustiLocalizationsX on BuildContext {
  EPustiLocalizations get l10n => EPustiLocalizations.of(this);
}

class _EPustiLocalizationsDelegate
    extends LocalizationsDelegate<EPustiLocalizations> {
  const _EPustiLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any(
      (language) => language.code == locale.languageCode,
    );
  }

  @override
  Future<EPustiLocalizations> load(Locale locale) async {
    return EPustiLocalizations(AppLanguage.fromLocale(locale));
  }

  @override
  bool shouldReload(_EPustiLocalizationsDelegate old) => false;
}




