import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/commercial/ad_slot.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/library_models.dart';
import '../library_providers.dart';
import '../widgets/document_tile.dart';

/// LIB-01. Size sits on every row; search with a way out when nothing
/// matches.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() {
      _searching = false;
      _categoryId = null;
    });
  }

  Future<void> _pickCategory(List<LibraryCategory> categories) async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.libraryAllCategories),
              trailing: _categoryId == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final c in categories)
              ListTile(
                title: Text(c.title),
                trailing: _categoryId == c.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _categoryId = picked.isEmpty ? null : picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = ref.watch(libraryDocumentsProvider);
    final categories =
        ref.watch(libraryCategoriesProvider).value ?? const <LibraryCategory>[];
    final queue = ref.watch(downloadQueueProvider).value ?? const {};
    final query = _search.text.trim();

    return Scaffold(
      appBar: EpAppBar(
        title: l10n.homeLibrary,
        actions: [
          IconButton(
            tooltip: l10n.downloadsTitle,
            onPressed: () => context.push(AppRoutes.downloads),
            icon: const Icon(Icons.download_done_rounded),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _search.clear();
            }),
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
          ),
        ],
      ),
      body: EpAsyncView(
        value: documents,
        onRetry: () => ref.invalidate(libraryDocumentsProvider),
        data: (all) {
          final filtered = all.where((d) {
            final inCategory =
                _categoryId == null || d.categoryId == _categoryId;
            final matches =
                query.isEmpty ||
                d.title.toLowerCase().contains(query.toLowerCase());
            return inCategory && matches;
          }).toList();
          final categoryTitle =
              categories.where((c) => c.id == _categoryId).firstOrNull?.title ??
              l10n.libraryAllCategories;

          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              const AdSlot(
                id: AdSlotId.libraryHeader,
                padding: EdgeInsets.only(bottom: EpSpace.s4),
              ),
              if (_searching) ...[
                TextField(
                  key: const ValueKey('library-search'),
                  controller: _search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: l10n.librarySearchHint,
                    filled: true,
                    fillColor: EpColors.surface,
                    border: const OutlineInputBorder(
                      borderRadius: EpRadius.mdAll,
                    ),
                  ),
                ),
                const SizedBox(height: EpSpace.s3),
              ],
              Row(
                children: [
                  Flexible(
                    child: OutlinedButton.icon(
                      key: const ValueKey('library-category'),
                      onPressed: () => _pickCategory(categories),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: Text(
                        categoryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: EpSpace.s3),
                  Text(
                    l10n.libraryDocCount(context.digits(filtered.length)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: EpSpace.s3),
              if (filtered.isEmpty)
                SizedBox(
                  height: 360,
                  child: EpStateView(
                    icon: Icons.search_off_rounded,
                    title: l10n.libraryNoResultsTitle,
                    body: l10n.libraryNoResultsBody(query),
                    primaryLabel: l10n.librarySeeAll,
                    onPrimary: _reset,
                  ),
                )
              else
                for (final doc in filtered)
                  DocumentTile(
                    document: doc,
                    status: queue[doc.id]?.status,
                    onTap: () => context.push(AppRoutes.document(doc.id)),
                  ),
            ],
          );
        },
      ),
    );
  }
}
