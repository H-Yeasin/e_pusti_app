import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_environment_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../providers/auth_controller.dart';

/// Placeholder for LAU-03 / LAU-04 (phone number + OTP).
///
/// After a successful login the user goes back to [returnTo] — the place
/// they were when login became necessary (LAU-05 promise).
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
        final target = AppRoutes.safeReturnTarget(returnTo);
        final router = GoRouter.of(context);
        if (router.canPop()) {
          // Keep the screen the user came from underneath, so back works.
          router.pop();
          if (target != AppRoutes.home) {
            router.push(target);
          }
        } else {
          router.go(target);
        }
      }
    });
    final l10n = context.l10n;
    final isDev = ref.watch(appEnvironmentProvider) == AppEnvironment.dev;

    return Scaffold(
      appBar: EpAppBar(title: l10n.loginTitle),
      body: EpStateView(
        icon: Icons.phone_iphone_rounded,
        title: l10n.comingSoonTitle,
        body: l10n.comingSoonBody,
        primaryLabel: isDev ? l10n.devSimulateLogin : null,
        onPrimary: isDev
            ? () => ref
                  .read(authControllerProvider.notifier)
                  .debugLogIn('+880 1712-345678')
            : null,
      ),
    );
  }
}
