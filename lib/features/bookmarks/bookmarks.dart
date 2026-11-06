import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_preferences.dart';
import '../../core/localization/localization.dart';
import '../search/search_index.dart';

class Bookmark {
  const Bookmark({
    required this.kind,
    required this.id,
    required this.title,
    required this.route,
    required this.savedAt,
  });

  final SearchKind kind;
  final String id;
  final String title;
  final String route;
  final DateTime savedAt;

  String get key => '${kind.name}:$id';

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'id': id,
    'title': title,
    'route': route,
    'at': savedAt.toIso8601String(),
  };

  static Bookmark? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = SearchKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final at = DateTime.tryParse('${json['at']}');
    if (kind == null || at == null) return null;
    return Bookmark(
      kind: kind,
      id: '${json['id']}',
      title: '${json['title']}',
      route: '${json['route']}',
      savedAt: at,
    );
  }
}

/// P2-5: saved chapters, modules, documents and webinars. Kept on the
/// device, so it works logged out and offline.
class BookmarksController extends Notifier<List<Bookmark>> {
  static const _key = 'bookmarks';

  @override
  List<Bookmark> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final b in (jsonDecode(raw) as List<Object?>).map(
          Bookmark.fromJson,
        ))
          ?b,
      ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return const [];
    }
  }

  bool isSaved(SearchKind kind, String id) =>
      state.any((b) => b.kind == kind && b.id == id);

  Future<void> toggle(Bookmark bookmark) async {
    state = isSaved(bookmark.kind, bookmark.id)
        ? state.where((b) => b.key != bookmark.key).toList()
        : [bookmark, ...state];
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode([for (final b in state) b.toJson()]));
  }
}

final bookmarksProvider = NotifierProvider<BookmarksController, List<Bookmark>>(
  BookmarksController.new,
);

/// App-bar toggle used on chapter, module, document and webinar screens.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    super.key,
    required this.kind,
    required this.id,
    required this.title,
    required this.route,
  });

  final SearchKind kind;
  final String id;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(bookmarksProvider);
    final saved = ref.read(bookmarksProvider.notifier).isSaved(kind, id);
    return IconButton(
      key: ValueKey('bookmark-${kind.name}-$id'),
      tooltip: saved ? l10n.bookmarkRemove : l10n.bookmarkAdd,
      isSelected: saved,
      icon: Icon(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      ),
      onPressed: () async {
        await ref
            .read(bookmarksProvider.notifier)
            .toggle(
              Bookmark(
                kind: kind,
                id: id,
                title: title,
                route: route,
                savedAt: DateTime.now(),
              ),
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(saved ? l10n.bookmarkRemoved : l10n.bookmarkSaved),
            ),
          );
      },
    );
  }
}
