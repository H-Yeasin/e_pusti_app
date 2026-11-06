import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/remote_config.dart';
import '../../core/localization/localization.dart';

/// Link that opens [route] — on the web once `shareBaseUrl` is configured,
/// otherwise the app's own `epushti://` scheme.
String shareLinkFor(AppRemoteConfig config, String route) {
  final base = config.shareBaseUrl;
  if (base != null && base.isNotEmpty) {
    final trimmed = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$trimmed$route';
  }
  return 'epushti:/$route';
}

/// P1-7: share a chapter, document or webinar (WhatsApp, Messenger, …).
Future<void> shareInAppLink(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String route,
}) {
  final text = context.l10n.shareContentText(title);
  final link = shareLinkFor(ref.read(remoteConfigProvider), route);
  return SharePlus.instance.share(ShareParams(text: '$text\n$link'));
}

Future<void> shareApp(BuildContext context, WidgetRef ref) {
  final text = context.l10n.shareAppText;
  final store = ref.read(remoteConfigProvider).storeUrl;
  return SharePlus.instance.share(
    ShareParams(text: store == null ? text : '$text\n$store'),
  );
}
