class AuthUser {
  const AuthUser({required this.id, required this.phone});

  final String id;

  /// E.164, e.g. `+8801712345678`.
  final String phone;
}

/// Why a login step failed; each has its own words on screen.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class InvalidCodeFailure extends AuthFailure {
  const InvalidCodeFailure();
}

final class CodeExpiredFailure extends AuthFailure {
  const CodeExpiredFailure();
}

/// Too many codes requested or wrong attempts; wait before trying again.
final class TooManyAttemptsFailure extends AuthFailure {
  const TooManyAttemptsFailure();
}

final class SmsSendFailure extends AuthFailure {
  const SmsSendFailure();
}

/// The new number already belongs to another account (change number).
final class PhoneInUseFailure extends AuthFailure {
  const PhoneInUseFailure();
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure();
}

/// Accounts are not available in this build (production without keys).
final class AuthUnavailableFailure extends AuthFailure {
  const AuthUnavailableFailure();
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> get userChanges;

  /// Sends a one-time code by SMS (LAU-03).
  Future<void> requestCode(String phone);

  /// Verifies the code and signs in (LAU-04).
  Future<AuthUser> verifyCode(String phone, String code);

  /// Starts moving the account to a new number (LAU-06).
  Future<void> requestPhoneChange(String newPhone);

  Future<AuthUser> verifyPhoneChange(String newPhone, String code);

  Future<void> signOut();

  /// Deletes the account and its personal data (INF-05). Issued
  /// certificates stay verifiable.
  Future<void> deleteAccount();
}
