import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

class AppLanguageStore {
  AppLanguageStore(this._preferences);

  static const languageCodeKey = 'app_language_code';

  final SharedPreferences _preferences;

  AppLanguage? readLanguage() {
    final code = _preferences.getString(languageCodeKey);
    if (code == null) {
      return null;
    }

    return AppLanguage.fromCode(code);
  }

  Future<void> saveLanguage(AppLanguage language) {
    return _preferences.setString(languageCodeKey, language.code);
  }

  String? languageCodeForAccountMigration() {
    return _preferences.getString(languageCodeKey);
  }
}
