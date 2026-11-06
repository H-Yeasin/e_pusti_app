import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/localization.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/feedback/ep_state_view.dart';
import '../../core/widgets/navigation/ep_app_bar.dart';
import '../search/presentation/search_screen.dart';
import 'bookmarks.dart';

/// P2-5: everything the user saved.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.savedTitle),
      body: saved.isEmpty
          ? EpStateView(
              key: const ValueKey('saved-empty'),
              icon: Icons.bookmark_border_rounded,
              title: l10n.savedEmptyTitle,
              body: l10n.savedEmptyBody,
            )
          : ListView.separated(
              itemCount: saved.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = saved[i];
                return Dismissible(
                  key: ValueKey(b.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: EpColors.destructiveTint,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.only(right: EpSpace.s5),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: EpColors.destructiveFill,
                    ),
                  ),
                  onDismissed: (_) =>
                      ref.read(bookmarksProvider.notifier).toggle(b),
                  child: ListTile(
                    leading: Icon(
                      searchKindIcon(b.kind),
                      color: EpColors.green700,
                    ),
                    title: Text(b.title),
                    subtitle: Text(searchKindLabel(context, b.kind)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(b.route),
                  ),
                );
              },
            ),
    );
  }
}
