import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_environment_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/config/app_info.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/phone_number.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../notifications/presentation/engagement_providers.dart';
import '../../../share/share_actions.dart';

/// HOM-02. Gated destinations stay visible and are marked with a lock when
/// logged out — never hidden.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, required this.onNavigate});

  /// Called with a route after the drawer closes; the caller decides whether
  /// to navigate or ask for login.
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(authControllerProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final version = ref.watch(appInfoProvider).version;
    final unread = session.isLoggedIn ? ref.watch(unreadCountProvider) : 0;

    void go(String route) {
      Navigator.of(context).pop();
      onNavigate(route);
    }

    final items = [
      (Icons.home_outlined, l10n.menuHome, AppRoutes.home),
      (
        Icons.family_restroom_outlined,
        l10n.menuFamilyProfile,
        AppRoutes.profile,
      ),
      (
        Icons.workspace_premium_outlined,
        l10n.menuCertificates,
        AppRoutes.certificates,
      ),
      (
        Icons.event_note_outlined,
        l10n.menuRegistrations,
        AppRoutes.registrations,
      ),
      (
        Icons.notifications_none_rounded,
        l10n.menuNotifications,
        AppRoutes.notifications,
      ),
      (Icons.info_outline_rounded, l10n.menuAbout, AppRoutes.about),
      (Icons.support_agent_outlined, l10n.menuSupport, AppRoutes.support),
      (Icons.settings_outlined, l10n.menuSettings, AppRoutes.settings),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              phoneNumber: session.phoneNumber,
              onLogin: () => go(AppRoutes.login),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: EpSpace.s2),
                children: [
                  for (final (icon, label, route) in items)
                    _SidebarItem(
                      icon: icon,
                      label: label,
                      locked: AppRoutes.isGated(route) && !session.isLoggedIn,
                      badge: route == AppRoutes.notifications ? unread : 0,
                      onTap: () => go(route),
                    ),
                  _SidebarItem(
                    icon: Icons.share_outlined,
                    label: l10n.shareAppAction,
                    locked: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      shareApp(context, ref);
                    },
                  ),
                  if (environment == AppEnvironment.dev)
                    _SidebarItem(
                      icon: Icons.palette_outlined,
                      label: l10n.devCatalogTitle,
                      locked: false,
                      onTap: () => go(AppRoutes.devCatalog),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(EpSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.menuVersion(context.digits(version)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (environment != AppEnvironment.prod)
                    Text(
                      l10n.runningEnvironment(environment.label),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.phoneNumber, required this.onLogin});

  final String? phoneNumber;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = phoneNumber;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EpSpace.s4,
        EpSpace.s5,
        EpSpace.s4,
        EpSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo/e-pusti_logo.png',
            height: 48,
            semanticLabel: l10n.homeAppTitle,
            errorBuilder: (context, error, stackTrace) =>
                Text(l10n.homeAppTitle),
          ),
          const SizedBox(height: EpSpace.s3),
          if (phone != null)
            Text(
              context.digits(PhoneNumber.display(phone)),
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 40),
                ),
                onPressed: onLogin,
                child: Text(l10n.menuLogin),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.locked,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool locked;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: EpColors.textSecondary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: EpTextSize.body,
          color: EpColors.textPrimary,
        ),
      ),
      trailing: locked
          ? Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: EpColors.textMuted,
              semanticLabel: context.l10n.menuLockedHint,
            )
          : badge > 0
          ? Badge(
              key: const ValueKey('sidebar-unread'),
              label: Text(context.digits(badge)),
              backgroundColor: EpColors.fillPrimary,
            )
          : null,
      onTap: onTap,
    );
  }
}
