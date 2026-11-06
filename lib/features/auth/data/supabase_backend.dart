import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../profile/domain/profile_models.dart';
import '../domain/auth_repository.dart';

/// Supabase implementations. Schema and row-level security live in
/// `supabase/migrations/`. Phone OTP needs an SMS provider configured in
/// the Supabase project.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static AuthUser? _map(User? user) {
    if (user == null) return null;
    final phone = user.phone ?? '';
    return AuthUser(
      id: user.id,
      phone: phone.startsWith('+') || phone.isEmpty ? phone : '+$phone',
    );
  }

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges =>
      _auth.onAuthStateChange.map((state) => _map(state.session?.user));

  @override
  Future<void> requestCode(String phone) =>
      _guard(() => _auth.signInWithOtp(phone: phone));

  @override
  Future<AuthUser> verifyCode(String phone, String code) => _guard(() async {
    final response = await _auth.verifyOTP(
      phone: phone,
      token: code,
      type: OtpType.sms,
    );
    return _map(response.user)!;
  });

  @override
  Future<void> requestPhoneChange(String newPhone) =>
      _guard(() => _auth.updateUser(UserAttributes(phone: newPhone)));

  @override
  Future<AuthUser> verifyPhoneChange(String newPhone, String code) =>
      _guard(() async {
        final response = await _auth.verifyOTP(
          phone: newPhone,
          token: code,
          type: OtpType.phoneChange,
        );
        return _map(response.user)!;
      });

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() => _guard(() async {
    await _client.rpc<void>('delete_my_account');
    await _auth.signOut();
  });

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw switch (e.code) {
        'otp_expired' => const CodeExpiredFailure(),
        'over_sms_send_rate_limit' ||
        'over_request_rate_limit' => const TooManyAttemptsFailure(),
        'sms_send_failed' => const SmsSendFailure(),
        'phone_exists' => const PhoneInUseFailure(),
        _ when e.statusCode == '429' => const TooManyAttemptsFailure(),
        _ => const InvalidCodeFailure(),
      };
    } on SocketException {
      throw const AuthNetworkFailure();
    } on TimeoutException {
      throw const AuthNetworkFailure();
    }
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Person>> loadFamily() async {
    final rows = await _client.from('people').select().order('created_at');
    return [for (final row in rows) Person.fromJson(row)];
  }

  @override
  Future<void> savePerson(Person person) =>
      _client.from('people').upsert(person.toJson());

  @override
  Future<void> deletePerson(String personId) =>
      _client.from('people').delete().eq('id', personId);
}

class SupabaseMeasurementRepository implements MeasurementRepository {
  SupabaseMeasurementRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Measurement>> listFor(String personId) async {
    final rows = await _client
        .from('measurements')
        .select()
        .eq('person_id', personId)
        .order('measured_at', ascending: false);
    return [for (final row in rows) Measurement.fromJson(row)];
  }

  @override
  Future<void> save(Measurement measurement) =>
      _client.from('measurements').upsert(measurement.toJson());

  @override
  Future<void> delete(String measurementId) =>
      _client.from('measurements').delete().eq('id', measurementId);

  @override
  Future<void> deleteAll() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('measurements').delete().eq('account_id', user.id);
  }
}

class SupabaseConsentRepository implements ConsentRepository {
  SupabaseConsentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ConsentRecord> load() async {
    final row = await _client.from('consents').select().maybeSingle();
    if (row == null) return ConsentRecord.none;
    final withdrawn = DateTime.tryParse('${row['health_data_withdrawn_at']}');
    final accepted = DateTime.tryParse('${row['health_data_accepted_at']}');
    return ConsentRecord(
      termsAcceptedAt: DateTime.tryParse('${row['terms_accepted_at']}'),
      healthDataAcceptedAt:
          accepted != null &&
              (withdrawn == null || withdrawn.isBefore(accepted))
          ? accepted
          : null,
    );
  }

  @override
  Future<void> accept({required bool healthData}) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _client.from('consents').upsert({
      'terms_accepted_at': now,
      if (healthData) 'health_data_accepted_at': now,
    });
  }

  @override
  Future<void> withdrawHealthData() => _client.from('consents').upsert({
    'health_data_withdrawn_at': DateTime.now().toUtc().toIso8601String(),
  });
}
