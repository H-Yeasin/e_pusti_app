class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.number,
    required this.title,
    required this.minutes,
  });

  final String id;
  final int number;
  final String title;
  final int minutes;
}

class ChapterVideo {
  const ChapterVideo({
    required this.durationLabel,
    required this.sizeMb,
    this.url,
  });

  final String durationLabel;
  final double sizeMb;

  /// Null until the content server provides a stream.
  final String? url;
}

class Chapter {
  const Chapter({required this.summary, required this.paragraphs, this.video});

  final ChapterSummary summary;
  final List<String> paragraphs;
  final ChapterVideo? video;
}

/// Content source for the e-Pushti Academy (served from the VPS).
abstract interface class CourseRepository {
  Future<List<ChapterSummary>> fetchChapters();

  Future<Chapter> fetchChapter(String id);
}
