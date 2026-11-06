import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/config/app_preferences.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/feedback/ep_async_view.dart';
import '../../../core/widgets/feedback/ep_state_view.dart';
import '../search_index.dart';

IconData searchKindIcon(SearchKind kind) => switch (kind) {
  SearchKind.chapter => Icons.menu_book_outlined,
  SearchKind.module => Icons.auto_awesome_outlined,
  SearchKind.document => Icons.description_outlined,
  SearchKind.webinar => Icons.videocam_outlined,
};

String searchKindLabel(BuildContext context, SearchKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    SearchKind.chapter => l10n.homeCourse,
    SearchKind.module => l10n.homeDigiSkill,
    SearchKind.document => l10n.homeLibrary,
    SearchKind.webinar => l10n.homeWebinar,
  };
}

/// HOM-03: one search across the app's content, with recent searches and a
/// way out when nothing matches.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentKey = 'recent_searches';
  final _field = TextEditingController();
  Timer? _debounce;
  String _query = '';

  List<String> get _recent =>
      ref.read(sharedPreferencesProvider).getStringList(_recentKey) ?? const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _use(String query) {
    _field.text = query;
    _field.selection = TextSelection.collapsed(offset: query.length);
    setState(() => _query = query);
  }

  Future<void> _remember(String query) async {
    final next = [query, ..._recent.where((q) => q != query)].take(5).toList();
    await ref.read(sharedPreferencesProvider).setStringList(_recentKey, next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('global-search'),
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: EpColors.n0),
          cursorColor: EpColors.n0,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: const TextStyle(color: EpColors.green100),
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (v) => _use(v.trim()),
        ),
        actions: [
          if (_field.text.isNotEmpty)
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _field.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.length < 2 ? _recentList(context) : _results(context),
    );
  }

  Widget _recentList(BuildContext context) {
    final l10n = context.l10n;
    final recent = _recent;
    if (recent.isEmpty) {
      return EpStateView(
        icon: Icons.search_rounded,
        title: l10n.searchPromptTitle,
        body: l10n.searchPromptBody,
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EpSpace.gutter,
            EpSpace.s4,
            EpSpace.gutter,
            EpSpace.s1,
          ),
          child: Text(
            l10n.searchRecent,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final q in recent)
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(q),
            onTap: () => _use(q),
          ),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    final results = ref.watch(searchProvider(_query));
    return EpAsyncView(
      value: results,
      onRetry: () => ref.invalidate(searchProvider(_query)),
      data: (hits) {
        if (hits.isEmpty) {
          return EpStateView(
            key: const ValueKey('search-empty'),
            icon: Icons.search_off_rounded,
            title: l10n.libraryNoResultsTitle,
            body: l10n.searchNoResults(_query),
            primaryLabel: l10n.homeLibrary,
            onPrimary: () => context.push(AppRoutes.library),
            secondaryLabel: l10n.homeCourse,
            onSecondary: () => context.push(AppRoutes.courses),
          );
        }
        return ListView.separated(
          itemCount: hits.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = hits[i];
            return ListTile(
              leading: Icon(searchKindIcon(h.kind), color: EpColors.green700),
              title: Text(h.title),
              subtitle: Text(
                [searchKindLabel(context, h.kind), ?h.snippet].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                _remember(_query);
                context.push(h.route);
              },
            );
          },
        );
      },
    );
  }
}
