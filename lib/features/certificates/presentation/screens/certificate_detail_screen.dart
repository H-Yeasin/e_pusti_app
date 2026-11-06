import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../domain/certificate_models.dart';
import '../widgets/certificate_card.dart';

/// CRT-02 — QR + code, PDF and share; a revoked certificate is shown as
/// revoked, never silently hidden.
class CertificateDetailScreen extends ConsumerStatefulWidget {
  const CertificateDetailScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState
    extends ConsumerState<CertificateDetailScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  /// Captures the on-screen card (so Bangla is shaped correctly) into a
  /// one-page PDF in the temp folder.
  Future<File> _buildPdf(Certificate c) async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final doc = pw.Document(title: c.title, author: 'BIID Foundation');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Center(
          child: pw.Image(pw.MemoryImage(bytes!.buffer.asUint8List())),
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/e-pushti-${c.code}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> _sharePdf(Certificate c) async {
    setState(() => _busy = true);
    try {
      final file = await _buildPdf(c);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          title: c.title,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText(Certificate c, String? verifyUrl) {
    final l10n = context.l10n;
    final text = [
      l10n.shareCertificateText(c.title, c.code),
      ?verifyUrl,
    ].join('\n');
    return SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final certificate = ref.watch(certificateProvider(widget.code));
    final base = ref.watch(remoteConfigProvider.select((c) => c.verifyBaseUrl));

    return Scaffold(
      appBar: EpAppBar(title: l10n.certificateTitle),
      body: EpAsyncView(
        value: certificate,
        onRetry: () => ref.invalidate(certificateProvider(widget.code)),
        data: (c) {
          if (c == null) {
            return EpStateView(
              icon: Icons.search_off_rounded,
              title: l10n.certificateNotFound,
              body: '',
            );
          }
          final verifyUrl = verifyUrlFor(base, c.code);
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              if (c.isRevoked) ...[
                EpBanner(
                  key: const ValueKey('certificate-revoked'),
                  tone: EpBannerTone.destructive,
                  icon: Icons.block_rounded,
                  message: '${l10n.revokedBanner}\n${l10n.revokedContact}',
                  action: TextButton(
                    onPressed: () => context.push(AppRoutes.support),
                    child: Text(l10n.menuSupport),
                  ),
                ),
                const SizedBox(height: EpSpace.s4),
              ],
              RepaintBoundary(
                key: _cardKey,
                child: CertificateCard(certificate: c, verifyUrl: verifyUrl),
              ),
              if (!c.isRevoked) ...[
                const SizedBox(height: EpSpace.s5),
                FilledButton.icon(
                  key: const ValueKey('certificate-pdf'),
                  onPressed: _busy ? null : () => _sharePdf(c),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.downloadPdfAction),
                ),
                const SizedBox(height: EpSpace.s2),
                OutlinedButton.icon(
                  onPressed: () => _shareText(c, verifyUrl),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareAction),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
