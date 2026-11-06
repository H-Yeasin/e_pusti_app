import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fixture_course_repository.dart';
import '../domain/course_models.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => const FixtureCourseRepository(),
);

final chaptersProvider = FutureProvider<List<ChapterSummary>>(
  (ref) => ref.watch(courseRepositoryProvider).fetchChapters(),
);

final chapterProvider = FutureProvider.family<Chapter, String>(
  (ref, id) => ref.watch(courseRepositoryProvider).fetchChapter(id),
);

/// Chapters whose text the user has opened (SYS-01 "text of chapters you've
/// read"). Local only; progress sync arrives with accounts.
class ReadChaptersController extends AsyncNotifier<Set<String>> {
  static const _key = 'read_chapter_ids';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> markRead(String id) async {
    final current = state.value ?? await future;
    if (current.contains(id)) {
      return;
    }
    final next = {...current, id};
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final readChaptersProvider =
    AsyncNotifierProvider<ReadChaptersController, Set<String>>(
      ReadChaptersController.new,
    );
