import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SlotEventKind { impression, click }

/// Where partner-slot impressions and clicks go. No health data, no
/// identifiers beyond what the backend already has for a signed-in,
/// consenting user.
abstract interface class SlotEventSink {
  Future<void> record(String slotId, SlotEventKind kind, {String? creative});
}

class NoopSlotEventSink implements SlotEventSink {
  const NoopSlotEventSink();

  @override
  Future<void> record(
    String slotId,
    SlotEventKind kind, {
    String? creative,
  }) async {}
}

/// Overridden in `bootstrap` with a sink that records only after consent.
final slotEventSinkProvider = Provider<SlotEventSink>(
  (ref) => const NoopSlotEventSink(),
);

/// Impressions are counted once per slot and creative per app session.
final _seenThisSession = <String>{};

bool markImpressionOnce(String slotId, String creative) =>
    _seenThisSession.add('$slotId|$creative');
