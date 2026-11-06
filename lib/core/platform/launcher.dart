import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/localization.dart';

/// Thin wrappers around the phone's own apps. Every action reports failure
/// to the user instead of silently doing nothing.
abstract final class Launcher {
  /// Opens the dialler with [code] filled in (USSD codes need `#` escaped).
  static Future<void> dial(BuildContext context, String code) {
    return _launch(context, Uri(scheme: 'tel', path: code));
  }

  static Future<void> sms(
    BuildContext context, {
    required String to,
    required String body,
  }) {
    return _launch(
      context,
      Uri(scheme: 'sms', path: to, queryParameters: {'body': body}),
    );
  }

  static Future<void> email(
    BuildContext context, {
    required String to,
    String? subject,
    String? body,
  }) {
    return _launch(
      context,
      Uri(
        scheme: 'mailto',
        path: to,
        query: _encodeQuery({'subject': ?subject, 'body': ?body}),
      ),
    );
  }

  static Future<void> web(BuildContext context, String url) {
    return _launch(
      context,
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      _toast(context, context.l10n.copiedToast);
    }
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: mode);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      _toast(context, context.l10n.cannotOpenAppToast);
    }
  }

  // mailto bodies must use %20, not '+', for spaces.
  static String? _encodeQuery(Map<String, String> params) {
    if (params.isEmpty) {
      return null;
    }
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
