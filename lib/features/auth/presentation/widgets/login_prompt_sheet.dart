import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';

/// LAU-05: a sheet over the current context asking to log in only at the
/// moment it becomes necessary. "Not now" leaves the user where they were.
Future<void> showLoginPrompt(
  BuildContext context, {
  required String returnTo,
  String? title,
  String? body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EpSpace.s6,
            0,
            EpSpace.s6,
            EpSpace.s6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title ?? l10n.loginPromptTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: EpSpace.s2),
              Text(
                body ?? l10n.loginPromptBody,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: EpSpace.s6),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.loginReturningTo(returnTo));
                },
                child: Text(l10n.loginAction),
              ),
              const SizedBox(height: EpSpace.s2),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.notNowAction),
              ),
            ],
          ),
        ),
      );
    },
  );
}
