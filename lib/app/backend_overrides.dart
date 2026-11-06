import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/analytics/slot_events.dart';
import '../core/config/backend_config.dart';
import '../core/config/remote_config.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/profile/presentation/profile_providers.dart';

/// Wiring that only exists with a real backend.
List<Override> backendOverrides(BackendKind kind) {
  if (kind != BackendKind.supabase) return const [];
  final client = Supabase.instance.client;
  return [
    remoteConfigFetcherProvider.overrideWithValue(() async {
      final row = await client
          .from('app_config')
          .select('value')
          .eq('key', 'mobile')
          .maybeSingle();
      final value = row?['value'];
      return value is Map ? value.cast<String, Object?>() : null;
    }),
    slotEventSinkProvider.overrideWith((ref) {
      // Slot analytics only for signed-in users who accepted the terms
      // (aggregate reporting is part of PRO-03).
      final signedIn = ref.watch(authControllerProvider).isLoggedIn;
      final consent = ref.watch(consentProvider).value;
      if (!signedIn || consent?.hasAnswered != true) {
        return const NoopSlotEventSink();
      }
      return _SupabaseSlotEventSink(client);
    }),
  ];
}

class _SupabaseSlotEventSink implements SlotEventSink {
  const _SupabaseSlotEventSink(this._client);

  final SupabaseClient _client;

  @override
  Future<void> record(
    String slotId,
    SlotEventKind kind, {
    String? creative,
  }) async {
    try {
      await _client.from('slot_events').insert({
        'slot': slotId,
        'kind': kind.name,
        'creative': creative,
      });
    } catch (_) {
      // Analytics must never break the screen.
    }
  }
}
