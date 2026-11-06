import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/slot_events.dart';
import '../../config/remote_config.dart';
import '../../platform/launcher.dart';
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
            ? _PartnerCreative(slotId: id, slot: content, onTap: onPartnerTap)
            : null,
    };

    if (child == null) {
      return const SizedBox.shrink();
    }
    return Padding(padding: padding, child: child);
  }
}

class _PartnerCreative extends ConsumerStatefulWidget {
  const _PartnerCreative({
    required this.slotId,
    required this.slot,
    this.onTap,
  });

  final AdSlotId slotId;
  final PartnerSlot slot;
  final void Function(PartnerSlot slot)? onTap;

  @override
  ConsumerState<_PartnerCreative> createState() => _PartnerCreativeState();
}

class _PartnerCreativeState extends ConsumerState<_PartnerCreative> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (markImpressionOnce(widget.slotId.key, widget.slot.imageUrl)) {
      ref
          .read(slotEventSinkProvider)
          .record(
            widget.slotId.key,
            SlotEventKind.impression,
            creative: widget.slot.imageUrl,
          );
    }
  }

  void _tap() {
    ref
        .read(slotEventSinkProvider)
        .record(
          widget.slotId.key,
          SlotEventKind.click,
          creative: widget.slot.imageUrl,
        );
    final custom = widget.onTap;
    if (custom != null) {
      custom(widget.slot);
      return;
    }
    final url = widget.slot.clickUrl;
    if (url != null && url.startsWith('https://')) Launcher.web(context, url);
  }

  @override
  Widget build(BuildContext context) {
    // A creative that fails to load collapses like an unsold slot.
    if (_failed) {
      return const SizedBox.shrink();
    }
    final tappable = widget.onTap != null || widget.slot.clickUrl != null;
    return Semantics(
      label: context.l10n.partnerContentLabel,
      button: tappable,
      child: GestureDetector(
        onTap: tappable ? _tap : null,
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
