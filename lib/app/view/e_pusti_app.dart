import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_environment.dart';
import '../../core/localization/localization.dart';
import '../../core/theme/app_theme.dart';
import '../../features/splash/presentation/screens/animated_brand_splash.dart';
import '../providers/app_environment_provider.dart';

class EPustiApp extends ConsumerStatefulWidget {
  const EPustiApp({super.key});

  @override
  ConsumerState<EPustiApp> createState() => _EPustiAppState();
}

class _EPustiAppState extends ConsumerState<EPustiApp> {
  late final Future<AppLocaleController> _localeControllerFuture;

  @override
  void initState() {
    super.initState();
    _localeControllerFuture = _createLocaleController();
  }

  Future<AppLocaleController> _createLocaleController() async {
    final preferences = await SharedPreferences.getInstance();
    return AppLocaleController(AppLanguageStore(preferences));
  }

  @override
  Widget build(BuildContext context) {
    final environment = ref.watch(appEnvironmentProvider);

    return FutureBuilder<AppLocaleController>(
      future: _localeControllerFuture,
      builder: (context, snapshot) {
        final localeController = snapshot.data;

        if (localeController == null) {
          return _LocalizedMaterialApp(
            environment: environment,
            locale: AppLanguage.bangla.locale,
            home: const Scaffold(body: SizedBox.expand()),
          );
        }

        return AnimatedBuilder(
          animation: localeController,
          builder: (context, child) {
            return _LocalizedMaterialApp(
              environment: environment,
              locale: localeController.locale,
              home: AnimatedBrandSplash(
                environment: environment,
                localeController: localeController,
              ),
            );
          },
        );
      },
    );
  }
}

class _LocalizedMaterialApp extends StatelessWidget {
  const _LocalizedMaterialApp({
    required this.environment,
    required this.locale,
    required this.home,
  });

  final AppEnvironment environment;
  final Locale locale;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-Pushti',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppLanguage.values.map((language) => language.locale),
      localizationsDelegates: const [
        EPustiLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: home,
    );
  }
}
