import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_routes.dart';
import '../profile/domain/profile_models.dart';

enum JourneyStage { pregnancy, breastfeeding }

class JourneyState {
  const JourneyState({required this.stage, this.week, this.dueDate, this.baby});

  final JourneyStage stage;

  /// Pregnancy: gestational week (1–42). Breastfeeding: baby's age in weeks.
  /// Null when the date it depends on is missing.
  final int? week;
  final DateTime? dueDate;
  final Person? baby;

  int? get trimester {
    final w = week;
    if (stage != JourneyStage.pregnancy || w == null) return null;
    return w <= 13 ? 1 : (w <= 27 ? 2 : 3);
  }
}

/// Gestational week from the expected due date (due date = 40 weeks).
int pregnancyWeek(DateTime dueDate, DateTime now) {
  final conception = DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
  ).subtract(const Duration(days: 280));
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(conception).inDays;
  return (days ~/ 7 + 1).clamp(1, 42);
}

/// The journey for the account holder, if pregnant or breastfeeding.
/// Breastfeeding follows the youngest child under two.
JourneyState? journeyFor(List<Person> family, DateTime now) {
  final holder = family.where((p) => p.isHolder).firstOrNull;
  if (holder == null) return null;
  if (holder.pregnant) {
    final due = holder.expectedDueDate;
    return JourneyState(
      stage: JourneyStage.pregnancy,
      dueDate: due,
      week: due == null ? null : pregnancyWeek(due, now),
    );
  }
  if (holder.breastfeeding) {
    final babies =
        family
            .where(
              (p) =>
                  p.relationship == Relationship.child &&
                  (p.ageMonthsAt(now) ?? 99) < 24,
            )
            .toList()
          ..sort((a, b) => b.dateOfBirth!.compareTo(a.dateOfBirth!));
    final baby = babies.firstOrNull;
    return JourneyState(
      stage: JourneyStage.breastfeeding,
      baby: baby,
      week: baby == null
          ? null
          : DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).difference(baby.dateOfBirth!).inDays ~/
                7,
    );
  }
  return null;
}

/// Upcoming antenatal contacts from the configured schedule.
List<(int week, DateTime date)> upcomingContacts(
  DateTime dueDate,
  List<int> weeks,
  DateTime now,
) {
  final conception = dueDate.subtract(const Duration(days: 280));
  return [
    for (final w in [...weeks]..sort())
      if (conception.add(Duration(days: (w - 1) * 7)) case final date
          when !date.isBefore(DateTime(now.year, now.month, now.day)))
        (w, DateTime(date.year, date.month, date.day, 10)),
  ];
}

class JourneyEntry {
  const JourneyEntry({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

/// Week-by-week guidance. No reviewed content exists yet, so the fixture
/// returns nothing and the screen says the guidance is coming.
abstract interface class JourneyContentRepository {
  Future<JourneyEntry?> entryFor(JourneyStage stage, int week);
}

class EmptyJourneyContentRepository implements JourneyContentRepository {
  const EmptyJourneyContentRepository();

  @override
  Future<JourneyEntry?> entryFor(JourneyStage stage, int week) async => null;
}

final journeyContentRepositoryProvider = Provider<JourneyContentRepository>(
  (ref) => const EmptyJourneyContentRepository(),
);

final journeyEntryProvider =
    FutureProvider.family<JourneyEntry?, (JourneyStage, int)>(
      (ref, key) =>
          ref.watch(journeyContentRepositoryProvider).entryFor(key.$1, key.$2),
    );

/// Existing app content relevant to each stage (from the fixtures).
const journeyResources = {
  JourneyStage.pregnancy: [
    ('গর্ভকালীন পুষ্টি নির্দেশিকা', '${AppRoutes.library}/doc/d2'),
    ('শিশুর প্রথম ১০০০ দিন', '${AppRoutes.library}/doc/d4'),
  ],
  JourneyStage.breastfeeding: [
    ('শিশু পুষ্টি ও স্তন্যপান চর্চা', '${AppRoutes.digiSkills}/m3'),
    ('শিশুর প্রথম ১০০০ দিন', '${AppRoutes.library}/doc/d4'),
  ],
};
