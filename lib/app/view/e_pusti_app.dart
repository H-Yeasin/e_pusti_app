import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_locale_controller_provider.dart';
import '../router/app_router.dart';

class EPustiApp extends ConsumerWidget {
  const EPustiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeController = ref.watch(appLocaleControllerProvider);

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'e-Pushti',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: localeController.locale,
          supportedLocales: EPustiGeneratedLocalizations.supportedLocales,
          localizationsDelegates:
              EPustiGeneratedLocalizations.localizationsDelegates,
          routerConfig: router,
        );
      },
    );
  }
}
