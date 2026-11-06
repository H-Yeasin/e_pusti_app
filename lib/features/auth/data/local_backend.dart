import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/backend_config.dart';
import '../../profile/domain/profile_models.dart';
import '../domain/auth_repository.dart';

/// On-device stand-in for Supabase in development and staging builds.
///
/// Any valid number signs in with [LocalBackend.devOtpCode]. Data is kept in
/// shared preferences per account, so the app's flows can be used and tested
/// end to end without a server. Never used in production.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs) {
    final raw = _prefs.getString(_sessionKey);
    if (raw != null) {
      final json = jsonDecode(raw) as Map<String, Object?>;
      _user = AuthUser(
        id: json['id']! as String,
        phone: json['phone']! as String,
      );
    }
  }

  static const _sessionKey = 'local_backend_session';
  static const _accountsKey = 'local_backend_accounts';
  static const maxWrongAttempts = 5;

  final SharedPreferences _prefs;
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  int _wrongAttempts = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  Map<String, String> get _accounts {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, Object?>).cast<String, String>();
  }

  Future<void> _saveAccounts(Map<String, String> accounts) =>
      _prefs.setString(_accountsKey, jsonEncode(accounts));

  Future<void> _setUser(AuthUser? user) async {
    _user = user;
    if (user == null) {
      await _prefs.remove(_sessionKey);
    } else {
      await _prefs.setString(
        _sessionKey,
        jsonEncode({'id': user.id, 'phone': user.phone}),
      );
    }
    _changes.add(user);
  }

  void _checkCode(String code) {
    if (_wrongAttempts >= maxWrongAttempts) {
      throw const TooManyAttemptsFailure();
    }
    if (code != LocalBackend.devOtpCode) {
      _wrongAttempts++;
      throw _wrongAttempts >= maxWrongAttempts
          ? const TooManyAttemptsFailure()
          : const InvalidCodeFailure();
    }
    _wrongAttempts = 0;
  }

  @override
  Future<void> requestCode(String phone) async {
    _wrongAttempts = 0;
  }

  @override
  Future<AuthUser> verifyCode(String phone, String code) async {
    _checkCode(code);
    final accounts = _accounts;
    final id =
        accounts.entries
            .where((e) => e.value == phone)
            .map((e) => e.key)
            .firstOrNull ??
        'local-${Random().nextInt(1 << 32).toRadixString(16)}';
    accounts[id] = phone;
    await _saveAccounts(accounts);
    final user = AuthUser(id: id, phone: phone);
    await _setUser(user);
    return user;
  }

  @override
  Future<void> requestPhoneChange(String newPhone) async {
    if (_accounts.values.contains(newPhone)) {
      throw const PhoneInUseFailure();
    }
    _wrongAttempts = 0;
  }

  @override
  Future<AuthUser> verifyPhoneChange(String newPhone, String code) async {
    _checkCode(code);
    final user = AuthUser(id: _user!.id, phone: newPhone);
    final accounts = _accounts..[user.id] = newPhone;
    await _saveAccounts(accounts);
    await _setUser(user);
    return user;
  }

  @override
  Future<void> signOut() => _setUser(null);

  @override
  Future<void> deleteAccount() async {
    final id = _user?.id;
    if (id == null) return;
    for (final key in _prefs.getKeys().where(
      (k) => k.startsWith('local_$id'),
    )) {
      await _prefs.remove(key);
    }
    final accounts = _accounts..remove(id);
    await _saveAccounts(accounts);
    await _setUser(null);
  }
}

/// JSON list stored per account and table.
class _LocalTable {
  _LocalTable(this._prefs, this.accountId, this.table);

  final SharedPreferences _prefs;
  final String accountId;
  final String table;

  String get _key => 'local_${accountId}_$table';

  List<Map<String, Object?>> read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    return [
      for (final row in jsonDecode(raw) as List<Object?>)
        (row as Map).cast<String, Object?>(),
    ];
  }

  Future<void> write(List<Map<String, Object?>> rows) =>
      _prefs.setString(_key, jsonEncode(rows));
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(SharedPreferences prefs, String accountId)
    : _people = _LocalTable(prefs, accountId, 'people'),
      _measurements = _LocalTable(prefs, accountId, 'measurements');

  final _LocalTable _people;
  final _LocalTable _measurements;

  @override
  Future<List<Person>> loadFamily() async => [
    for (final row in _people.read()) Person.fromJson(row),
  ];

  @override
  Future<void> savePerson(Person person) async {
    final rows = _people.read()..removeWhere((r) => r['id'] == person.id);
    rows.add(person.toJson());
    await _people.write(rows);
  }

  @override
  Future<void> deletePerson(String personId) async {
    await _people.write(
      _people.read()..removeWhere((r) => r['id'] == personId),
    );
    await _measurements.write(
      _measurements.read()..removeWhere((r) => r['person_id'] == personId),
    );
  }
}

class LocalMeasurementRepository implements MeasurementRepository {
  LocalMeasurementRepository(SharedPreferences prefs, String accountId)
    : _table = _LocalTable(prefs, accountId, 'measurements');

  final _LocalTable _table;

  @override
  Future<List<Measurement>> listFor(String personId) async {
    final list = [
      for (final row in _table.read())
        if (row['person_id'] == personId) Measurement.fromJson(row),
    ]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return list;
  }

  @override
  Future<void> save(Measurement measurement) async {
    final rows = _table.read()..removeWhere((r) => r['id'] == measurement.id);
    rows.add(measurement.toJson());
    await _table.write(rows);
  }

  @override
  Future<void> delete(String measurementId) async =>
      _table.write(_table.read()..removeWhere((r) => r['id'] == measurementId));

  @override
  Future<void> deleteAll() => _table.write(const []);
}

class LocalConsentRepository implements ConsentRepository {
  LocalConsentRepository(this._prefs, String accountId)
    : _key = 'local_${accountId}_consent';

  final SharedPreferences _prefs;
  final String _key;

  @override
  Future<ConsentRecord> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return ConsentRecord.none;
    final json = jsonDecode(raw) as Map<String, Object?>;
    return ConsentRecord(
      termsAcceptedAt: DateTime.tryParse('${json['terms']}'),
      healthDataAcceptedAt: DateTime.tryParse('${json['health']}'),
    );
  }

  @override
  Future<void> accept({required bool healthData}) async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(
      _key,
      jsonEncode({'terms': now, 'health': healthData ? now : null}),
    );
  }

  @override
  Future<void> withdrawHealthData() async {
    final current = await load();
    await _prefs.setString(
      _key,
      jsonEncode({
        'terms': current.termsAcceptedAt?.toIso8601String(),
        'health': null,
      }),
    );
  }
}
