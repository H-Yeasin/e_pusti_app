import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_environment.dart';
import '../../core/localization/localization.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/language/presentation/screens/language_selection_screen.dart';
import '../../features/splash/presentation/screens/animated_brand_splash.dart';
import '../dev/component_catalog_screen.dart';
import '../providers/app_environment_provider.dart';
import '../providers/app_locale_controller_provider.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';

/// Pure redirect rule, kept separate so it can be unit tested.
///
/// * Gated screens send logged-out users to login, remembering where they
///   were going.
/// * A logged-in user opening the login screen is returned to that place.
///
/// Redirects run on every navigation. Login success itself is handled by
/// `LoginScreen` (it pops back and opens the target), so there is no
/// `refreshListenable` — refreshing here would race with that navigation.
String? resolveRedirect({
  required Uri location,
  required bool isLoggedIn,
  required bool isDev,
}) {
  final path = location.path;
  if (path == AppRoutes.devCatalog && !isDev) {
    return AppRoutes.home;
  }
  if (AppRoutes.isGated(path) && !isLoggedIn) {
    return AppRoutes.loginReturningTo(location.toString());
  }
  if (path == AppRoutes.login && isLoggedIn) {
    return AppRoutes.safeReturnTarget(location.queryParameters['from']);
  }
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isDev = ref.watch(appEnvironmentProvider) == AppEnvironment.dev;
  final localeController = ref.watch(appLocaleControllerProvider);

  GoRoute placeholder(String path, String Function(BuildContext) title) {
    return GoRoute(
      path: path,
      builder: (context, state) => PlaceholderScreen(title: title(context)),
    );
  }

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode && isDev,
    redirect: (context, state) => resolveRedirect(
      location: state.uri,
      isLoggedIn: ref.read(authControllerProvider).isLoggedIn,
      isDev: isDev,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            AnimatedBrandSplash(localeController: localeController),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) =>
            LanguageSelectionScreen(localeController: localeController),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            LoginScreen(returnTo: state.uri.queryParameters['from']),
      ),
      placeholder(AppRoutes.pust9, (c) => c.l10n.pust9Title),
      placeholder(AppRoutes.webinars, (c) => c.l10n.homeWebinar),
      placeholder(AppRoutes.courses, (c) => c.l10n.academyTitle),
      placeholder(AppRoutes.digiSkills, (c) => c.l10n.homeDigiSkill),
      placeholder(AppRoutes.library, (c) => c.l10n.homeLibrary),
      placeholder(AppRoutes.bmi, (c) => c.l10n.homeBmiTitle),
      placeholder(AppRoutes.about, (c) => c.l10n.menuAbout),
      placeholder(AppRoutes.support, (c) => c.l10n.menuSupport),
      placeholder(AppRoutes.settings, (c) => c.l10n.menuSettings),
      placeholder(AppRoutes.profile, (c) => c.l10n.menuFamilyProfile),
      placeholder(AppRoutes.certificates, (c) => c.l10n.menuCertificates),
      placeholder(AppRoutes.registrations, (c) => c.l10n.menuRegistrations),
      placeholder(AppRoutes.notifications, (c) => c.l10n.menuNotifications),
      GoRoute(
        path: AppRoutes.devCatalog,
        builder: (context, state) => const ComponentCatalogScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
