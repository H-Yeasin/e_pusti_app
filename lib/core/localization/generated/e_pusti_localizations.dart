import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'e_pusti_localizations_bn.dart';
import 'e_pusti_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of EPustiGeneratedLocalizations
/// returned by `EPustiGeneratedLocalizations.of(context)`.
///
/// Applications need to include `EPustiGeneratedLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/e_pusti_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: EPustiGeneratedLocalizations.localizationsDelegates,
///   supportedLocales: EPustiGeneratedLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the EPustiGeneratedLocalizations.supportedLocales
/// property.
abstract class EPustiGeneratedLocalizations {
  EPustiGeneratedLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static EPustiGeneratedLocalizations of(BuildContext context) {
    return Localizations.of<EPustiGeneratedLocalizations>(
      context,
      EPustiGeneratedLocalizations,
    )!;
  }

  static const LocalizationsDelegate<EPustiGeneratedLocalizations> delegate =
      _EPustiGeneratedLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get languageSelectionTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @banglaName.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get banglaName;

  /// No description provided for @banglaLabel.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get banglaLabel;

  /// No description provided for @englishName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishName;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'ইংরেজি'**
  String get englishLabel;

  /// No description provided for @languageCanChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from Settings'**
  String get languageCanChangeLater;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @runningEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Running {environmentLabel}'**
  String runningEnvironment(String environmentLabel);

  /// No description provided for @homeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'e-Pushti'**
  String get homeAppTitle;

  /// No description provided for @homeSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily nutrition SMS - PUST9'**
  String get homeSmsTitle;

  /// No description provided for @homeSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'30-day course with daily tips delivered by SMS'**
  String get homeSmsSubtitle;

  /// No description provided for @homeSubscribeButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get homeSubscribeButton;

  /// No description provided for @homeWebinar.
  ///
  /// In en, this message translates to:
  /// **'Webinar'**
  String get homeWebinar;

  /// No description provided for @homeCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get homeCourse;

  /// No description provided for @homeDigiSkill.
  ///
  /// In en, this message translates to:
  /// **'Digi Skill'**
  String get homeDigiSkill;

  /// No description provided for @homeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get homeLibrary;

  /// No description provided for @homeBmiTitle.
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get homeBmiTitle;

  /// No description provided for @homeBmiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter height and weight for an instant result'**
  String get homeBmiSubtitle;

  /// No description provided for @homeViewNowButton.
  ///
  /// In en, this message translates to:
  /// **'View now'**
  String get homeViewNowButton;

  /// No description provided for @homeNutritionTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s nutrition tip'**
  String get homeNutritionTipTitle;

  /// No description provided for @homeNutritionTipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add colorful vegetables to family meals'**
  String get homeNutritionTipSubtitle;

  /// No description provided for @homeHealthCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Health check'**
  String get homeHealthCheckTitle;

  /// No description provided for @homeHealthCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record weight and height regularly'**
  String get homeHealthCheckSubtitle;
}

class _EPustiGeneratedLocalizationsDelegate
    extends LocalizationsDelegate<EPustiGeneratedLocalizations> {
  const _EPustiGeneratedLocalizationsDelegate();

  @override
  Future<EPustiGeneratedLocalizations> load(Locale locale) {
    return SynchronousFuture<EPustiGeneratedLocalizations>(
      lookupEPustiGeneratedLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_EPustiGeneratedLocalizationsDelegate old) => false;
}

EPustiGeneratedLocalizations lookupEPustiGeneratedLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return EPustiGeneratedLocalizationsBn();
    case 'en':
      return EPustiGeneratedLocalizationsEn();
  }

  throw FlutterError(
    'EPustiGeneratedLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
