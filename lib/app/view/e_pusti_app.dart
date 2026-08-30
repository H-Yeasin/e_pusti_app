import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/theme/app_theme.dart';
import '../../features/splash/presentation/screens/animated_brand_splash.dart';
import '../providers/app_environment_provider.dart';

class EPustiApp extends ConsumerWidget {
  const EPustiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);

    return MaterialApp(
      title: 'e-Pushti',
      debugShowCheckedModeBanner: environment != AppEnvironment.prod,
      theme: buildAppTheme(),
      home: AnimatedBrandSplash(environment: environment),
    );
  }
}
