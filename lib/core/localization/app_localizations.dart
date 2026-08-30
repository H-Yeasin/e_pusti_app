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
      ? '\u{9AD}\u{9BE}\u{9B7}\u{9BE} \u{9A8}\u{9BF}\u{9B0}\u{9CD}\u{9AC}\u{9BE}\u{99A}\u{9A8} \u{995}\u{9B0}\u{9C1}\u{9A8}'
      : 'Select language';

  String get chooseLanguage => isBangla
      ? '\u{986}\u{9AA}\u{9A8}\u{9BE}\u{9B0} \u{9AD}\u{9BE}\u{9B7}\u{9BE} \u{9AC}\u{9C7}\u{99B}\u{9C7} \u{9A8}\u{9BF}\u{9A8}'
      : 'Choose your language';

  String get banglaName => '\u{9AC}\u{9BE}\u{982}\u{9B2}\u{9BE}';

  String get banglaLabel => 'Bangla';

  String get englishName => 'English';

  String get englishLabel => '\u{987}\u{982}\u{9B0}\u{9C7}\u{99C}\u{9BF}';

  String get languageCanChangeLater => isBangla
      ? '\u{9B8}\u{9C7}\u{99F}\u{9BF}\u{982}\u{9B8} \u{9A5}\u{9C7}\u{995}\u{9C7} \u{9AF}\u{9C7}\u{995}\u{9CB}\u{9A8}\u{9CB} \u{9B8}\u{9AE}\u{9DF}\u{9BC} \u{9AA}\u{9B0}\u{9BF}\u{9AC}\u{9B0}\u{9CD}\u{9A4}\u{9A8} \u{995}\u{9B0}\u{9BE} \u{9AF}\u{9BE}\u{9AC}\u{9C7}'
      : 'You can change this anytime from Settings';

  String get continueLabel => isBangla
      ? '\u{99A}\u{9BE}\u{9B2}\u{9BF}\u{9DF}\u{9C7} \u{9AF}\u{9BE}\u{9A8}'
      : 'Continue';

  String runningEnvironment(String environmentLabel) {
    return isBangla
        ? '$environmentLabel \u{9AA}\u{9B0}\u{9BF}\u{9AC}\u{9C7}\u{9B6}\u{9C7} \u{99A}\u{9B2}\u{99B}\u{9C7}'
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

