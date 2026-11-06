/// PUST9 subscription on bdapps (Robi/Airtel), as seen by the signed-in
/// user. The server holds the bdapps credentials and the OTP reference.
enum Pust9Phase { notSubscribed, otpSent, subscribed, unsubscribed }

class Pust9Status {
  const Pust9Status({
    required this.phase,
    this.since,
    this.day = 0,
    this.courseDays = 0,
    this.phone,
  });

  const Pust9Status.notSubscribed() : this(phase: Pust9Phase.notSubscribed);

  final Pust9Phase phase;
  final DateTime? since;

  /// The day of the course the latest tip belongs to (1-based).
  final int day;
  final int courseDays;

  /// The subscribed number, E.164.
  final String? phone;

  bool get isSubscribed => phase == Pust9Phase.subscribed;

  /// Parses the `pust9-subscribe` function's response.
  factory Pust9Status.fromJson(Map<String, Object?> json) {
    final phase = switch (json['state']) {
      'otp_sent' => Pust9Phase.otpSent,
      'subscribed' => Pust9Phase.subscribed,
      'unsubscribed' => Pust9Phase.unsubscribed,
      _ => Pust9Phase.notSubscribed,
    };
    final since = json['subscribedAt'];
    return Pust9Status(
      phase: phase,
      since: since is String ? DateTime.tryParse(since) : null,
      day: (json['day'] as num?)?.toInt() ?? 0,
      courseDays: (json['courseDays'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String?,
    );
  }
}

sealed class Pust9Failure implements Exception {
  const Pust9Failure();

  /// Maps the function's `error` code.
  static Pust9Failure fromCode(Object? code) => switch (code) {
    'invalid_code' => const Pust9InvalidCodeFailure(),
    'code_expired' => const Pust9CodeExpiredFailure(),
    'not_eligible' => const Pust9NotEligibleFailure(),
    'rate_limited' => const Pust9RateLimitedFailure(),
    _ => const Pust9ServiceFailure(),
  };
}

class Pust9InvalidCodeFailure extends Pust9Failure {
  const Pust9InvalidCodeFailure();
}

class Pust9CodeExpiredFailure extends Pust9Failure {
  const Pust9CodeExpiredFailure();
}

class Pust9NotEligibleFailure extends Pust9Failure {
  const Pust9NotEligibleFailure();
}

class Pust9RateLimitedFailure extends Pust9Failure {
  const Pust9RateLimitedFailure();
}

class Pust9NetworkFailure extends Pust9Failure {
  const Pust9NetworkFailure();
}

/// bdapps or our server failed; the dial/SMS paths still work.
class Pust9ServiceFailure extends Pust9Failure {
  const Pust9ServiceFailure();
}

abstract interface class Pust9Repository {
  Future<Pust9Status> status();

  /// Sends a bdapps OTP to [phone] (E.164, Robi or Airtel).
  Future<void> requestOtp(String phone);

  /// Confirms the OTP; bdapps registers the subscription.
  Future<Pust9Status> verifyOtp(String code);

  Future<Pust9Status> unsubscribe();
}
