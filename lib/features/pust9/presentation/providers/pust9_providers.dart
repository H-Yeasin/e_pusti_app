import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../core/config/backend_config.dart';
import '../../../../core/config/remote_config.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/local_pust9_repository.dart';
import '../../data/supabase_pust9_repository.dart';
import '../../domain/pust9_subscription.dart';

/// Account-scoped; null while logged out or without a backend.
final pust9RepositoryProvider = Provider<Pust9Repository?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabasePust9Repository(Supabase.instance.client),
    BackendKind.local => LocalPust9Repository(
      ref.watch(sharedPreferencesProvider),
      userId,
      courseDays: ref.watch(
        remoteConfigProvider.select((c) => c.pust9.courseDays),
      ),
    ),
    BackendKind.none => null,
  };
});

/// Whether the in-app (bdapps OTP) path is offered at all.
final pust9InAppAvailableProvider = Provider<bool>((ref) {
  final enabled = ref.watch(
    remoteConfigProvider.select((c) => c.pust9.inAppSubscribe),
  );
  return enabled && ref.watch(backendKindProvider) != BackendKind.none;
});

/// The signed-in user's PUST9 status; null while logged out. A failed
/// status check surfaces as an error, and the screen falls back to the
/// dial/SMS paths.
class Pust9SubscriptionController extends AsyncNotifier<Pust9Status?> {
  @override
  Future<Pust9Status?> build() async {
    final repo = ref.watch(pust9RepositoryProvider);
    if (repo == null || !ref.watch(pust9InAppAvailableProvider)) return null;
    return repo.status();
  }

  Pust9Repository get _repo {
    final repo = ref.read(pust9RepositoryProvider);
    if (repo == null) throw const Pust9ServiceFailure();
    return repo;
  }

  Future<void> requestOtp(String phone) async {
    await _repo.requestOtp(phone);
    final current = state.value;
    if (current == null || !current.isSubscribed) {
      state = AsyncData(Pust9Status(phase: Pust9Phase.otpSent, phone: phone));
    }
  }

  Future<Pust9Status> verifyOtp(String code) async {
    final status = await _repo.verifyOtp(code);
    state = AsyncData(status);
    return status;
  }

  Future<void> unsubscribe() async {
    state = AsyncData(await _repo.unsubscribe());
  }
}

final pust9SubscriptionProvider =
    AsyncNotifierProvider<Pust9SubscriptionController, Pust9Status?>(
      Pust9SubscriptionController.new,
    );
