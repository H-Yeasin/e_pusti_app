/// Failure taxonomy from the design's system states (SYS-01…03, DGS-01/02).
///
/// Each failure needs different words on screen, so repositories must map
/// transport errors to one of these instead of throwing raw exceptions.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// The device has no internet connection (SYS-01).
final class NoConnectionFailure extends AppFailure {
  const NoConnectionFailure();
}

/// The request is taking too long (SYS-02 shows a skeleton after 3 s).
final class SlowConnectionFailure extends AppFailure {
  const SlowConnectionFailure();
}

/// The VPS content server is unreachable while the internet works.
/// Progress (stored in Supabase) is not affected (DGS-01/02).
final class ContentServerUnavailableFailure extends AppFailure {
  const ContentServerUnavailableFailure();
}

/// Server-side error — "not the user's fault" (SYS-03).
final class ServerFailure extends AppFailure {
  const ServerFailure({required this.code, required this.occurredAt});

  /// Shown to the user, e.g. `ERR-503`, so support can trace it.
  final String code;
  final DateTime occurredAt;
}

/// The installed version is below the supported minimum (SYS-04).
final class UpdateRequiredFailure extends AppFailure {
  const UpdateRequiredFailure({required this.latestVersion});

  final String latestVersion;
}
