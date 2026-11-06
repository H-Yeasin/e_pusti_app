import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../core/config/app_preferences.dart';
import '../../../../core/config/backend_config.dart';
import '../../data/local_backend.dart';
import '../../data/supabase_backend.dart';
import '../../domain/auth_repository.dart';

export '../../../../core/config/app_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabaseAuthRepository(Supabase.instance.client),
    BackendKind.local => LocalAuthRepository(
      ref.watch(sharedPreferencesProvider),
    ),
    BackendKind.none => const _UnavailableAuthRepository(),
  };
});

class AuthSession {
  const AuthSession.loggedOut() : userId = null, phoneNumber = null;

  const AuthSession.loggedIn({
    required String this.userId,
    required String this.phoneNumber,
  });

  final String? userId;
  final String? phoneNumber;

  bool get isLoggedIn => userId != null;
}

/// The signed-in state, driven by the [AuthRepository].
class AuthController extends Notifier<AuthSession> {
  StreamSubscription<AuthUser?>? _sub;

  @override
  AuthSession build() {
    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.userChanges.listen((user) => state = _session(user));
    ref.onDispose(() => _sub?.cancel());
    return _session(repo.currentUser);
  }

  static AuthSession _session(AuthUser? user) => user == null
      ? const AuthSession.loggedOut()
      : AuthSession.loggedIn(userId: user.id, phoneNumber: user.phone);

  Future<void> requestCode(String phone) =>
      ref.read(authRepositoryProvider).requestCode(phone);

  Future<void> verifyCode(String phone, String code) async {
    final user = await ref.read(authRepositoryProvider).verifyCode(phone, code);
    state = _session(user);
  }

  Future<void> requestPhoneChange(String phone) =>
      ref.read(authRepositoryProvider).requestPhoneChange(phone);

  Future<void> verifyPhoneChange(String phone, String code) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyPhoneChange(phone, code);
    state = _session(user);
  }

  Future<void> logOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthSession.loggedOut();
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AuthSession.loggedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);

class _UnavailableAuthRepository implements AuthRepository {
  const _UnavailableAuthRepository();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get userChanges => const Stream.empty();

  Never _unavailable() => throw const AuthUnavailableFailure();

  @override
  Future<void> requestCode(String phone) async => _unavailable();

  @override
  Future<AuthUser> verifyCode(String phone, String code) async =>
      _unavailable();

  @override
  Future<void> requestPhoneChange(String newPhone) async => _unavailable();

  @override
  Future<AuthUser> verifyPhoneChange(String newPhone, String code) async =>
      _unavailable();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async => _unavailable();
}
