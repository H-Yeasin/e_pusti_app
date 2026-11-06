import 'package:flutter/material.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/library_models.dart';
import '../library_providers.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.status,
    required this.onTap,
    this.trailing,
  });

  final LibraryDocument document;
  final DownloadStatus? status;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meta = l10n.docMeta(
      document.sizeMb.toStringAsFixed(1),
      context.digits(document.pages),
    );
    final statusText = switch (status) {
      DownloadStatus.downloaded => l10n.docDownloaded,
      DownloadStatus.waitingForWifi => l10n.docWaitingWifi,
      DownloadStatus.pending => l10n.docPending,
      null => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: EpSpace.s2),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: EpColors.destructiveTint,
              borderRadius: EpRadius.smAll,
            ),
            child: const Text(
              'PDF',
              style: TextStyle(
                fontSize: EpTextSize.caption,
                fontWeight: FontWeight.w700,
                color: EpColors.destructiveStrong,
              ),
            ),
          ),
          title: Text(
            document.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(statusText == null ? meta : '$meta · $statusText'),
          trailing:
              trailing ??
              Icon(
                status == DownloadStatus.downloaded
                    ? Icons.check_circle_outline_rounded
                    : Icons.chevron_right_rounded,
                color: status == DownloadStatus.downloaded
                    ? EpColors.fillPrimary
                    : null,
              ),
          onTap: onTap,
        ),
      ),
    );
  }
}
