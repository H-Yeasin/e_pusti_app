import 'package:flutter/widgets.dart';

import '../../../core/localization/localization.dart';
import '../domain/auth_repository.dart';

String authFailureMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  return switch (error) {
    InvalidCodeFailure() => l10n.otpWrong,
    CodeExpiredFailure() => l10n.otpExpired,
    TooManyAttemptsFailure() => l10n.otpTooMany,
    SmsSendFailure() => l10n.otpSmsFailed,
    PhoneInUseFailure() => l10n.phoneInUse,
    AuthNetworkFailure() => l10n.offlineTitle,
    AuthUnavailableFailure() => l10n.authUnavailable,
    _ => l10n.serverErrorTitle,
  };
}
