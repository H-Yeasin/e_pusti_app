import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_environment.dart';
import '../core/config/app_info.dart';
import '../core/localization/localization.dart';
import 'providers/app_environment_provider.dart';
import 'providers/app_locale_controller_provider.dart';
import 'view/e_pusti_app.dart';

/// Loads local-only state (no network, so the splash never blocks on it)
/// and starts the app.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        appLocaleControllerProvider.overrideWithValue(
          AppLocaleController(AppLanguageStore(preferences)),
        ),
        appInfoProvider.overrideWithValue(
          AppInfo(version: packageInfo.version),
        ),
      ],
      child: const EPustiApp(),
    ),
  );
}
