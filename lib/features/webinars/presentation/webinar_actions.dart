import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/widgets/login_prompt_sheet.dart';

/// Seat reservation and recording alerts need an account. Logged out, ask
/// at this moment; logged in, registration itself arrives in Phase 4.
void requireLoginForWebinar(
  BuildContext context,
  WidgetRef ref,
  String webinarId,
) {
  final l10n = context.l10n;
  if (!ref.read(authControllerProvider).isLoggedIn) {
    showLoginPrompt(
      context,
      returnTo: AppRoutes.webinar(webinarId),
      body: l10n.webinarRegisterLoginBody,
    );
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.comingSoonTitle)));
}
