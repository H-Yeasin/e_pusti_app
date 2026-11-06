class LibraryCategory {
  const LibraryCategory({required this.id, required this.title});

  final String id;
  final String title;
}

class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.sizeMb,
    required this.pages,
    this.url,
  });

  final String id;
  final String title;
  final String categoryId;
  final double sizeMb;
  final int pages;

  /// Null until the content server provides the file.
  final String? url;
}

/// Files above this size ask before spending mobile data (LIB-02).
const largeDocumentThresholdMb = 3.0;

abstract interface class LibraryRepository {
  Future<List<LibraryCategory>> fetchCategories();

  Future<List<LibraryDocument>> fetchDocuments();
}
