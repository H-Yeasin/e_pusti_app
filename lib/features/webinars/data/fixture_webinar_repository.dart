import '../domain/webinar_models.dart';

/// Sample webinars from WEB-01 / WEB-02, dated relative to [now] so the
/// upcoming/past split always makes sense.
class FixtureWebinarRepository implements WebinarRepository {
  FixtureWebinarRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  List<Webinar> _all() {
    final today = _clock();
    DateTime day(int offset, int hour) =>
        DateTime(today.year, today.month, today.day + offset, hour);
    return [
      Webinar(
        id: 'w1',
        title: 'National Nutrition Week',
        description:
            'জাতীয় পুষ্টি সপ্তাহ উপলক্ষে পরিবারের জন্য সুষম খাদ্য পরিকল্পনা নিয়ে আলোচনা।',
        startsAt: day(7, 10),
        durationMinutes: 60,
        speaker: 'ডা. ফারহানা হক',
        speakerRole: 'পুষ্টিবিদ',
        capacity: 50,
        seatsLeft: 8,
      ),
      Webinar(
        id: 'w2',
        title: 'Safe Food Handling at Home',
        startsAt: day(19, 16),
        durationMinutes: 60,
        capacity: 40,
        seatsLeft: 0,
      ),
      Webinar(
        id: 'w3',
        title: 'Breastfeeding Week',
        startsAt: day(-30, 11),
        durationMinutes: 60,
        capacity: 50,
        seatsLeft: 0,
        hasRecording: true,
      ),
      Webinar(
        id: 'w4',
        title: 'Adolescent Nutrition',
        startsAt: day(-50, 11),
        durationMinutes: 60,
        capacity: 50,
        seatsLeft: 12,
      ),
    ];
  }

  @override
  Future<List<Webinar>> fetchWebinars() async => _all();

  @override
  Future<Webinar> fetchWebinar(String id) async => _all().firstWhere(
    (w) => w.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown webinar'),
  );
}
