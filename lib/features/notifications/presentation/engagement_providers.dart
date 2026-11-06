import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/config/backend_config.dart';
import '../../../core/config/remote_config.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../profile/domain/profile_models.dart';
import '../../webinars/domain/webinar_models.dart';
import '../../webinars/presentation/webinar_providers.dart';
import '../data/local_engagement_backend.dart';
import '../data/reminder_scheduler.dart';
import '../data/supabase_engagement_backend.dart';
import '../domain/notification_models.dart';

/// Account-scoped registrations + inbox; null while logged out.
final engagementBackendProvider =
    Provider<(WebinarRegistrationRepository, InboxRepository)?>((ref) {
      final userId = ref.watch(authControllerProvider.select((s) => s.userId));
      if (userId == null) return null;
      switch (ref.watch(backendKindProvider)) {
        case BackendKind.supabase:
          final b = SupabaseEngagementBackend(Supabase.instance.client);
          return (b, b);
        case BackendKind.local:
          final b = LocalEngagementBackend(
            ref.watch(sharedPreferencesProvider),
            userId,
            catalogue: () =>
                ref.read(webinarRepositoryProvider).fetchWebinars(),
          );
          return (b, b);
        case BackendKind.none:
          return null;
      }
    });

final registrationsProvider = FutureProvider<List<WebinarRegistration>>((
  ref,
) async {
  final backend = ref.watch(engagementBackendProvider);
  if (backend == null) return const [];
  return backend.$1.myRegistrations();
});

final recordingAlertsProvider = FutureProvider<Set<String>>((ref) async {
  final backend = ref.watch(engagementBackendProvider);
  if (backend == null) return const {};
  return backend.$1.recordingAlerts();
});

/// The catalogue with live seat counts when signed in.
final webinarsWithSeatsProvider = FutureProvider<List<Webinar>>((ref) async {
  final webinars = await ref.watch(webinarsProvider.future);
  final backend = ref.watch(engagementBackendProvider);
  if (backend == null) return webinars;
  final seats = await backend.$1.seatsLeft(webinars);
  return [
    for (final w in webinars) w.withSeatsLeft(seats[w.id] ?? w.seatsLeft),
  ];
});

final webinarWithSeatsProvider = FutureProvider.family<Webinar, String>((
  ref,
  id,
) async {
  final all = await ref.watch(webinarsWithSeatsProvider.future);
  return all.firstWhere(
    (w) => w.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown webinar'),
  );
});

final joinLinkProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  final backend = ref.watch(engagementBackendProvider);
  if (backend == null) return null;
  return backend.$1.joinLink(id);
});

// ---- inbox -----------------------------------------------------------------

class InboxController extends AsyncNotifier<List<InboxItem>> {
  @override
  Future<List<InboxItem>> build() async {
    final backend = ref.watch(engagementBackendProvider);
    if (backend == null) return const [];
    return backend.$2.list();
  }

  Future<void> markRead(String id) async {
    await ref.read(engagementBackendProvider)?.$2.markRead(id);
    ref.invalidateSelf();
  }

  Future<void> markAllRead() async {
    await ref.read(engagementBackendProvider)?.$2.markAllRead();
    ref.invalidateSelf();
  }
}

final inboxProvider = AsyncNotifierProvider<InboxController, List<InboxItem>>(
  InboxController.new,
);

final unreadCountProvider = Provider<int>(
  (ref) => (ref.watch(inboxProvider).value ?? const [])
      .where((i) => !i.isRead)
      .length,
);

// ---- device preferences (NOT-02) -------------------------------------------

class NotificationPrefsController
    extends Notifier<Map<NotificationCategory, bool>> {
  static const _key = 'notification_prefs';

  @override
  Map<NotificationCategory, bool> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    final stored = raw == null
        ? const <String, Object?>{}
        : jsonDecode(raw) as Map<String, Object?>;
    return {
      for (final c in NotificationCategory.values) c: stored[c.name] != false,
    };
  }

  Future<void> set(NotificationCategory category, bool enabled) async {
    state = {...state, category: enabled};
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _key,
          jsonEncode({for (final e in state.entries) e.key.name: e.value}),
        );
  }
}

final notificationPrefsProvider =
    NotifierProvider<
      NotificationPrefsController,
      Map<NotificationCategory, bool>
    >(NotificationPrefsController.new);

// ---- reminders -------------------------------------------------------------

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return LocalReminderScheduler.instance;
  }
  return RecordingReminderScheduler(permitted: false);
});

/// OS-level permission (NOT-02 "permission trap").
final notificationPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderSchedulerProvider).isPermitted(),
);

/// Schedules and cancels the device reminders the app owns.
class ReminderPlanner {
  ReminderPlanner(this._ref);

  final Ref _ref;

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);

  bool _enabled(NotificationCategory c) =>
      _ref.read(notificationPrefsProvider)[c] ?? true;

  static String webinarKey(String id, String when) => 'webinar:$id:$when';
  static String measurementKey(String personId) => 'measure:$personId';

  /// 24 hours and 15 minutes before a registered webinar.
  Future<void> planWebinar(
    Webinar w, {
    required String title24h,
    required String title15m,
  }) async {
    await cancelWebinar(w.id);
    if (!_enabled(NotificationCategory.webinar)) return;
    final route = '/webinars/${w.id}';
    await _scheduler.schedule(
      Reminder(
        key: webinarKey(w.id, '24h'),
        at: w.startsAt.subtract(const Duration(hours: 24)),
        title: title24h,
        body: w.title,
        route: route,
      ),
    );
    await _scheduler.schedule(
      Reminder(
        key: webinarKey(w.id, '15m'),
        at: w.startsAt.subtract(Webinar.joinWindow),
        title: title15m,
        body: w.title,
        route: route,
      ),
    );
  }

  Future<void> cancelWebinar(String id) async {
    await _scheduler.cancel(webinarKey(id, '24h'));
    await _scheduler.cancel(webinarKey(id, '15m'));
  }

  /// When the next measurement is due for [person], given the latest one.
  DateTime dueDate(Person person, Measurement latest) {
    final days = _ref
        .read(remoteConfigProvider)
        .measurementReminderDays
        .forAgeMonths(person.ageMonthsAt(latest.measuredAt));
    final due = latest.measuredAt.add(Duration(days: days));
    return DateTime(due.year, due.month, due.day, 10);
  }

  Future<void> planMeasurement(
    Person person,
    Measurement latest, {
    required String title,
    required String body,
  }) async {
    await _scheduler.cancel(measurementKey(person.id));
    if (!_enabled(NotificationCategory.health)) return;
    await _scheduler.schedule(
      Reminder(
        key: measurementKey(person.id),
        at: dueDate(person, latest),
        title: title,
        body: body,
        route: '/bmi?p=${person.id}',
      ),
    );
  }
}

final reminderPlannerProvider = Provider<ReminderPlanner>(ReminderPlanner.new);
