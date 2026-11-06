import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/notification_models.dart';
import '../engagement_providers.dart';

/// NOT-01 — unread first; tapping opens the destination.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inbox = ref.watch(inboxProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: EpAppBar(
        title: l10n.menuNotifications,
        actions: [
          if (unread > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: EpColors.n0),
              onPressed: () => ref.read(inboxProvider.notifier).markAllRead(),
              child: Text(l10n.inboxMarkAll),
            ),
          IconButton(
            tooltip: l10n.prefsTitle,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: EpAsyncView(
        value: inbox,
        onRetry: () => ref.invalidate(inboxProvider),
        data: (items) {
          if (items.isEmpty) {
            return EpStateView(
              key: const ValueKey('inbox-empty'),
              icon: Icons.notifications_none_rounded,
              title: l10n.inboxEmptyTitle,
              body: l10n.inboxEmptyBody,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                key: ValueKey('inbox-${item.id}'),
                tileColor: item.isRead ? null : EpColors.green50,
                leading: Icon(
                  _icon(item.category),
                  color: item.isRead ? EpColors.textMuted : EpColors.green700,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  [
                    item.body,
                    relativeTime(context, item.createdAt),
                  ].where((s) => s.isNotEmpty).join('\n'),
                ),
                isThreeLine: item.body.isNotEmpty,
                trailing: item.isRead
                    ? null
                    : Semantics(
                        label: l10n.inboxUnread,
                        child: const CircleAvatar(
                          radius: 5,
                          backgroundColor: EpColors.fillPrimary,
                        ),
                      ),
                onTap: () {
                  ref.read(inboxProvider.notifier).markRead(item.id);
                  final route = safeNotificationRoute(item.route);
                  if (route != null) context.push(route);
                },
              );
            },
          );
        },
      ),
    );
  }

  static IconData _icon(NotificationCategory c) => switch (c) {
    NotificationCategory.webinar => Icons.videocam_outlined,
    NotificationCategory.course => Icons.menu_book_outlined,
    NotificationCategory.content => Icons.description_outlined,
    NotificationCategory.general => Icons.campaign_outlined,
    NotificationCategory.health => Icons.monitor_weight_outlined,
  };
}

/// "3 hours ago", "Yesterday", or a date.
String relativeTime(BuildContext context, DateTime at, {DateTime? now}) {
  final l10n = context.l10n;
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) {
    return l10n.timeMinutesAgo(context.digits(diff.inMinutes));
  }
  if (diff.inHours < 24) return l10n.timeHoursAgo(context.digits(diff.inHours));
  if (diff.inHours < 48) return l10n.timeYesterday;
  return formatShortDate(context, at);
}
