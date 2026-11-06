import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppInfo {
  const AppInfo({required this.version});

  final String version;
}

/// Overridden in `bootstrap` with values read from the platform.
final appInfoProvider = Provider<AppInfo>(
  (ref) => const AppInfo(version: '1.0.0'),
);
