import 'package:flutter/material.dart';
import '../../../share/share_actions.dart';
import '../../../search/search_index.dart';
import '../../../bookmarks/bookmarks.dart';
import '../../../../app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/commercial/ad_slot.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/library_models.dart';
import '../library_providers.dart';

/// LIB-02. Large files ask before spending mobile data; "read later on
/// Wi-Fi" queues the download instead of declining.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  bool _consented = false;

  Future<void> _queue(LibraryDocument doc, {required bool wifiOnly}) async {
    final l10n = context.l10n;
    await ref
        .read(downloadQueueProvider.notifier)
        .request(doc.id, wifiOnly: wifiOnly);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(wifiOnly ? l10n.queuedForWifiToast : l10n.queuedToast),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = ref.watch(libraryDocumentsProvider);
    final doc = documents.value
        ?.where((d) => d.id == widget.documentId)
        .firstOrNull;
    final onWifi = ref.watch(isOnWifiProvider).value ?? false;

    return Scaffold(
      appBar: EpAppBar(
        title: doc?.title ?? l10n.homeLibrary,
        actions: [
          if (doc != null) ...[
            BookmarkButton(
              kind: SearchKind.document,
              id: doc.id,
              title: doc.title,
              route: AppRoutes.document(doc.id),
            ),
            IconButton(
              tooltip: l10n.shareAction,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareInAppLink(
                context,
                ref,
                title: doc.title,
                route: AppRoutes.document(doc.id),
              ),
            ),
          ],
        ],
      ),
      body: EpAsyncView(
        value: documents,
        onRetry: () => ref.invalidate(libraryDocumentsProvider),
        data: (_) {
          if (doc == null) {
            return EpStateView(
              icon: Icons.description_outlined,
              title: l10n.libraryNoResultsTitle,
              body: '',
            );
          }
          final needsConsent =
              doc.sizeMb > largeDocumentThresholdMb && !onWifi && !_consented;
          return needsConsent
              ? _LargeFileConsent(
                  document: doc,
                  onOpen: () => setState(() => _consented = true),
                  onLater: () => _queue(doc, wifiOnly: true),
                )
              : _Viewer(
                  document: doc,
                  onDownload: () => _queue(doc, wifiOnly: false),
                );
        },
      ),
    );
  }
}

class _LargeFileConsent extends StatelessWidget {
  const _LargeFileConsent({
    required this.document,
    required this.onOpen,
    required this.onLater,
  });

  final LibraryDocument document;
  final VoidCallback onOpen;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = context.digits(document.sizeMb.toStringAsFixed(1));
    return ListView(
      padding: const EdgeInsets.all(EpSpace.gutter),
      children: [
        EpBanner(
          key: const ValueKey('doc-large-consent'),
          icon: Icons.data_usage_rounded,
          message: l10n.docLargeNote(size),
        ),
        const SizedBox(height: EpSpace.s4),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(document.title),
            subtitle: Text(
              l10n.docMeta(
                document.sizeMb.toStringAsFixed(1),
                context.digits(document.pages),
              ),
            ),
          ),
        ),
        const SizedBox(height: EpSpace.s6),
        FilledButton(onPressed: onOpen, child: Text(l10n.openAction)),
        const SizedBox(height: EpSpace.s2),
        OutlinedButton(onPressed: onLater, child: Text(l10n.readLaterWifi)),
      ],
    );
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer({required this.document, required this.onDownload});

  final LibraryDocument document;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = document.url;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EpSpace.gutter,
            vertical: EpSpace.s2,
          ),
          child: Row(
            children: [
              Text(
                l10n.pageCounter(
                  context.digits(1),
                  context.digits(document.pages),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.downloadAction),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          // A PDF renderer is attached once documents carry file URLs.
          child: url == null
              ? EpStateView(
                  icon: Icons.description_outlined,
                  title: l10n.docPreviewUnavailableTitle,
                  body: l10n.docPreviewUnavailableBody,
                )
              : EpStateView(
                  icon: Icons.open_in_new_rounded,
                  title: document.title,
                  body: '',
                  primaryLabel: l10n.openAction,
                  onPrimary: () => Launcher.web(context, url),
                ),
        ),
        const AdSlot(
          id: AdSlotId.viewerFooter,
          padding: EdgeInsets.all(EpSpace.gutter),
        ),
      ],
    );
  }
}
