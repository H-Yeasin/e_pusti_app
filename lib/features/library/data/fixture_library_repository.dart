import '../domain/library_models.dart';

/// Sample library entries from the LIB-01 / LIB-02 design until the
/// content API exists. No files are attached (`url` is null).
class FixtureLibraryRepository implements LibraryRepository {
  const FixtureLibraryRepository();

  @override
  Future<List<LibraryCategory>> fetchCategories() async => const [
    LibraryCategory(id: 'sbcc', title: 'SBCC পোস্টার'),
    LibraryCategory(id: 'guides', title: 'নির্দেশিকা'),
    LibraryCategory(id: 'reports', title: 'প্রতিবেদন'),
  ];

  @override
  Future<List<LibraryDocument>> fetchDocuments() async => const [
    LibraryDocument(
      id: 'd1',
      title: 'সুষম খাদ্য পিরামিড',
      categoryId: 'sbcc',
      sizeMb: 1.2,
      pages: 2,
    ),
    LibraryDocument(
      id: 'd2',
      title: 'গর্ভকালীন পুষ্টি নির্দেশিকা',
      categoryId: 'sbcc',
      sizeMb: 1.3,
      pages: 4,
    ),
    LibraryDocument(
      id: 'd3',
      title: 'হাত ধোয়ার সঠিক নিয়ম',
      categoryId: 'sbcc',
      sizeMb: 1.1,
      pages: 1,
    ),
    LibraryDocument(
      id: 'd4',
      title: 'শিশুর প্রথম ১০০০ দিন',
      categoryId: 'sbcc',
      sizeMb: 1.4,
      pages: 6,
    ),
    LibraryDocument(
      id: 'd5',
      title: 'নিরাপদ পানি সংরক্ষণ',
      categoryId: 'sbcc',
      sizeMb: 0.9,
      pages: 2,
    ),
    LibraryDocument(
      id: 'd6',
      title: 'বার্ষিক প্রতিবেদন ২০২৫',
      categoryId: 'reports',
      sizeMb: 4.1,
      pages: 32,
    ),
  ];
}
