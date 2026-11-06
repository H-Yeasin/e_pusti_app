import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_environment.dart';
import '../core/config/app_info.dart';
import '../core/config/backend_config.dart';
import '../core/localization/localization.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import 'backend_overrides.dart';
import 'providers/app_environment_provider.dart';
import 'providers/app_locale_controller_provider.dart';
import 'view/e_pusti_app.dart';

/// Failures show their own "Try again"; silent retries would hide them and
/// spend data on metered connections.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Loads local-only state (no network, so the splash never blocks on it)
/// and starts the app.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  const backend = BackendConfig.fromEnvironment;
  final backendKind = backend.kindFor(environment);
  if (backendKind == BackendKind.supabase) {
    // Restores a saved session from local storage; no network needed here.
    await Supabase.initialize(
      url: backend.supabaseUrl,
      publishableKey: backend.supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendKindProvider.overrideWithValue(backendKind),
        appLocaleControllerProvider.overrideWithValue(
          AppLocaleController(AppLanguageStore(preferences)),
        ),
        appInfoProvider.overrideWithValue(
          AppInfo(version: packageInfo.version),
        ),
        ...backendOverrides(backendKind),
      ],
      child: const EPustiApp(),
    ),
  );
}
