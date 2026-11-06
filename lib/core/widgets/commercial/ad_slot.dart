import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/remote_config.dart';
import '../../localization/localization.dart';
import '../../theme/app_tokens.dart';

/// A configurable placement (design group SLOT).
///
/// * Empty → renders nothing: 0 px, no placeholder, no reserved gap.
/// * House → BIID's own promotion in brand tint ([houseBuilder]).
/// * Partner → the advertiser's creative, full-bleed, radius 10, no app
///   chrome; only when the partner is confirmed.
///
/// Spacing around a filled slot is applied here so an empty slot leaves no gap.
class AdSlot extends ConsumerWidget {
  const AdSlot({
    super.key,
    required this.id,
    this.houseBuilder,
    this.padding = const EdgeInsets.only(top: EpSpace.s4),
    this.onPartnerTap,
  });

  final AdSlotId id;
  final Widget Function(BuildContext context, HousePromotion promotion)?
  houseBuilder;
  final EdgeInsetsGeometry padding;
  final void Function(PartnerSlot slot)? onPartnerTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(
      remoteConfigProvider.select((config) => config.slot(id)),
    );

    final Widget? child = switch (content) {
      EmptySlot() => null,
      HouseSlot(:final promotion) =>
        promotion == null ? null : houseBuilder?.call(context, promotion),
      PartnerSlot() =>
        content.confirmedPartner && content.imageUrl.isNotEmpty
            ? _PartnerCreative(slot: content, onTap: onPartnerTap)
            : null,
    };

    if (child == null) {
      return const SizedBox.shrink();
    }
    return Padding(padding: padding, child: child);
  }
}

class _PartnerCreative extends StatefulWidget {
  const _PartnerCreative({required this.slot, this.onTap});

  final PartnerSlot slot;
  final void Function(PartnerSlot slot)? onTap;

  @override
  State<_PartnerCreative> createState() => _PartnerCreativeState();
}

class _PartnerCreativeState extends State<_PartnerCreative> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    // A creative that fails to load collapses like an unsold slot.
    if (_failed) {
      return const SizedBox.shrink();
    }
    final onTap = widget.onTap;
    return Semantics(
      label: context.l10n.partnerContentLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap(widget.slot),
        child: ClipRRect(
          borderRadius: EpRadius.mdAll,
          child: Image.network(
            widget.slot.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _failed = true);
                }
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
