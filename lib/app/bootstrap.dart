import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_environment.dart';
import 'providers/app_environment_provider.dart';
import 'view/e_pusti_app.dart';

void bootstrap(AppEnvironment environment) {
  runApp(
    ProviderScope(
      overrides: [appEnvironmentProvider.overrideWithValue(environment)],
      child: const EPustiApp(),
    ),
  );
}
