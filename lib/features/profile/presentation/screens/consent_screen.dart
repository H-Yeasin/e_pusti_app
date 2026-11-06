import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/login_completion.dart';
import '../profile_providers.dart';

/// PRO-03. Both boxes are required; "Not now" keeps courses, library and
/// webinars open.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _terms = false;
  bool _health = false;
  bool _saving = false;

  void _leave() {
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
    final target = AppRoutes.safeReturnTarget(widget.returnTo);
    if (widget.returnTo != null) goToTarget(router, target);
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await ref.read(consentProvider.notifier).accept(healthData: true);
      if (mounted) _leave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EpAppBar(title: l10n.consentTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.s6),
        children: [
          Text(l10n.consentHeading, style: theme.textTheme.titleLarge),
          const SizedBox(height: EpSpace.s3),
          Text(l10n.consentBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: EpSpace.s5),
          CheckboxListTile(
            key: const ValueKey('consent-terms'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: Text(l10n.consentTerms),
          ),
          CheckboxListTile(
            key: const ValueKey('consent-health'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _health,
            onChanged: (v) => setState(() => _health = v ?? false),
            title: Text(l10n.consentHealth),
          ),
          const SizedBox(height: EpSpace.s6),
          FilledButton(
            onPressed: _terms && _health && !_saving ? _accept : null,
            child: Text(l10n.consentContinue),
          ),
          const SizedBox(height: EpSpace.s2),
          TextButton(onPressed: _leave, child: Text(l10n.notNowAction)),
          const SizedBox(height: EpSpace.s2),
          Text(
            l10n.consentSkipNote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
