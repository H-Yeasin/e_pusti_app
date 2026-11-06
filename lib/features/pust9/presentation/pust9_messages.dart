import 'package:flutter/widgets.dart';

import '../../../core/localization/localization.dart';
import '../domain/pust9_subscription.dart';

String pust9FailureMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  return switch (error) {
    Pust9InvalidCodeFailure() => l10n.otpWrong,
    Pust9CodeExpiredFailure() => l10n.otpExpired,
    Pust9NotEligibleFailure() => l10n.pust9NotEligible,
    Pust9RateLimitedFailure() => l10n.pust9ErrorRateLimited,
    Pust9NetworkFailure() => l10n.offlineTitle,
    _ => l10n.pust9ErrorService,
  };
}
