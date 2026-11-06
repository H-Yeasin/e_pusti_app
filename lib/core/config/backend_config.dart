import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

enum BackendKind {
  /// Supabase project configured with `--dart-define` keys.
  supabase,

  /// On-device stand-in for development and staging builds without keys:
  /// any valid number logs in with code [LocalBackend.devOtpCode].
  local,

  /// Production build without keys: accounts are unavailable, the rest of
  /// the app (everything the soft gate allows) still works.
  none,
}

class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Build with:
  /// `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`
  /// (the project's publishable / anon key — never the service-role key).
  static const fromEnvironment = BackendConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  BackendKind kindFor(AppEnvironment environment) {
    if (hasSupabase) return BackendKind.supabase;
    return environment == AppEnvironment.prod
        ? BackendKind.none
        : BackendKind.local;
  }
}

/// Overridden in `bootstrap`.
final backendKindProvider = Provider<BackendKind>((ref) => BackendKind.local);

abstract final class LocalBackend {
  static const devOtpCode = '123456';
}
