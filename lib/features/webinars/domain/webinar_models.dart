class Webinar {
  const Webinar({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.durationMinutes,
    required this.capacity,
    required this.seatsLeft,
    this.description,
    this.speaker,
    this.speakerRole,
    this.hasRecording = false,
    this.recordingUrl,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startsAt;
  final int durationMinutes;
  final String? speaker;
  final String? speakerRole;
  final int capacity;
  final int seatsLeft;
  final bool hasRecording;

  /// External player link (YouTube / Zoom) once published.
  final String? recordingUrl;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  /// The join link is revealed this long before the start.
  static const joinWindow = Duration(minutes: 15);

  bool isJoinable(DateTime now) =>
      !now.isBefore(startsAt.subtract(joinWindow)) && now.isBefore(endsAt);

  Webinar withSeatsLeft(int seats) => Webinar(
    id: id,
    title: title,
    description: description,
    startsAt: startsAt,
    durationMinutes: durationMinutes,
    speaker: speaker,
    speakerRole: speakerRole,
    capacity: capacity,
    seatsLeft: seats,
    hasRecording: hasRecording,
    recordingUrl: recordingUrl,
  );

  bool isPast(DateTime now) =>
      startsAt.add(Duration(minutes: durationMinutes)).isBefore(now);

  bool get isFull => seatsLeft <= 0;

  /// Low-seat emphasis threshold ("only 3 seats left").
  bool get isAlmostFull => seatsLeft > 0 && seatsLeft <= 5;
}

abstract interface class WebinarRepository {
  Future<List<Webinar>> fetchWebinars();

  Future<Webinar> fetchWebinar(String id);
}

class WebinarRegistration {
  const WebinarRegistration({
    required this.webinarId,
    required this.registeredAt,
  });

  final String webinarId;
  final DateTime registeredAt;
}

enum RegisterOutcome {
  registered,

  /// Seats ran out — the app distinguishes "full before the tap" from
  /// "lost the last seat during it" by what it showed the user.
  full,
}

/// Registrations live in Supabase, where capacity is enforced in a
/// transaction. The catalogue itself comes from the content server.
abstract interface class WebinarRegistrationRepository {
  Future<List<WebinarRegistration>> myRegistrations();

  /// Seats currently left, by webinar id.
  Future<Map<String, int>> seatsLeft(List<Webinar> webinars);

  Future<RegisterOutcome> register(String webinarId);

  Future<void> cancel(String webinarId);

  /// Null until [Webinar.joinWindow] before the start, and only for
  /// registered users.
  Future<String?> joinLink(String webinarId);

  /// "Tell me about the recording" (WEB-02 full).
  Future<void> requestRecordingAlert(String webinarId);

  Future<Set<String>> recordingAlerts();
}
