import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../webinars/domain/webinar_models.dart';
import '../domain/notification_models.dart';

/// Dev-backend webinar registrations and inbox, mirroring the Supabase
/// functions: capacity is checked at registration time, a registration
/// writes a confirmation to the inbox.
class LocalEngagementBackend
    implements WebinarRegistrationRepository, InboxRepository {
  LocalEngagementBackend(
    this._prefs,
    this.accountId, {
    required this.catalogue,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final String accountId;

  /// The webinar catalogue (content server).
  final Future<List<Webinar>> Function() catalogue;
  final DateTime Function() _clock;

  /// Seats taken by everyone, shared across accounts on this device.
  static const seatsTakenKey = 'local_webinar_seats_taken';
  String get _registrationsKey => 'local_${accountId}_registrations';
  String get _alertsKey => 'local_${accountId}_recording_alerts';
  String get _inboxKey => 'local_${accountId}_inbox';

  Map<String, int> _taken() {
    final raw = _prefs.getString(seatsTakenKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, Object?>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
  }

  Future<void> _setTaken(Map<String, int> taken) =>
      _prefs.setString(seatsTakenKey, jsonEncode(taken));

  List<Map<String, Object?>> _rows(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [
      for (final r in jsonDecode(raw) as List<Object?>)
        (r as Map).cast<String, Object?>(),
    ];
  }

  Future<void> _write(String key, List<Map<String, Object?>> rows) =>
      _prefs.setString(key, jsonEncode(rows));

  // ---- registrations -----------------------------------------------------

  @override
  Future<List<WebinarRegistration>> myRegistrations() async => [
    for (final r in _rows(_registrationsKey))
      WebinarRegistration(
        webinarId: r['webinar_id']! as String,
        registeredAt: DateTime.parse(r['at']! as String),
      ),
  ];

  @override
  Future<Map<String, int>> seatsLeft(List<Webinar> webinars) async {
    final taken = _taken();
    return {
      for (final w in webinars)
        w.id: (w.seatsLeft - (taken[w.id] ?? 0)).clamp(0, w.capacity),
    };
  }

  @override
  Future<RegisterOutcome> register(String webinarId) async {
    final mine = _rows(_registrationsKey);
    if (mine.any((r) => r['webinar_id'] == webinarId)) {
      return RegisterOutcome.registered;
    }
    final webinar = (await catalogue()).firstWhere((w) => w.id == webinarId);
    final left = (await seatsLeft([webinar]))[webinarId]!;
    if (left <= 0) return RegisterOutcome.full;

    final taken = _taken()..update(webinarId, (v) => v + 1, ifAbsent: () => 1);
    await _setTaken(taken);
    final now = _clock();
    await _write(_registrationsKey, [
      ...mine,
      {'webinar_id': webinarId, 'at': now.toIso8601String()},
    ]);
    await _addInbox(
      InboxItem(
        id: 'reg-$webinarId-${now.millisecondsSinceEpoch}',
        category: NotificationCategory.webinar,
        title: 'রেজিস্ট্রেশন সম্পন্ন: ${webinar.title}',
        body: 'ইভেন্টের ১৫ মিনিট আগে যোগ দেওয়ার লিংক দেখা যাবে।',
        createdAt: now,
        route: '/webinars/$webinarId',
      ),
    );
    return RegisterOutcome.registered;
  }

  @override
  Future<void> cancel(String webinarId) async {
    final mine = _rows(_registrationsKey);
    if (!mine.any((r) => r['webinar_id'] == webinarId)) return;
    await _write(
      _registrationsKey,
      mine.where((r) => r['webinar_id'] != webinarId).toList(),
    );
    final taken = _taken();
    taken[webinarId] = ((taken[webinarId] ?? 1) - 1).clamp(0, 1 << 30);
    await _setTaken(taken);
  }

  @override
  Future<String?> joinLink(String webinarId) async {
    final registered = _rows(
      _registrationsKey,
    ).any((r) => r['webinar_id'] == webinarId);
    if (!registered) return null;
    final webinar = (await catalogue()).firstWhere((w) => w.id == webinarId);
    // Dev backend has no meeting links; a real one comes from the server.
    return webinar.isJoinable(_clock())
        ? 'https://example.org/join/$webinarId'
        : null;
  }

  @override
  Future<void> requestRecordingAlert(String webinarId) async {
    final alerts = await recordingAlerts();
    await _prefs.setStringList(_alertsKey, {...alerts, webinarId}.toList());
  }

  @override
  Future<Set<String>> recordingAlerts() async =>
      (_prefs.getStringList(_alertsKey) ?? const []).toSet();

  // ---- inbox ---------------------------------------------------------------

  Future<void> _addInbox(InboxItem item) =>
      _write(_inboxKey, [..._rows(_inboxKey), item.toJson()]);

  @override
  Future<List<InboxItem>> list() async {
    final items = [for (final r in _rows(_inboxKey)) InboxItem.fromJson(r)];
    items.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  @override
  Future<void> markRead(String id) async {
    final now = _clock().toUtc().toIso8601String();
    await _write(_inboxKey, [
      for (final r in _rows(_inboxKey))
        r['id'] == id && r['read_at'] == null ? {...r, 'read_at': now} : r,
    ]);
  }

  @override
  Future<void> markAllRead() async {
    final now = _clock().toUtc().toIso8601String();
    await _write(_inboxKey, [
      for (final r in _rows(_inboxKey))
        r['read_at'] == null ? {...r, 'read_at': now} : r,
    ]);
  }
}
