import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({required this.videoOnWifiOnly});

  final bool videoOnWifiOnly;
}

/// Device settings from INF-04. Video on Wi-Fi only is on by default to
/// protect metered connections.
class AppSettingsController extends AsyncNotifier<AppSettings> {
  static const _videoWifiKey = 'settings_video_wifi_only';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(videoOnWifiOnly: prefs.getBool(_videoWifiKey) ?? true);
  }

  Future<void> setVideoOnWifiOnly(bool value) async {
    state = AsyncData(AppSettings(videoOnWifiOnly: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoWifiKey, value);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
