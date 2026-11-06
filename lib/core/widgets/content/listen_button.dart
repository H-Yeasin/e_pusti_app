import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/localization.dart';
import '../../platform/narrator.dart';
import '../../theme/app_tokens.dart';
import '../feedback/ep_banner.dart';

enum _ListenState { idle, preparing, speaking, unavailable }

/// "শুনুন": reads the text aloud for users who find reading hard.
class ListenButton extends ConsumerStatefulWidget {
  const ListenButton({super.key, required this.parts});

  final List<String> parts;

  @override
  ConsumerState<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends ConsumerState<ListenButton> {
  _ListenState _state = _ListenState.idle;
  late final Narrator _narrator = ref.read(narratorProvider);

  @override
  void dispose() {
    if (_state == _ListenState.speaking) _narrator.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == _ListenState.speaking) {
      await _narrator.stop();
      if (mounted) setState(() => _state = _ListenState.idle);
      return;
    }
    setState(() => _state = _ListenState.preparing);
    final ok = await _narrator.prepareBangla();
    if (!mounted) return;
    if (!ok) {
      setState(() => _state = _ListenState.unavailable);
      return;
    }
    setState(() => _state = _ListenState.speaking);
    await _narrator.speak(widget.parts);
    if (mounted && _state == _ListenState.speaking) {
      setState(() => _state = _ListenState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_state == _ListenState.unavailable) {
      return EpBanner(
        key: const ValueKey('listen-unavailable'),
        icon: Icons.record_voice_over_outlined,
        message: l10n.listenUnavailable,
      );
    }
    final speaking = _state == _ListenState.speaking;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        key: const ValueKey('listen-button'),
        style: OutlinedButton.styleFrom(
          foregroundColor: EpColors.green800,
          side: const BorderSide(color: EpColors.green300),
        ),
        onPressed: _state == _ListenState.preparing ? null : _toggle,
        icon: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
        label: Text(speaking ? l10n.listenStop : l10n.listenAction),
      ),
    );
  }
}
