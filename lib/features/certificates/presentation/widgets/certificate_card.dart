import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/certificate_models.dart';

/// The certificate itself. Rendered on screen and captured as the PDF page,
/// so Bangla text is shaped by Flutter rather than the PDF library.
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.certificate,
    required this.verifyUrl,
  });

  final Certificate certificate;

  /// Null until the verification domain exists (O-15).
  final String? verifyUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final revoked = certificate.isRevoked;
    final ink = revoked ? EpColors.n500 : EpColors.green800;
    final date =
        '${formatShortDate(context, certificate.issuedAt)} '
        '${context.digits(certificate.issuedAt.year)}';

    return Container(
      padding: const EdgeInsets.all(EpSpace.s5),
      decoration: BoxDecoration(
        color: EpColors.surface,
        borderRadius: EpRadius.lgAll,
        border: Border.all(
          color: revoked ? EpColors.n300 : EpColors.green300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded, size: 40, color: ink),
          const SizedBox(height: EpSpace.s3),
          Text(
            l10n.certifyLine,
            textAlign: TextAlign.center,
            style: const TextStyle(color: EpColors.textSecondary),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            certificate.holderName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: revoked ? EpColors.n600 : EpColors.textPrimary,
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            l10n.completedLine,
            textAlign: TextAlign.center,
            style: const TextStyle(color: EpColors.textSecondary),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            certificate.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: EpTextSize.heading,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          if (certificate.sourceLabel.isNotEmpty) ...[
            const SizedBox(height: EpSpace.s1),
            Text(
              l10n.approvedModule(certificate.sourceLabel),
              style: const TextStyle(color: EpColors.textSecondary),
            ),
          ],
          const SizedBox(height: EpSpace.s5),
          if (verifyUrl != null && !revoked)
            Semantics(
              label: l10n.verifyAt(verifyUrl!),
              child: QrImageView(
                key: const ValueKey('certificate-qr'),
                data: verifyUrl!,
                size: 120,
                backgroundColor: EpColors.surface,
              ),
            ),
          const SizedBox(height: EpSpace.s2),
          SelectableText(
            certificate.code,
            style: const TextStyle(
              fontSize: EpTextSize.bodyLarge,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          if (verifyUrl == null)
            Text(
              l10n.verifyLinkSoon,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (!revoked)
            Text(
              l10n.verifyAt(verifyUrl!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: EpSpace.s4),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BIID Foundation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                revoked ? l10n.revokedStamp : date,
                style: TextStyle(
                  fontWeight: revoked ? FontWeight.w700 : FontWeight.w400,
                  color: revoked
                      ? EpColors.destructiveText
                      : EpColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? verifyUrlFor(String? base, String code) {
  if (base == null || base.isEmpty) return null;
  final trimmed = base.endsWith('/')
      ? base.substring(0, base.length - 1)
      : base;
  return '$trimmed/$code';
}
