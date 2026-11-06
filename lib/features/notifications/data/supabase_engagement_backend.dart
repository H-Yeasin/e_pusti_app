import 'package:supabase_flutter/supabase_flutter.dart';

import '../../webinars/domain/webinar_models.dart';
import '../domain/notification_models.dart';

/// Supabase implementation; see
/// `supabase/migrations/*_webinars_notifications_config.sql`.
class SupabaseEngagementBackend
    implements WebinarRegistrationRepository, InboxRepository {
  SupabaseEngagementBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WebinarRegistration>> myRegistrations() async {
    final rows = await _client
        .from('webinar_registrations')
        .select('webinar_id, registered_at');
    return [
      for (final r in rows)
        WebinarRegistration(
          webinarId: r['webinar_id'] as String,
          registeredAt: DateTime.parse(r['registered_at'] as String).toLocal(),
        ),
    ];
  }

  @override
  Future<Map<String, int>> seatsLeft(List<Webinar> webinars) async {
    final rows = await _client.rpc<List<dynamic>>(
      'webinar_seats_left',
      params: {
        'p_ids': [for (final w in webinars) w.id],
      },
    );
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['webinar_id'] as String: (r['seats_left'] as num).toInt(),
    };
  }

  @override
  Future<RegisterOutcome> register(String webinarId) async {
    final outcome = await _client.rpc<String>(
      'register_for_webinar',
      params: {'p_webinar_id': webinarId},
    );
    return outcome == 'full'
        ? RegisterOutcome.full
        : RegisterOutcome.registered;
  }

  @override
  Future<void> cancel(String webinarId) => _client.rpc<void>(
    'cancel_webinar_registration',
    params: {'p_webinar_id': webinarId},
  );

  @override
  Future<String?> joinLink(String webinarId) => _client.rpc<String?>(
    'webinar_join_link',
    params: {'p_webinar_id': webinarId},
  );

  @override
  Future<void> requestRecordingAlert(String webinarId) => _client
      .from('recording_alerts')
      .upsert({'webinar_id': webinarId}, ignoreDuplicates: true);

  @override
  Future<Set<String>> recordingAlerts() async {
    final rows = await _client.from('recording_alerts').select('webinar_id');
    return {for (final r in rows) r['webinar_id'] as String};
  }

  @override
  Future<List<InboxItem>> list() async {
    final rows = await _client
        .from('inbox_items')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    final items = [for (final r in rows) InboxItem.fromJson(r)];
    items.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  @override
  Future<void> markRead(String id) => _client
      .from('inbox_items')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', id)
      .isFilter('read_at', null);

  @override
  Future<void> markAllRead() => _client
      .from('inbox_items')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .isFilter('read_at', null);
}
