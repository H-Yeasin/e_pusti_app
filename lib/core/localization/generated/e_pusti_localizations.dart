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
  /// **'Daily nutrition SMS — PUST9'**
  String get homeSmsTitle;

  /// No description provided for @homeSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{days}-day course, daily tips straight to your SMS'**
  String homeSmsSubtitle(String days);

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
  /// **'Digi Skills'**
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

  /// No description provided for @menuHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menuHome;

  /// No description provided for @menuFamilyProfile.
  ///
  /// In en, this message translates to:
  /// **'Family & profile'**
  String get menuFamilyProfile;

  /// No description provided for @menuCertificates.
  ///
  /// In en, this message translates to:
  /// **'My certificates'**
  String get menuCertificates;

  /// No description provided for @menuRegistrations.
  ///
  /// In en, this message translates to:
  /// **'My registrations'**
  String get menuRegistrations;

  /// No description provided for @menuNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get menuNotifications;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get menuAbout;

  /// No description provided for @menuSupport.
  ///
  /// In en, this message translates to:
  /// **'Support / Feedback'**
  String get menuSupport;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in →'**
  String get menuLogin;

  /// No description provided for @menuLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get menuLockedHint;

  /// No description provided for @menuVersion.
  ///
  /// In en, this message translates to:
  /// **'e-Pushti · version {version}'**
  String menuVersion(String version);

  /// No description provided for @loginPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get loginPromptTitle;

  /// No description provided for @loginPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to use this. You\'ll come back to exactly where you were.'**
  String get loginPromptBody;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginAction;

  /// No description provided for @notNowAction.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNowAction;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginTitle;

  /// No description provided for @pust9Title.
  ///
  /// In en, this message translates to:
  /// **'PUST9 subscription'**
  String get pust9Title;

  /// No description provided for @academyTitle.
  ///
  /// In en, this message translates to:
  /// **'e-Pushti Academy'**
  String get academyTitle;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This section is being built.'**
  String get comingSoonBody;

  /// No description provided for @backToHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeAction;

  /// No description provided for @devSimulateLogin.
  ///
  /// In en, this message translates to:
  /// **'Simulate login (dev only)'**
  String get devSimulateLogin;

  /// No description provided for @devCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Component catalog'**
  String get devCatalogTitle;

  /// No description provided for @partnerContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner content'**
  String get partnerContentLabel;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @copiedToast.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedToast;

  /// No description provided for @cannotOpenAppToast.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the app on this phone'**
  String get cannotOpenAppToast;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineTitle;

  /// No description provided for @offlineAvailableIntro.
  ///
  /// In en, this message translates to:
  /// **'Available without a connection —'**
  String get offlineAvailableIntro;

  /// No description provided for @offlineDownloadedDocs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded documents · {count}'**
  String offlineDownloadedDocs(String count);

  /// No description provided for @offlineReadChapters.
  ///
  /// In en, this message translates to:
  /// **'Text of chapters you\'ve read'**
  String get offlineReadChapters;

  /// No description provided for @offlineBmi.
  ///
  /// In en, this message translates to:
  /// **'BMI calculator'**
  String get offlineBmi;

  /// No description provided for @offlineVideoWebinar.
  ///
  /// In en, this message translates to:
  /// **'Videos and webinars'**
  String get offlineVideoWebinar;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Try again when you\'re back online.'**
  String get offlineBody;

  /// No description provided for @slowConnection.
  ///
  /// In en, this message translates to:
  /// **'Slow connection — this is taking a while'**
  String get slowConnection;

  /// No description provided for @serverErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get serverErrorTitle;

  /// No description provided for @serverErrorBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s not your fault. Our server is having a temporary problem. Please try again shortly.'**
  String get serverErrorBody;

  /// No description provided for @reportToSupport.
  ///
  /// In en, this message translates to:
  /// **'Tell support'**
  String get reportToSupport;

  /// No description provided for @contentServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch the content'**
  String get contentServerTitle;

  /// No description provided for @contentServerBody.
  ///
  /// In en, this message translates to:
  /// **'This content comes from our content server, which can\'t be reached right now. Your progress is safely saved.'**
  String get contentServerBody;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update the app'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Please update to the new version to continue.'**
  String get updateBody;

  /// No description provided for @updateVersionSize.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {size} MB'**
  String updateVersionSize(String version, String size);

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @updateRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'The app can\'t be used without updating'**
  String get updateRequiredNote;

  /// No description provided for @pust9Headline.
  ///
  /// In en, this message translates to:
  /// **'{days}-day nutrition curriculum'**
  String pust9Headline(String days);

  /// No description provided for @pust9Tagline.
  ///
  /// In en, this message translates to:
  /// **'One nutrition tip a day, straight to your phone'**
  String get pust9Tagline;

  /// No description provided for @pust9OperatorNote.
  ///
  /// In en, this message translates to:
  /// **'Available only for Robi and Airtel customers'**
  String get pust9OperatorNote;

  /// No description provided for @pust9ChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get pust9ChargeLabel;

  /// No description provided for @pust9Charge.
  ///
  /// In en, this message translates to:
  /// **'৳{price}/day + VAT, supplementary duty and surcharge apply'**
  String pust9Charge(String price);

  /// No description provided for @pust9PathATitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe by dialling'**
  String get pust9PathATitle;

  /// No description provided for @pust9DialAction.
  ///
  /// In en, this message translates to:
  /// **'Dial'**
  String get pust9DialAction;

  /// No description provided for @pust9PathAStep1.
  ///
  /// In en, this message translates to:
  /// **'Dial the code above'**
  String get pust9PathAStep1;

  /// No description provided for @pust9PathAStep2.
  ///
  /// In en, this message translates to:
  /// **'When the pop-up menu appears, type 1 and Reply/Send'**
  String get pust9PathAStep2;

  /// No description provided for @pust9PathAStep3.
  ///
  /// In en, this message translates to:
  /// **'The service starts when you get the confirmation SMS'**
  String get pust9PathAStep3;

  /// No description provided for @pust9PathBTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe by SMS'**
  String get pust9PathBTitle;

  /// No description provided for @pust9ShortcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortcode'**
  String get pust9ShortcodeLabel;

  /// No description provided for @pust9MessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get pust9MessageLabel;

  /// No description provided for @pust9OpenSmsAction.
  ///
  /// In en, this message translates to:
  /// **'Open SMS app'**
  String get pust9OpenSmsAction;

  /// No description provided for @pust9PathBStep1.
  ///
  /// In en, this message translates to:
  /// **'Send the message above to the shortcode'**
  String get pust9PathBStep1;

  /// No description provided for @pust9PathBStep2.
  ///
  /// In en, this message translates to:
  /// **'Reply 1 to the message you get back'**
  String get pust9PathBStep2;

  /// No description provided for @pust9SupportLink.
  ///
  /// In en, this message translates to:
  /// **'Having trouble? Tell support'**
  String get pust9SupportLink;

  /// No description provided for @pust9NotEligible.
  ///
  /// In en, this message translates to:
  /// **'Your number doesn\'t look like Robi or Airtel. PUST9 runs only on these two operators.'**
  String get pust9NotEligible;

  /// No description provided for @pust9StillOpen.
  ///
  /// In en, this message translates to:
  /// **'But all of the app\'s content is open to you —'**
  String get pust9StillOpen;

  /// No description provided for @bmiAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'You can calculate without logging in. Saving needs a login.'**
  String get bmiAnonymousNote;

  /// No description provided for @bmiHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bmiHeight;

  /// No description provided for @bmiWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bmiWeight;

  /// No description provided for @bmiAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get bmiAge;

  /// No description provided for @bmiSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get bmiSex;

  /// No description provided for @bmiUnitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get bmiUnitCm;

  /// No description provided for @bmiUnitFeetInches.
  ///
  /// In en, this message translates to:
  /// **'ft + in'**
  String get bmiUnitFeetInches;

  /// No description provided for @bmiFeet.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get bmiFeet;

  /// No description provided for @bmiInches.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get bmiInches;

  /// No description provided for @bmiKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get bmiKg;

  /// No description provided for @bmiAddAgeOptional.
  ///
  /// In en, this message translates to:
  /// **'Add age (optional)'**
  String get bmiAddAgeOptional;

  /// No description provided for @bmiAgeValue.
  ///
  /// In en, this message translates to:
  /// **'{years} y {months} m'**
  String bmiAgeValue(String years, String months);

  /// No description provided for @bmiAgeYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get bmiAgeYears;

  /// No description provided for @bmiAgeMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get bmiAgeMonths;

  /// No description provided for @bmiAgeClear.
  ///
  /// In en, this message translates to:
  /// **'Remove age'**
  String get bmiAgeClear;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @bmiNoAgeNote.
  ///
  /// In en, this message translates to:
  /// **'Without an age the result uses the adult standard — that does not apply to children and teenagers.'**
  String get bmiNoAgeNote;

  /// No description provided for @bmiSexNote.
  ///
  /// In en, this message translates to:
  /// **'Under 19, BMI is assessed on separate growth standards for boys and girls. With \"Other\" an age-based result can\'t be shown.'**
  String get bmiSexNote;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sexOther;

  /// No description provided for @childBoy.
  ///
  /// In en, this message translates to:
  /// **'boy'**
  String get childBoy;

  /// No description provided for @childGirl.
  ///
  /// In en, this message translates to:
  /// **'girl'**
  String get childGirl;

  /// No description provided for @bmiShowResult.
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get bmiShowResult;

  /// No description provided for @bmiCheckHeight.
  ///
  /// In en, this message translates to:
  /// **'Check the height'**
  String get bmiCheckHeight;

  /// No description provided for @bmiCheckWeight.
  ///
  /// In en, this message translates to:
  /// **'Check the weight'**
  String get bmiCheckWeight;

  /// No description provided for @bmiResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get bmiResultTitle;

  /// No description provided for @bmiAdultUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiAdultUnderweight;

  /// No description provided for @bmiAdultNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiAdultNormal;

  /// No description provided for @bmiAdultOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiAdultOverweight;

  /// No description provided for @bmiAdultObesity.
  ///
  /// In en, this message translates to:
  /// **'Obesity'**
  String get bmiAdultObesity;

  /// No description provided for @bmiAdultUnderweightBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight is below the healthy range for your height.'**
  String get bmiAdultUnderweightBody;

  /// No description provided for @bmiAdultNormalBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight is in the healthy range for your height.'**
  String get bmiAdultNormalBody;

  /// No description provided for @bmiAdultOverweightBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight is above the healthy range for your height.'**
  String get bmiAdultOverweightBody;

  /// No description provided for @bmiAdultObesityBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight is well above the healthy range for your height.'**
  String get bmiAdultObesityBody;

  /// No description provided for @bmiAdultStandard.
  ///
  /// In en, this message translates to:
  /// **'Adult standard (WHO)'**
  String get bmiAdultStandard;

  /// No description provided for @bmiBandUnder.
  ///
  /// In en, this message translates to:
  /// **'Below 18.5'**
  String get bmiBandUnder;

  /// No description provided for @bmiBandNormal.
  ///
  /// In en, this message translates to:
  /// **'18.5 – 24.9'**
  String get bmiBandNormal;

  /// No description provided for @bmiBandOver.
  ///
  /// In en, this message translates to:
  /// **'25.0 – 29.9'**
  String get bmiBandOver;

  /// No description provided for @bmiBandObese.
  ///
  /// In en, this message translates to:
  /// **'30.0 or more'**
  String get bmiBandObese;

  /// No description provided for @bmiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is not a diagnosis. If you\'re worried, talk to a doctor.'**
  String get bmiDisclaimer;

  /// No description provided for @bmiChildDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is not a diagnosis. If you\'re worried about a child\'s growth, talk to a doctor.'**
  String get bmiChildDisclaimer;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @bmiSaveDataAction.
  ///
  /// In en, this message translates to:
  /// **'Save the data'**
  String get bmiSaveDataAction;

  /// No description provided for @bmiSavePromptBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to save measurements and follow changes over time. You\'ll come back to this result.'**
  String get bmiSavePromptBody;

  /// No description provided for @bmiPersonAge.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String bmiPersonAge(String age);

  /// No description provided for @bmiChildStandardNote.
  ///
  /// In en, this message translates to:
  /// **'Results for children and teenagers use growth standards by age and sex — adult values don\'t apply here.'**
  String get bmiChildStandardNote;

  /// No description provided for @bmiChildPosition.
  ///
  /// In en, this message translates to:
  /// **'Position for age'**
  String get bmiChildPosition;

  /// No description provided for @bmiChildThinness.
  ///
  /// In en, this message translates to:
  /// **'Thinness'**
  String get bmiChildThinness;

  /// No description provided for @bmiChildSevereThinness.
  ///
  /// In en, this message translates to:
  /// **'Severe thinness'**
  String get bmiChildSevereThinness;

  /// No description provided for @bmiChildNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiChildNormal;

  /// No description provided for @bmiChildOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiChildOverweight;

  /// No description provided for @bmiChildObesity.
  ///
  /// In en, this message translates to:
  /// **'Obesity'**
  String get bmiChildObesity;

  /// No description provided for @bmiChildCompare.
  ///
  /// In en, this message translates to:
  /// **'Compared with {group} of the same age, the weight is: {category}.'**
  String bmiChildCompare(String group, String category);

  /// No description provided for @bmiUnderFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'BMI doesn\'t apply'**
  String get bmiUnderFiveTitle;

  /// No description provided for @bmiUnderFiveBody.
  ///
  /// In en, this message translates to:
  /// **'Nutrition status of children under 5 isn\'t measured with BMI. At this age, weight-for-height and the growth pattern are used.'**
  String get bmiUnderFiveBody;

  /// No description provided for @bmiUnderFiveSave.
  ///
  /// In en, this message translates to:
  /// **'If you save the data, the child\'s growth pattern can be followed over time.'**
  String get bmiUnderFiveSave;

  /// No description provided for @bmiUnderFiveAdvice.
  ///
  /// In en, this message translates to:
  /// **'To know the child\'s nutrition status, visit the nearest health centre or a doctor.'**
  String get bmiUnderFiveAdvice;

  /// No description provided for @bmiNoReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'An age-based result can\'t be shown'**
  String get bmiNoReferenceTitle;

  /// No description provided for @bmiNoReferenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{age} years · Sex: Other'**
  String bmiNoReferenceSubtitle(String age);

  /// No description provided for @bmiNoReferenceBody.
  ///
  /// In en, this message translates to:
  /// **'Under 19, BMI is assessed on separate growth standards for boys and girls. There is no internationally recognised standard for \"Other\".'**
  String get bmiNoReferenceBody;

  /// No description provided for @bmiNoReferenceWhy.
  ///
  /// In en, this message translates to:
  /// **'We think showing nothing is better than showing a wrong result.'**
  String get bmiNoReferenceWhy;

  /// No description provided for @bmiNoReferenceSave.
  ///
  /// In en, this message translates to:
  /// **'Height and weight can still be saved and used when talking to a doctor.'**
  String get bmiNoReferenceSave;

  /// No description provided for @bmiNoAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'On the adult standard'**
  String get bmiNoAgeLabel;

  /// No description provided for @bmiNoAgeGiven.
  ///
  /// In en, this message translates to:
  /// **'No age given'**
  String get bmiNoAgeGiven;

  /// No description provided for @bmiNoAgeBody.
  ///
  /// In en, this message translates to:
  /// **'This result uses the adult standard. It does not apply if the person is under 19.'**
  String get bmiNoAgeBody;

  /// No description provided for @bmiNoAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Add age and sex for an accurate result.'**
  String get bmiNoAgeHint;

  /// No description provided for @bmiAddAgeAction.
  ///
  /// In en, this message translates to:
  /// **'Add age'**
  String get bmiAddAgeAction;

  /// No description provided for @bmiChildTablesMissing.
  ///
  /// In en, this message translates to:
  /// **'The age-based reference for children isn\'t available in this version yet, so no classification is shown.'**
  String get bmiChildTablesMissing;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(String minutes);

  /// No description provided for @chapterNumbered.
  ///
  /// In en, this message translates to:
  /// **'{number}. {title}'**
  String chapterNumbered(String number, String title);

  /// No description provided for @coursesLoggedOutNote.
  ///
  /// In en, this message translates to:
  /// **'All chapters can be read without logging in. Saving progress and quizzes need a login.'**
  String get coursesLoggedOutNote;

  /// No description provided for @videoDataNote.
  ///
  /// In en, this message translates to:
  /// **'Playing the video uses about {size} MB of data'**
  String videoDataNote(String size);

  /// No description provided for @videoWifiOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Video is set to play on Wi-Fi only. Change this in Settings.'**
  String get videoWifiOnlyNote;

  /// No description provided for @videoFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the video'**
  String get videoFailedTitle;

  /// No description provided for @videoFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The video can be watched when the connection is back. The text is fine to read.'**
  String get videoFailedBody;

  /// No description provided for @takeQuizAction.
  ///
  /// In en, this message translates to:
  /// **'Take the quiz'**
  String get takeQuizAction;

  /// No description provided for @quizLoginBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to take the quiz and get a certificate. You\'ll come back to where you were.'**
  String get quizLoginBody;

  /// No description provided for @libraryAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get libraryAllCategories;

  /// No description provided for @libraryDocCount.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String libraryDocCount(String count);

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents…'**
  String get librarySearchHint;

  /// No description provided for @libraryNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get libraryNoResultsTitle;

  /// No description provided for @libraryNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched \"{query}\". Try another word, or see all categories.'**
  String libraryNoResultsBody(String query);

  /// No description provided for @librarySeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all documents'**
  String get librarySeeAll;

  /// No description provided for @docMeta.
  ///
  /// In en, this message translates to:
  /// **'{size} MB · {pages} pages'**
  String docMeta(String size, String pages);

  /// No description provided for @docDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get docDownloaded;

  /// No description provided for @docWaitingWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi'**
  String get docWaitingWifi;

  /// No description provided for @docPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to download'**
  String get docPending;

  /// No description provided for @downloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadAction;

  /// No description provided for @docLargeNote.
  ///
  /// In en, this message translates to:
  /// **'This document is {size} MB. Opening it on mobile data will cost data.'**
  String docLargeNote(String size);

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @readLaterWifi.
  ///
  /// In en, this message translates to:
  /// **'Read later on Wi-Fi'**
  String get readLaterWifi;

  /// No description provided for @queuedForWifiToast.
  ///
  /// In en, this message translates to:
  /// **'Added to downloads — it will download on Wi-Fi'**
  String get queuedForWifiToast;

  /// No description provided for @queuedToast.
  ///
  /// In en, this message translates to:
  /// **'Added to downloads'**
  String get queuedToast;

  /// No description provided for @docPreviewUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview not available yet'**
  String get docPreviewUnavailableTitle;

  /// No description provided for @docPreviewUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This document\'s file isn\'t on the content server yet.'**
  String get docPreviewUnavailableBody;

  /// No description provided for @pageCounter.
  ///
  /// In en, this message translates to:
  /// **'{page} / {total}'**
  String pageCounter(String page, String total);

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded files'**
  String get downloadsTitle;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Documents you download or save for Wi-Fi appear here and can be read offline.'**
  String get downloadsEmptyBody;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @webinarUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get webinarUpcoming;

  /// No description provided for @webinarPast.
  ///
  /// In en, this message translates to:
  /// **'Past events'**
  String get webinarPast;

  /// No description provided for @webinarSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} seats left'**
  String webinarSeatsLeft(String count);

  /// No description provided for @webinarOnlySeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} seats left'**
  String webinarOnlySeatsLeft(String count);

  /// No description provided for @webinarSeatsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{left} seats left · {total} total'**
  String webinarSeatsOfTotal(String left, String total);

  /// No description provided for @webinarReserveSeat.
  ///
  /// In en, this message translates to:
  /// **'Reserve a seat'**
  String get webinarReserveSeat;

  /// No description provided for @webinarCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get webinarCompleted;

  /// No description provided for @webinarWatchRecording.
  ///
  /// In en, this message translates to:
  /// **'Watch recording'**
  String get webinarWatchRecording;

  /// No description provided for @webinarNoRecording.
  ///
  /// In en, this message translates to:
  /// **'No recording'**
  String get webinarNoRecording;

  /// No description provided for @webinarNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'There are no upcoming webinars right now. You\'ll get a notification when a new event is announced.'**
  String get webinarNoUpcoming;

  /// No description provided for @webinarFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get webinarFull;

  /// No description provided for @webinarFullBody.
  ///
  /// In en, this message translates to:
  /// **'All seats for this session are taken. We\'ll let you know when the recording is published.'**
  String get webinarFullBody;

  /// No description provided for @webinarNotifyRecording.
  ///
  /// In en, this message translates to:
  /// **'Tell me about the recording'**
  String get webinarNotifyRecording;

  /// No description provided for @webinarSeeOthers.
  ///
  /// In en, this message translates to:
  /// **'See other webinars'**
  String get webinarSeeOthers;

  /// No description provided for @webinarMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String webinarMinutes(String minutes);

  /// No description provided for @webinarRegisterLoginBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to reserve a seat. You\'ll come back to this webinar.'**
  String get webinarRegisterLoginBody;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'e-Pushti is an initiative to bring reliable nutrition information to families in Bangladesh. Content follows government and internationally recognised guidelines.'**
  String get aboutBody;

  /// No description provided for @aboutPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get aboutPartners;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @supportScope.
  ///
  /// In en, this message translates to:
  /// **'This channel helps with using the app. Personal health or medical advice is not given here — please contact a doctor for that.'**
  String get supportScope;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubject;

  /// No description provided for @supportSubjectSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription problem'**
  String get supportSubjectSubscription;

  /// No description provided for @supportSubjectApp.
  ///
  /// In en, this message translates to:
  /// **'Using the app'**
  String get supportSubjectApp;

  /// No description provided for @supportSubjectContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get supportSubjectContent;

  /// No description provided for @supportSubjectOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportSubjectOther;

  /// No description provided for @supportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get supportDetails;

  /// No description provided for @supportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem…'**
  String get supportDetailsHint;

  /// No description provided for @supportSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get supportSend;

  /// No description provided for @supportSendNote.
  ///
  /// In en, this message translates to:
  /// **'Opens your email app with the message ready to send.'**
  String get supportSendNote;

  /// No description provided for @supportDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct contact'**
  String get supportDirect;

  /// No description provided for @supportHours.
  ///
  /// In en, this message translates to:
  /// **'Sun–Thu, 10 am – 5 pm'**
  String get supportHours;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsVideoWifi.
  ///
  /// In en, this message translates to:
  /// **'Video on Wi-Fi only'**
  String get settingsVideoWifi;

  /// No description provided for @settingsVideoWifiSub.
  ///
  /// In en, this message translates to:
  /// **'Saves mobile data'**
  String get settingsVideoWifiSub;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @offlineNotNow.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get offlineNotNow;

  /// No description provided for @phoneHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get phoneHeading;

  /// No description provided for @phoneReason.
  ///
  /// In en, this message translates to:
  /// **'Needed to save progress, certificates and webinar registrations'**
  String get phoneReason;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'1XXX-XXXXXX'**
  String get phoneHint;

  /// No description provided for @phoneOperatorNote.
  ///
  /// In en, this message translates to:
  /// **'Any operator\'s number works for the app. Only the PUST9 subscription needs Robi or Airtel.'**
  String get phoneOperatorNote;

  /// No description provided for @phoneTermsNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept the privacy policy and terms.'**
  String get phoneTermsNote;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Bangladeshi mobile number'**
  String get phoneInvalid;

  /// No description provided for @sendCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCodeAction;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to this number'**
  String get otpSentTo;

  /// No description provided for @changeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code — {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpNoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'If the code doesn\'t arrive, check your network connection'**
  String get otpNoCodeHint;

  /// No description provided for @otpDelayedHint.
  ///
  /// In en, this message translates to:
  /// **'Code taking long? Check the number is right, or use another number.'**
  String get otpDelayedHint;

  /// No description provided for @otpWrong.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right — try again'**
  String get otpWrong;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired — get a new one'**
  String get otpExpired;

  /// No description provided for @otpTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while and try again.'**
  String get otpTooMany;

  /// No description provided for @otpSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'The code couldn\'t be sent. Please try again shortly.'**
  String get otpSmsFailed;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Login isn\'t available in this version yet. Everything else in the app is open to you.'**
  String get authUnavailable;

  /// No description provided for @devOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Development build: use code {code}'**
  String devOtpHint(String code);

  /// No description provided for @changeNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumberTitle;

  /// No description provided for @changeNumberHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your new mobile number'**
  String get changeNumberHeading;

  /// No description provided for @changeNumberBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, family, records and certificates move to the new number.'**
  String get changeNumberBody;

  /// No description provided for @phoneInUse.
  ///
  /// In en, this message translates to:
  /// **'This number is already used by another account.'**
  String get phoneInUse;

  /// No description provided for @numberChangedToast.
  ///
  /// In en, this message translates to:
  /// **'Number changed'**
  String get numberChangedToast;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get consentTitle;

  /// No description provided for @consentHeading.
  ///
  /// In en, this message translates to:
  /// **'How your information is used'**
  String get consentHeading;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'The information you give is used only to give you suitable nutrition advice and, without names, in BIID Foundation\'s aggregate reports. No information is sold.'**
  String get consentBody;

  /// No description provided for @consentTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the privacy policy and terms'**
  String get consentTerms;

  /// No description provided for @consentHealth.
  ///
  /// In en, this message translates to:
  /// **'I consent to storing health information (height, weight)'**
  String get consentHealth;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get consentContinue;

  /// No description provided for @consentSkipNote.
  ///
  /// In en, this message translates to:
  /// **'Without consent you can still use courses, the library and webinars'**
  String get consentSkipNote;

  /// No description provided for @privacyCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyCentreTitle;

  /// No description provided for @privacyTermsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Terms accepted on {date}'**
  String privacyTermsAccepted(String date);

  /// No description provided for @privacyHealthOn.
  ///
  /// In en, this message translates to:
  /// **'Health data storage: on'**
  String get privacyHealthOn;

  /// No description provided for @privacyHealthOff.
  ///
  /// In en, this message translates to:
  /// **'Health data storage: off'**
  String get privacyHealthOff;

  /// No description provided for @privacyWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw health data consent'**
  String get privacyWithdraw;

  /// No description provided for @privacyWithdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent? All saved height, weight and BMI records will be deleted. This can\'t be undone.'**
  String get privacyWithdrawConfirm;

  /// No description provided for @privacyGiveConsent.
  ///
  /// In en, this message translates to:
  /// **'Give consent'**
  String get privacyGiveConsent;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @profileAddName.
  ///
  /// In en, this message translates to:
  /// **'Add your details'**
  String get profileAddName;

  /// No description provided for @familyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add family members'**
  String get familyAddTitle;

  /// No description provided for @familyAddBody.
  ///
  /// In en, this message translates to:
  /// **'Add your children, spouse or parents to see age-appropriate nutrition advice and BMI for them too.'**
  String get familyAddBody;

  /// No description provided for @familyAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get familyAddAction;

  /// No description provided for @familyCount.
  ///
  /// In en, this message translates to:
  /// **'Your family · {count}'**
  String familyCount(String count);

  /// No description provided for @consentNeededBanner.
  ///
  /// In en, this message translates to:
  /// **'Give consent to save profile and health information.'**
  String get consentNeededBanner;

  /// No description provided for @ageYearsMonths.
  ///
  /// In en, this message translates to:
  /// **'{years} y {months} m'**
  String ageYearsMonths(String years, String months);

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String ageYears(String years);

  /// No description provided for @fieldNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get fieldNameOptional;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldNameHint;

  /// No description provided for @fieldRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get fieldRelationship;

  /// No description provided for @fieldDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldDob;

  /// No description provided for @fieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get fieldDistrict;

  /// No description provided for @fieldOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get fieldOccupation;

  /// No description provided for @fieldPregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get fieldPregnant;

  /// No description provided for @fieldBreastfeeding.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding'**
  String get fieldBreastfeeding;

  /// No description provided for @fieldInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get fieldInterests;

  /// No description provided for @fieldInterestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Interests (optional)'**
  String get fieldInterestsOptional;

  /// No description provided for @fieldChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get fieldChoose;

  /// No description provided for @fieldSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String fieldSelectedCount(String count);

  /// No description provided for @dobReason.
  ///
  /// In en, this message translates to:
  /// **'Date of birth and sex are needed for age-appropriate BMI'**
  String get dobReason;

  /// No description provided for @dobSelectedAge.
  ///
  /// In en, this message translates to:
  /// **'Selected age: {age}'**
  String dobSelectedAge(String age);

  /// No description provided for @removeMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMemberAction;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this member? Their saved measurements will also be deleted.'**
  String get removeMemberConfirm;

  /// No description provided for @savedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedToast;

  /// No description provided for @pickDistrictTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose district'**
  String get pickDistrictTitle;

  /// No description provided for @pickDistrictSearch.
  ///
  /// In en, this message translates to:
  /// **'Search districts…'**
  String get pickDistrictSearch;

  /// No description provided for @pickOccupationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose occupation'**
  String get pickOccupationTitle;

  /// No description provided for @pickRelationshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose relationship'**
  String get pickRelationshipTitle;

  /// No description provided for @pickSexTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose sex'**
  String get pickSexTitle;

  /// No description provided for @pickInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'You can choose more than one'**
  String get pickInterestsHint;

  /// No description provided for @pickInterestsDone.
  ///
  /// In en, this message translates to:
  /// **'Done · {count} selected'**
  String pickInterestsDone(String count);

  /// No description provided for @divisionDhaka.
  ///
  /// In en, this message translates to:
  /// **'Dhaka Division'**
  String get divisionDhaka;

  /// No description provided for @divisionChattogram.
  ///
  /// In en, this message translates to:
  /// **'Chattogram Division'**
  String get divisionChattogram;

  /// No description provided for @divisionRajshahi.
  ///
  /// In en, this message translates to:
  /// **'Rajshahi Division'**
  String get divisionRajshahi;

  /// No description provided for @divisionKhulna.
  ///
  /// In en, this message translates to:
  /// **'Khulna Division'**
  String get divisionKhulna;

  /// No description provided for @divisionBarishal.
  ///
  /// In en, this message translates to:
  /// **'Barishal Division'**
  String get divisionBarishal;

  /// No description provided for @divisionSylhet.
  ///
  /// In en, this message translates to:
  /// **'Sylhet Division'**
  String get divisionSylhet;

  /// No description provided for @divisionRangpur.
  ///
  /// In en, this message translates to:
  /// **'Rangpur Division'**
  String get divisionRangpur;

  /// No description provided for @divisionMymensingh.
  ///
  /// In en, this message translates to:
  /// **'Mymensingh Division'**
  String get divisionMymensingh;

  /// No description provided for @relChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relChild;

  /// No description provided for @relSpouse.
  ///
  /// In en, this message translates to:
  /// **'Husband / Wife'**
  String get relSpouse;

  /// No description provided for @relParent.
  ///
  /// In en, this message translates to:
  /// **'Father / Mother'**
  String get relParent;

  /// No description provided for @relSibling.
  ///
  /// In en, this message translates to:
  /// **'Brother / Sister'**
  String get relSibling;

  /// No description provided for @relOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relOther;

  /// No description provided for @relHolderYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String relHolderYou(String name);

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @occStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get occStudent;

  /// No description provided for @occPrivate.
  ///
  /// In en, this message translates to:
  /// **'Employee (private)'**
  String get occPrivate;

  /// No description provided for @occGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government employee'**
  String get occGovernment;

  /// No description provided for @occBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get occBusiness;

  /// No description provided for @occTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get occTeacher;

  /// No description provided for @occFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get occFarmer;

  /// No description provided for @occHomemaker.
  ///
  /// In en, this message translates to:
  /// **'Homemaker'**
  String get occHomemaker;

  /// No description provided for @occOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occOther;

  /// No description provided for @intBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced diet'**
  String get intBalanced;

  /// No description provided for @intPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Nutrition in pregnancy'**
  String get intPregnancy;

  /// No description provided for @intWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight management'**
  String get intWeight;

  /// No description provided for @intChild.
  ///
  /// In en, this message translates to:
  /// **'Child nutrition'**
  String get intChild;

  /// No description provided for @intDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes management'**
  String get intDiabetes;

  /// No description provided for @intGeneral.
  ///
  /// In en, this message translates to:
  /// **'General health awareness'**
  String get intGeneral;

  /// No description provided for @bmiForWhom.
  ///
  /// In en, this message translates to:
  /// **'Who is this for?'**
  String get bmiForWhom;

  /// No description provided for @bmiSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'See previous records'**
  String get bmiSeeHistory;

  /// No description provided for @bmiChoosePerson.
  ///
  /// In en, this message translates to:
  /// **'Save for whom?'**
  String get bmiChoosePerson;

  /// No description provided for @bmiSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved to records'**
  String get bmiSavedToast;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get historyTitle;

  /// No description provided for @historyHeader.
  ///
  /// In en, this message translates to:
  /// **'{person} · {count} records'**
  String historyHeader(String person, String count);

  /// No description provided for @historyRowMeta.
  ///
  /// In en, this message translates to:
  /// **'{height} cm · {weight} kg'**
  String historyRowMeta(String height, String weight);

  /// No description provided for @historyGrowthSoon.
  ///
  /// In en, this message translates to:
  /// **'Growth chart coming soon'**
  String get historyGrowthSoon;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save height and weight to see changes over time here.'**
  String get historyEmptyBody;

  /// No description provided for @historyAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get historyAddAction;

  /// No description provided for @historyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct record'**
  String get historyEditTitle;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get deleteRecordConfirm;

  /// No description provided for @settingsChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get settingsChangeNumber;

  /// No description provided for @settingsPrivacyCentre.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyCentre;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out? Downloaded files stay on this phone.'**
  String get logoutConfirm;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting the account is permanent — it can\'t be restored.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountDeletes.
  ///
  /// In en, this message translates to:
  /// **'What will be deleted'**
  String get deleteAccountDeletes;

  /// No description provided for @deleteAccountProfiles.
  ///
  /// In en, this message translates to:
  /// **'Your and your family members\' profiles'**
  String get deleteAccountProfiles;

  /// No description provided for @deleteAccountRecords.
  ///
  /// In en, this message translates to:
  /// **'Saved height, weight and BMI records'**
  String get deleteAccountRecords;

  /// No description provided for @deleteAccountProgress.
  ///
  /// In en, this message translates to:
  /// **'Course and module progress'**
  String get deleteAccountProgress;

  /// No description provided for @deleteAccountRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Webinar registrations'**
  String get deleteAccountRegistrations;

  /// No description provided for @deleteAccountStays.
  ///
  /// In en, this message translates to:
  /// **'What stays'**
  String get deleteAccountStays;

  /// No description provided for @deleteAccountCertificates.
  ///
  /// In en, this message translates to:
  /// **'Issued certificates stay verifiable, because third parties may check them. Anonymous aggregate statistics also remain.'**
  String get deleteAccountCertificates;

  /// No description provided for @deleteAccountPust9.
  ///
  /// In en, this message translates to:
  /// **'The PUST9 subscription stays active with your operator — stop it separately.'**
  String get deleteAccountPust9;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'The account couldn\'t be deleted. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @accountDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeletedToast;
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
