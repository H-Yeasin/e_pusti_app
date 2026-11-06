import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../pust9/presentation/providers/pust9_providers.dart';
import '../../../../app/providers/app_locale_controller_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../library/presentation/library_providers.dart';
import '../app_settings_controller.dart';

/// INF-04. Notification preferences (Phase 4) and account deletion
/// (Phase 2) are added with their features.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeController = ref.watch(appLocaleControllerProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final downloads = ref.watch(downloadQueueProvider).value?.length ?? 0;
    final privacyUrl = ref.watch(
      remoteConfigProvider.select((c) => c.privacyUrl),
    );

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuSettings),
      body: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              key: const ValueKey('settings-language'),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(
                localeController.language == AppLanguage.bangla
                    ? l10n.banglaName
                    : l10n.englishName,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickLanguage(context, localeController),
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('settings-notifications'),
              title: Text(l10n.menuNotifications),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
            const Divider(height: 1),
            SwitchListTile(
              key: const ValueKey('settings-video-wifi'),
              title: Text(l10n.settingsVideoWifi),
              subtitle: Text(l10n.settingsVideoWifiSub),
              value: settings?.videoOnWifiOnly ?? true,
              onChanged: settings == null
                  ? null
                  : (v) => ref
                        .read(appSettingsProvider.notifier)
                        .setVideoOnWifiOnly(v),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(l10n.downloadsTitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (downloads > 0) Text(context.digits(downloads)),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => context.push(AppRoutes.downloads),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                if (privacyUrl == null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(l10n.comingSoonTitle)),
                    );
                  return;
                }
                Launcher.web(context, privacyUrl);
              },
            ),
            if (isLoggedIn) ...[
              if (ref.watch(pust9InAppAvailableProvider)) ...[
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('settings-pust9'),
                  title: Text(l10n.pust9Title),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.pust9),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('settings-privacy'),
                title: Text(l10n.settingsPrivacyCentre),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.privacyCentre),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('settings-change-number'),
                title: Text(l10n.settingsChangeNumber),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.changeNumber),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('settings-logout'),
                title: Text(l10n.settingsLogout),
                trailing: const Icon(Icons.logout_rounded),
                onTap: () => _confirmLogout(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('settings-delete-account'),
                title: Text(
                  l10n.settingsDeleteAccount,
                  style: const TextStyle(color: EpColors.destructiveText),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.deleteAccount),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// INF-06: logging out keeps downloaded files on the phone.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logOut();
    router.go(AppRoutes.home);
  }

  Future<void> _pickLanguage(
    BuildContext context,
    AppLocaleController controller,
  ) async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<AppLanguage>(
          groupValue: controller.language,
          onChanged: (v) => Navigator.of(context).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppLanguage>(
                value: AppLanguage.bangla,
                title: Text(l10n.banglaName),
                subtitle: Text(l10n.banglaLabel),
              ),
              RadioListTile<AppLanguage>(
                value: AppLanguage.english,
                title: Text(l10n.englishName),
                subtitle: Text(l10n.englishLabel),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != controller.language) {
      await controller.chooseLanguage(picked);
    }
  }
}
