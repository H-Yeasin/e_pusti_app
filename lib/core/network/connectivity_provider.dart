import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network reachability as seen by the OS. `true` while unknown, so the app
/// never shows an offline state before it has evidence.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  try {
    yield online(await connectivity.checkConnectivity());
  } catch (_) {
    yield true;
  }
  yield* connectivity.onConnectivityChanged.map(online);
});

/// Whether the current connection is Wi-Fi (used by "video on Wi-Fi only"
/// and the download queue).
final isOnWifiProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool wifi(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);

  try {
    yield wifi(await connectivity.checkConnectivity());
  } catch (_) {
    yield false;
  }
  yield* connectivity.onConnectivityChanged.map(wifi);
});
