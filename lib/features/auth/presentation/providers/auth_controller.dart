import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in state. Placeholder until phone OTP auth (LAU-03/04) is
/// built on Supabase; the rest of the app only depends on this shape.
class AuthSession {
  const AuthSession.loggedOut() : phoneNumber = null;

  const AuthSession.loggedIn({required String this.phoneNumber});

  final String? phoneNumber;

  bool get isLoggedIn => phoneNumber != null;
}

class AuthController extends Notifier<AuthSession> {
  @override
  AuthSession build() => const AuthSession.loggedOut();

  /// Development-only stand-in for the OTP flow.
  void debugLogIn(String phoneNumber) {
    state = AuthSession.loggedIn(phoneNumber: phoneNumber);
  }

  void logOut() {
    state = const AuthSession.loggedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);
