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
