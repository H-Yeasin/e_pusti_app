import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads text aloud with the phone's own speech engine (P2-3). No data is
/// used; it needs a Bangla voice installed on the phone. Recorded audio can
/// replace it per chapter later.
abstract interface class Narrator {
  /// Picks the first available Bangla voice; false when there is none.
  Future<bool> prepareBangla();

  /// Speaks [parts] in order; completes when finished or stopped.
  Future<void> speak(List<String> parts);

  Future<void> stop();
}

class DeviceNarrator implements Narrator {
  DeviceNarrator() {
    _tts.setCompletionHandler(() => _done?.complete());
    _tts.setCancelHandler(() => _done?.complete());
    _tts.setErrorHandler((_) => _done?.complete());
  }

  static const _banglaLocales = ['bn-BD', 'bn-IN', 'bn'];

  final _tts = FlutterTts();
  Completer<void>? _done;
  bool _stopped = false;

  @override
  Future<bool> prepareBangla() async {
    for (final locale in _banglaLocales) {
      try {
        final available = await _tts.isLanguageAvailable(locale);
        if (available == true || available == 1) {
          await _tts.setLanguage(locale);
          await _tts.setSpeechRate(0.45);
          return true;
        }
      } catch (_) {
        // Try the next locale.
      }
    }
    return false;
  }

  @override
  Future<void> speak(List<String> parts) async {
    _stopped = false;
    for (final part in parts) {
      if (_stopped) break;
      if (part.trim().isEmpty) continue;
      _done = Completer<void>();
      await _tts.speak(part);
      await _done!.future;
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    await _tts.stop();
    _done?.complete();
  }
}

/// Platforms without a speech engine (and tests).
class UnavailableNarrator implements Narrator {
  const UnavailableNarrator();

  @override
  Future<bool> prepareBangla() async => false;

  @override
  Future<void> speak(List<String> parts) async {}

  @override
  Future<void> stop() async {}
}

final narratorProvider = Provider<Narrator>((ref) {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final narrator = DeviceNarrator();
    ref.onDispose(narrator.stop);
    return narrator;
  }
  return const UnavailableNarrator();
});
