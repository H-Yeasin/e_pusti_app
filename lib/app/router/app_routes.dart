/// Route paths. One path per screen family in the design.
abstract final class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const home = '/home';
  static const login = '/login';

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

  static const devCatalog = '/dev/catalog';

  static const gated = {profile, certificates, registrations, notifications};

  static bool isGated(String path) => gated.contains(path);

  /// `/login?from=…` — after login the user returns to [returnTo].
  static String loginReturningTo(String returnTo) =>
      Uri(path: login, queryParameters: {'from': returnTo}).toString();

  /// Only accept in-app paths as a return target.
  static String safeReturnTarget(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return home;
    }
    if (from == login || from.startsWith('$login?')) {
      return home;
    }
    return from;
  }
}
