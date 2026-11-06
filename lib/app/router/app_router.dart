import 'package:flutter/foundation.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/journey/journey_screen.dart';
import '../../features/bookmarks/saved_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_environment.dart';
import '../../core/config/app_info.dart';
import '../../core/config/remote_config.dart';
import '../../core/utils/version.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/assessment/domain/learning_models.dart';
import '../../features/assessment/presentation/screens/assessment_result_screen.dart';
import '../../features/assessment/presentation/screens/assessment_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/certificates/presentation/screens/certificate_detail_screen.dart';
import '../../features/certificates/presentation/screens/certificates_screen.dart';
import '../../features/digiskills/presentation/screens/module_list_screen.dart';
import '../../features/digiskills/presentation/screens/module_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/bmi/presentation/screens/bmi_history_screen.dart';
import '../../features/profile/presentation/screens/consent_screen.dart';
import '../../features/profile/presentation/screens/person_form_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/support/presentation/screens/delete_account_screen.dart';
import '../../features/support/presentation/screens/privacy_centre_screen.dart';
import '../../features/bmi/presentation/bmi_route_args.dart';
import '../../features/bmi/presentation/screens/bmi_entry_screen.dart';
import '../../features/bmi/presentation/screens/bmi_result_screen.dart';
import '../../features/courses/presentation/screens/chapter_screen.dart';
import '../../features/courses/presentation/screens/course_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/language/presentation/screens/language_selection_screen.dart';
import '../../features/notifications/domain/notification_models.dart';
import '../../features/notifications/presentation/engagement_providers.dart';
import '../../features/notifications/presentation/screens/inbox_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/pust9/presentation/screens/pust9_archive_screen.dart';
import '../../features/webinars/presentation/screens/my_registrations_screen.dart';
import '../../features/library/presentation/screens/document_screen.dart';
import '../../features/library/presentation/screens/downloads_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/pust9/presentation/screens/pust9_screen.dart';
import '../../features/splash/presentation/screens/animated_brand_splash.dart';
import '../../features/support/presentation/screens/about_screen.dart';
import '../../features/support/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/system/presentation/screens/update_required_screen.dart';
import '../../features/webinars/presentation/screens/webinar_detail_screen.dart';
import '../../features/webinars/presentation/screens/webinar_list_screen.dart';
import '../dev/component_catalog_screen.dart';
import '../providers/app_environment_provider.dart';
import '../providers/app_locale_controller_provider.dart';
import 'app_routes.dart';

/// Pure redirect rule, kept separate so it can be unit tested.
///
/// * Gated screens send logged-out users to login, remembering where they
///   were going.
/// * An unsupported app version sees only the forced-update screen.
/// * A logged-in user opening the login screen is returned to that place.
///
/// Redirects run on every navigation. Login success itself is handled by
/// `LoginScreen` (it pops back and opens the target), so there is no
/// `refreshListenable` — refreshing here would race with that navigation.
String? resolveRedirect({
  required Uri location,
  required bool isLoggedIn,
  required bool isDev,
  bool updateRequired = false,
}) {
  // epushti://webinars/w1 arrives with the first segment as the host.
  if (location.scheme == 'epushti') {
    final path = '/${location.host}${location.path}';
    return Uri(
      path: path == '/' ? AppRoutes.home : path,
      query: location.query.isEmpty ? null : location.query,
    ).toString();
  }
  final path = location.path;
  if (updateRequired) {
    return path == AppRoutes.updateRequired ? null : AppRoutes.updateRequired;
  }
  if (path == AppRoutes.updateRequired) {
    return AppRoutes.home;
  }
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
  final updateRequired = isVersionBelow(
    ref.watch(appInfoProvider).version,
    ref.watch(remoteConfigProvider.select((c) => c.minSupportedVersion)),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode && isDev,
    redirect: (context, state) => resolveRedirect(
      location: state.uri,
      isLoggedIn: ref.read(authControllerProvider).isLoggedIn,
      isDev: isDev,
      updateRequired: updateRequired,
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
        routes: [
          GoRoute(
            path: 'verify',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return VerifyCodeScreen(
                phone: q['phone'] ?? '',
                returnTo: q['from'],
                changeNumber: q['change'] == '1',
              );
            },
          ),
          GoRoute(
            path: 'change',
            builder: (context, state) => const LoginScreen(changeNumber: true),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (context, state) =>
            ConsentScreen(returnTo: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'person/new',
            builder: (context, state) => const PersonFormScreen(),
          ),
          GoRoute(
            path: 'person/:id',
            builder: (context, state) =>
                PersonFormScreen(personId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.updateRequired,
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.pust9,
        builder: (context, state) => const Pust9Screen(),
        routes: [
          GoRoute(
            path: 'tips',
            builder: (context, state) => const Pust9ArchiveScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.saved,
        builder: (context, state) => const SavedScreen(),
      ),
      GoRoute(
        path: AppRoutes.journey,
        builder: (context, state) => const JourneyScreen(),
      ),
      GoRoute(
        path: AppRoutes.registrations,
        builder: (context, state) => const MyRegistrationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: AppRoutes.bmi,
        builder: (context, state) =>
            BmiEntryScreen(personId: state.uri.queryParameters['p']),
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final input = BmiRouteArgs.fromQuery(q);
              return input == null
                  ? const BmiEntryScreen()
                  : BmiResultScreen(
                      input: input,
                      personId: BmiRouteArgs.personIdFrom(q),
                    );
            },
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) =>
                BmiHistoryScreen(personId: state.uri.queryParameters['p']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (context, state) => const CourseListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ChapterScreen(chapterId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryScreen(),
        routes: [
          GoRoute(
            path: 'downloads',
            builder: (context, state) => const DownloadsScreen(),
          ),
          GoRoute(
            path: 'doc/:id',
            builder: (context, state) =>
                DocumentScreen(documentId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.webinars,
        builder: (context, state) => const WebinarListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                WebinarDetailScreen(webinarId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyCentreScreen(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.digiSkills,
        builder: (context, state) => const ModuleListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ModuleScreen(moduleId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.assessments}/:id',
        builder: (context, state) =>
            AssessmentScreen(assessmentId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final result = state.extra;
              return result is AssessmentResult
                  ? AssessmentResultScreen(result: result)
                  : AssessmentScreen(assessmentId: state.pathParameters['id']!);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.certificates,
        builder: (context, state) => const CertificatesScreen(),
        routes: [
          GoRoute(
            path: ':code',
            builder: (context, state) =>
                CertificateDetailScreen(code: state.pathParameters['code']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.devCatalog,
        builder: (context, state) => const ComponentCatalogScreen(),
      ),
    ],
  );
  // Tapping a shown reminder opens its in-app destination.
  final taps = ref.watch(reminderSchedulerProvider).taps.listen((route) {
    final safe = safeNotificationRoute(route);
    if (safe != null) router.push(safe);
  });
  ref.onDispose(taps.cancel);
  ref.onDispose(router.dispose);
  return router;
});
