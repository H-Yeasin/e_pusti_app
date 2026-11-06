import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization.dart';
import '../../profile/presentation/profile_providers.dart';

/// After a successful code: close the login screens, ask for consent once
/// if it was never answered, then take the user back to where they were
/// (LAU-05 promise). A number change simply returns to Settings.
Future<void> completeLogin(
  BuildContext context,
  WidgetRef ref, {
  required String? returnTo,
  bool changedNumber = false,
}) async {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final changedText = context.l10n.numberChangedToast;
  final hadStack = router.canPop();

  // Verify screen, then the phone-entry screen beneath it.
  for (var i = 0; i < 2 && router.canPop(); i++) {
    router.pop();
  }

  if (changedNumber) {
    messenger?.showSnackBar(SnackBar(content: Text(changedText)));
    return;
  }

  final target = AppRoutes.safeReturnTarget(returnTo);
  final consent = await ref.read(consentProvider.future);
  if (!consent.hasAnswered) {
    router.push(AppRoutes.consentReturningTo(target));
    return;
  }
  if (!hadStack) {
    router.go(target);
    return;
  }
  goToTarget(router, target);
}

/// Opens [target] unless it is already the visible screen.
void goToTarget(GoRouter router, String target) {
  final current = router.routerDelegate.currentConfiguration.uri.toString();
  if (current == target) return;
  if (target == AppRoutes.home) {
    router.go(AppRoutes.home);
    return;
  }
  router.push(target);
}
