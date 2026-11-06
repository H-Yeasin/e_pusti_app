import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/backend_config.dart';
import '../domain/entities/mobile_operator.dart';
import '../domain/pust9_subscription.dart';

/// On-device stand-in for dev builds: any Robi/Airtel number, code `123456`.
class LocalPust9Repository implements Pust9Repository {
  LocalPust9Repository(
    this._prefs,
    String accountId, {
    required this.courseDays,
    DateTime Function()? clock,
  }) : _key = 'local_${accountId}_pust9',
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final String _key;
  final int courseDays;
  final DateTime Function() _clock;

  Map<String, Object?> _read() {
    final raw = _prefs.getString(_key);
    return raw == null
        ? <String, Object?>{}
        : (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  Future<void> _write(Map<String, Object?> row) =>
      _prefs.setString(_key, jsonEncode(row));

  Pust9Status _status(Map<String, Object?> row) {
    final phase = switch (row['phase']) {
      'otp_sent' => Pust9Phase.otpSent,
      'subscribed' => Pust9Phase.subscribed,
      'unsubscribed' => Pust9Phase.unsubscribed,
      _ => Pust9Phase.notSubscribed,
    };
    final since = DateTime.tryParse(row['since'] as String? ?? '');
    final day = since == null
        ? 0
        : (_clock().difference(since).inDays + 1).clamp(1, courseDays);
    return Pust9Status(
      phase: phase,
      since: since,
      day: day,
      courseDays: courseDays,
      phone: row['phone'] as String?,
    );
  }

  @override
  Future<Pust9Status> status() async => _status(_read());

  @override
  Future<void> requestOtp(String phone) async {
    if (!MobileOperator.fromPhoneNumber(phone).supportsPust9) {
      throw const Pust9NotEligibleFailure();
    }
    final row = _read();
    await _write({
      ...row,
      'pendingPhone': phone,
      if (row['phase'] != 'subscribed') 'phase': 'otp_sent',
    });
  }

  @override
  Future<Pust9Status> verifyOtp(String code) async {
    final row = _read();
    final phone = row['pendingPhone'] as String?;
    if (phone == null) throw const Pust9CodeExpiredFailure();
    if (code != LocalBackend.devOtpCode) {
      throw const Pust9InvalidCodeFailure();
    }
    final next = {
      'phase': 'subscribed',
      'phone': phone,
      'since': row['phase'] == 'subscribed'
          ? row['since']
          : _clock().toIso8601String(),
    };
    await _write(next);
    return _status(next);
  }

  @override
  Future<Pust9Status> unsubscribe() async {
    final next = {..._read(), 'phase': 'unsubscribed'}..remove('pendingPhone');
    await _write(next);
    return _status(next);
  }
}
