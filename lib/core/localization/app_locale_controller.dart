import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'app_language_store.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController(this._store) : _language = _store.readLanguage();

  final AppLanguageStore _store;
  AppLanguage? _language;

  bool get hasChosenLanguage => _language != null;

  AppLanguage get language => _language ?? AppLanguage.bangla;

  Locale get locale => language.locale;

  Future<void> chooseLanguage(AppLanguage language) async {
    await _store.saveLanguage(language);
    _language = language;
    notifyListeners();
  }

  String? languageCodeForAccountMigration() {
    return _store.languageCodeForAccountMigration();
  }
}

