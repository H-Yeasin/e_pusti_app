import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../library_providers.dart';
import '../widgets/document_tile.dart';

/// LIB-03 (added to the design): downloaded files and the Wi-Fi queue, so a
/// "read later" request is always visible somewhere.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final queue = ref.watch(downloadQueueProvider).value ?? const {};
    final docs = ref.watch(libraryDocumentsProvider).value ?? const [];
    final entries = queue.values.toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    return Scaffold(
      appBar: EpAppBar(title: l10n.downloadsTitle),
      body: entries.isEmpty
          ? EpStateView(
              icon: Icons.download_outlined,
              title: l10n.downloadsEmptyTitle,
              body: l10n.downloadsEmptyBody,
              primaryLabel: l10n.homeLibrary,
              onPrimary: () => context.pop(),
            )
          : ListView(
              padding: const EdgeInsets.all(EpSpace.gutter),
              children: [
                for (final entry in entries)
                  if (docs.where((d) => d.id == entry.documentId).firstOrNull
                      case final doc?)
                    DocumentTile(
                      document: doc,
                      status: entry.status,
                      onTap: () => context.push(AppRoutes.document(doc.id)),
                      trailing: IconButton(
                        tooltip: l10n.removeAction,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => ref
                            .read(downloadQueueProvider.notifier)
                            .remove(doc.id),
                      ),
                    ),
              ],
            ),
    );
  }
}
