/// Route paths. One path per screen family in the design.
abstract final class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const home = '/home';
  static const login = '/login';
  static const loginVerify = '/login/verify';
  static const changeNumber = '/login/change';
  static const consent = '/consent';

  // Open to everyone (soft gate).
  static const pust9 = '/pust9';
  static const webinars = '/webinars';
  static const courses = '/courses';
  static const digiSkills = '/digi-skills';
  static const library = '/library';
  static const bmi = '/bmi';
  static const about = '/about';
  static const support = '/support';
  static const settings = '/settings';

  // Need an account (shown with 🔒 when logged out, never hidden).
  static const profile = '/profile';
  static const certificates = '/certificates';
  static const registrations = '/registrations';
  static const notifications = '/notifications';

  // Detail screens.
  static const bmiResult = '/bmi/result';
  static const downloads = '/library/downloads';
  static String chapter(String id) => '$courses/$id';
  static String document(String id) => '$library/doc/$id';
  static String webinar(String id) => '$webinars/$id';
  static String module(String id) => '$digiSkills/$id';
  static const assessments = '/assessment';
  static const notificationSettings = '/settings/notifications';
  static const search = '/search';
  static const saved = '/saved';
  static const journey = '/journey';
  static const pust9Archive = '/pust9/tips';
  static const pust9Verify = '/pust9/confirm';
  static String assessment(String id) => '$assessments/$id';
  static String assessmentResult(String id) => '$assessments/$id/result';
  static String certificate(String code) => '$certificates/$code';

  /// SYS-04 — reachable only through the version check redirect.
  static const updateRequired = '/update';

  static const devCatalog = '/dev/catalog';

  static const bmiHistory = '/bmi/history';
  static const privacyCentre = '/settings/privacy';
  static const deleteAccount = '/settings/delete-account';
  static const newPerson = '/profile/person/new';
  static String person(String id) => '/profile/person/$id';

  static const gated = {
    profile,
    certificates,
    registrations,
    notifications,
    bmiHistory,
    privacyCentre,
    deleteAccount,
    changeNumber,
    consent,
    assessments,
    journey,
    pust9Verify,
  };

  /// A gated path or anything beneath it (e.g. `/profile/person/x`).
  static bool isGated(String path) =>
      gated.any((g) => path == g || path.startsWith('$g/'));

  static String verifyCode({
    required String phone,
    String? returnTo,
    bool changeNumber = false,
  }) => Uri(
    path: loginVerify,
    queryParameters: {
      'phone': phone,
      'from': ?returnTo,
      if (changeNumber) 'change': '1',
    },
  ).toString();

  static String consentReturningTo(String returnTo) =>
      Uri(path: consent, queryParameters: {'from': returnTo}).toString();

  /// `/login?from=…` — after login the user returns to [returnTo].
  static String loginReturningTo(String returnTo) =>
      Uri(path: login, queryParameters: {'from': returnTo}).toString();

  /// Only accept in-app paths as a return target.
  static String safeReturnTarget(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return home;
    }
    if (from == login ||
        from.startsWith('$login?') ||
        from.startsWith('$login/')) {
      return home;
    }
    return from;
  }
}
