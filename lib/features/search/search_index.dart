import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_routes.dart';
import '../../core/localization/digits.dart';
import '../courses/presentation/course_providers.dart';
import '../library/presentation/library_providers.dart';
import '../assessment/presentation/learning_providers.dart';
import '../webinars/presentation/webinar_providers.dart';

enum SearchKind { chapter, module, document, webinar }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.route,
    this.snippet,
  });

  final SearchKind kind;
  final String id;
  final String title;
  final String route;

  /// The matching sentence from the text, when the match wasn't the title.
  final String? snippet;
}

/// Normalises for matching: lower case, Bangla digits as ASCII.
String _norm(String s) => normalizeDigits(s).toLowerCase();

/// Finds [query] in [text] and returns the surrounding sentence.
String? snippetFor(String text, String query, {int radius = 40}) {
  final i = _norm(text).indexOf(_norm(query));
  if (i < 0) return null;
  final start = (i - radius).clamp(0, text.length);
  final end = (i + query.length + radius).clamp(0, text.length);
  return '${start > 0 ? '…' : ''}${text.substring(start, end).trim()}'
      '${end < text.length ? '…' : ''}';
}

/// HOM-03 (added): one search across chapters, modules, documents and
/// webinars. Uses the content repositories, so it works offline for content
/// already on the device; a server search endpoint can replace it later.
final searchProvider = FutureProvider.family<List<SearchHit>, String>((
  ref,
  rawQuery,
) async {
  final query = rawQuery.trim();
  if (query.length < 2) return const [];
  final q = _norm(query);
  bool hit(String s) => _norm(s).contains(q);
  final hits = <SearchHit>[];

  final courses = ref.watch(courseRepositoryProvider);
  for (final c in await courses.fetchChapters()) {
    String? snippet;
    if (!hit(c.title)) {
      try {
        final chapter = await courses.fetchChapter(c.id);
        snippet = chapter.paragraphs
            .map((p) => snippetFor(p, query))
            .nonNulls
            .firstOrNull;
      } catch (_) {
        // Text not reachable: title-only search for this chapter.
      }
      if (snippet == null) continue;
    }
    hits.add(
      SearchHit(
        kind: SearchKind.chapter,
        id: c.id,
        title: c.title,
        route: AppRoutes.chapter(c.id),
        snippet: snippet,
      ),
    );
  }

  try {
    final modules = await ref.watch(modulesProvider.future);
    for (final m in modules.modules.where((m) => hit(m.title))) {
      hits.add(
        SearchHit(
          kind: SearchKind.module,
          id: m.id,
          title: m.title,
          route: AppRoutes.module(m.id),
        ),
      );
    }
  } catch (_) {
    // Content server down: skip modules.
  }

  final docs = await ref.watch(libraryRepositoryProvider).fetchDocuments();
  for (final d in docs.where((d) => hit(d.title))) {
    hits.add(
      SearchHit(
        kind: SearchKind.document,
        id: d.id,
        title: d.title,
        route: AppRoutes.document(d.id),
      ),
    );
  }

  final webinars = await ref.watch(webinarRepositoryProvider).fetchWebinars();
  for (final w in webinars.where(
    (w) => hit(w.title) || hit(w.description ?? '') || hit(w.speaker ?? ''),
  )) {
    hits.add(
      SearchHit(
        kind: SearchKind.webinar,
        id: w.id,
        title: w.title,
        route: AppRoutes.webinar(w.id),
        snippet: hit(w.title) ? null : snippetFor(w.description ?? '', query),
      ),
    );
  }
  return hits;
});
