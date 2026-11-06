import '../domain/course_models.dart';

/// Sample academy content until the VPS content API exists. Chapter titles
/// and durations follow CRS-01; chapter 3 text is from the CRS-02 design.
/// The other chapters carry a placeholder line, not invented health content.
class FixtureCourseRepository implements CourseRepository {
  const FixtureCourseRepository();

  static const _placeholder =
      'নমুনা কনটেন্ট — চূড়ান্ত অধ্যায়ের লেখা কনটেন্ট সার্ভার থেকে আসবে।';

  static const _chapters = [
    ChapterSummary(id: 'c1', number: 1, title: 'খাদ্য ও পুষ্টি', minutes: 14),
    ChapterSummary(
      id: 'c2',
      number: 2,
      title: 'নিরাপদ খাদ্য ও অপচয়',
      minutes: 11,
    ),
    ChapterSummary(
      id: 'c3',
      number: 3,
      title: 'স্বাস্থ্যসম্মত জীবনধারা',
      minutes: 16,
    ),
    ChapterSummary(id: 'c4', number: 4, title: 'মানসিক স্বাস্থ্য', minutes: 12),
    ChapterSummary(id: 'c5', number: 5, title: 'নেতৃত্ব', minutes: 9),
    ChapterSummary(id: 'c6', number: 6, title: 'সামাজিক বিষয়', minutes: 13),
  ];

  @override
  Future<List<ChapterSummary>> fetchChapters() async => _chapters;

  @override
  Future<Chapter> fetchChapter(String id) async {
    final summary = _chapters.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown chapter'),
    );
    if (id == 'c3') {
      return Chapter(
        summary: summary,
        video: const ChapterVideo(durationLabel: '8:24', sizeMb: 12.4),
        paragraphs: const [
          'সুস্থ থাকতে হলে শুধু খাবার নয় — ঘুম, চলাফেরা ও মানসিক প্রশান্তিও সমান গুরুত্বপূর্ণ। এই অধ্যায়ে আমরা দৈনন্দিন অভ্যাসের কয়েকটি সহজ পরিবর্তন নিয়ে আলোচনা করব।',
          'প্রতিদিন অন্তত ৩০ মিনিট হাঁটা, পর্যাপ্ত পানি পান এবং নিয়মিত ঘুম — এই তিনটি অভ্যাস...',
          _placeholder,
        ],
      );
    }
    return Chapter(summary: summary, paragraphs: const [_placeholder]);
  }
}
