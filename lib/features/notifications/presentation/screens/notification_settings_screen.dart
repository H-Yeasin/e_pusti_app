import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/notification_models.dart';
import '../engagement_providers.dart';

/// NOT-02. The permission trap: every category may be on in the app while
/// the phone blocks delivery — say so, and offer the phone's settings.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check after the user comes back from the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
    }
  }

  Future<void> _toggle(NotificationCategory c, bool on) async {
    await ref.read(notificationPrefsProvider.notifier).set(c, on);
    if (on) {
      // First time a category is turned on, ask the OS (no-op if decided).
      await ref.read(reminderSchedulerProvider).requestPermission();
      ref.invalidate(notificationPermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = ref.watch(notificationPrefsProvider);
    final permitted = ref.watch(notificationPermissionProvider).value ?? true;

    final rows = [
      (NotificationCategory.webinar, l10n.catWebinar, l10n.catWebinarSub),
      (NotificationCategory.course, l10n.catCourse, l10n.catCourseSub),
      (NotificationCategory.content, l10n.catContent, l10n.catContentSub),
      (NotificationCategory.general, l10n.catGeneral, l10n.catGeneralSub),
      (NotificationCategory.health, l10n.catHealth, l10n.catHealthSub),
    ];

    return Scaffold(
      appBar: EpAppBar(title: l10n.prefsTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: EpSpace.s3),
        children: [
          if (!permitted)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EpSpace.gutter,
                0,
                EpSpace.gutter,
                EpSpace.s4,
              ),
              child: EpBanner(
                key: const ValueKey('permission-denied'),
                tone: EpBannerTone.destructive,
                icon: Icons.notifications_off_outlined,
                message:
                    '${l10n.permissionDeniedTitle}\n${l10n.permissionDeniedBody}',
                action: FilledButton(
                  onPressed: () =>
                      ref.read(reminderSchedulerProvider).openSystemSettings(),
                  child: Text(l10n.openPhoneSettings),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EpSpace.gutter),
            child: Text(
              l10n.prefsHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final (category, title, subtitle) in rows)
            SwitchListTile(
              key: ValueKey('pref-${category.name}'),
              title: Text(title),
              subtitle: Text(subtitle),
              value: prefs[category] ?? true,
              onChanged: (v) => _toggle(category, v),
            ),
        ],
      ),
    );
  }
}
