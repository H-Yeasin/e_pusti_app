import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/localization.dart';
import '../../core/widgets/feedback/ep_state_view.dart';
import '../../core/widgets/navigation/ep_app_bar.dart';
import 'app_routes.dart';

/// Stand-in for screens that are not built yet, so navigation from the
/// dashboard and sidebar is real and testable.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: EpAppBar(title: title),
      body: EpStateView(
        icon: Icons.construction_rounded,
        title: l10n.comingSoonTitle,
        body: l10n.comingSoonBody,
        primaryLabel: l10n.backToHomeAction,
        onPrimary: () => context.go(AppRoutes.home),
      ),
    );
  }
}
