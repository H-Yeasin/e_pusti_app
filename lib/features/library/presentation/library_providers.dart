import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fixture_library_repository.dart';
import '../domain/library_models.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => const FixtureLibraryRepository(),
);

final libraryCategoriesProvider = FutureProvider<List<LibraryCategory>>(
  (ref) => ref.watch(libraryRepositoryProvider).fetchCategories(),
);

final libraryDocumentsProvider = FutureProvider<List<LibraryDocument>>(
  (ref) => ref.watch(libraryRepositoryProvider).fetchDocuments(),
);

enum DownloadStatus {
  /// "Read later on Wi-Fi": queued, starts when on Wi-Fi.
  waitingForWifi,

  /// Requested; waiting for the file to become available / transfer to run.
  pending,

  /// On the device and readable offline.
  downloaded,
}

class DownloadEntry {
  const DownloadEntry({
    required this.documentId,
    required this.status,
    required this.requestedAt,
  });

  final String documentId;
  final DownloadStatus status;
  final DateTime requestedAt;

  Map<String, Object> toJson() => {
    'id': documentId,
    'status': status.name,
    'at': requestedAt.toIso8601String(),
  };

  static DownloadEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final status = DownloadStatus.values
        .where((s) => s.name == json['status'])
        .firstOrNull;
    final at = DateTime.tryParse('${json['at']}');
    final id = json['id'];
    if (status == null || at == null || id is! String) return null;
    return DownloadEntry(documentId: id, status: status, requestedAt: at);
  }
}

/// The download queue behind LIB-02 "read later on Wi-Fi" and LIB-03.
///
/// It records what the user asked for and survives restarts. The transfer
/// itself is wired once documents have real file URLs.
class DownloadQueueController
    extends AsyncNotifier<Map<String, DownloadEntry>> {
  static const _key = 'library_download_queue';

  @override
  Future<Map<String, DownloadEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<Object?>;
      return {
        for (final entry in list.map(DownloadEntry.fromJson).nonNulls)
          entry.documentId: entry,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> request(String documentId, {required bool wifiOnly}) {
    return _update((queue) {
      final existing = queue[documentId];
      if (existing?.status == DownloadStatus.downloaded) return;
      queue[documentId] = DownloadEntry(
        documentId: documentId,
        status: wifiOnly
            ? DownloadStatus.waitingForWifi
            : DownloadStatus.pending,
        requestedAt: DateTime.now(),
      );
    });
  }

  Future<void> remove(String documentId) =>
      _update((queue) => queue.remove(documentId));

  Future<void> _update(void Function(Map<String, DownloadEntry>) change) async {
    final next = {...(state.value ?? await future)};
    change(next);
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final e in next.values) e.toJson()]),
    );
  }
}

final downloadQueueProvider =
    AsyncNotifierProvider<DownloadQueueController, Map<String, DownloadEntry>>(
      DownloadQueueController.new,
    );

final downloadedCountProvider = Provider<int>((ref) {
  final queue = ref.watch(downloadQueueProvider).value ?? const {};
  return queue.values
      .where((e) => e.status == DownloadStatus.downloaded)
      .length;
});
