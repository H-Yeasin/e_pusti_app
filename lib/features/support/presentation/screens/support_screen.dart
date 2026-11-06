import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';

enum SupportSubject { subscription, app, content, other }

/// INF-02. The scope statement comes before the message box.
///
/// Until a support API exists, "Send" opens the user's email app with the
/// message ready; the reference-number screen (INF-03) needs the API.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _details = TextEditingController();
  SupportSubject _subject = SupportSubject.subscription;

  @override
  void initState() {
    super.initState();
    _details.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _subjectLabel(SupportSubject subject) {
    final l10n = context.l10n;
    return switch (subject) {
      SupportSubject.subscription => l10n.supportSubjectSubscription,
      SupportSubject.app => l10n.supportSubjectApp,
      SupportSubject.content => l10n.supportSubjectContent,
      SupportSubject.other => l10n.supportSubjectOther,
    };
  }

  void _send(String email) {
    final version = ref.read(appInfoProvider).version;
    Launcher.email(
      context,
      to: email,
      subject: 'e-Pushti: ${_subjectLabel(_subject)}',
      body: '${_details.text.trim()}\n\n—\ne-Pushti $version',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final email = ref.watch(remoteConfigProvider.select((c) => c.supportEmail));

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuSupport),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          EpBanner(
            key: const ValueKey('support-scope'),
            icon: Icons.medical_information_outlined,
            message: l10n.supportScope,
          ),
          const SizedBox(height: EpSpace.s5),
          DropdownButtonFormField<SupportSubject>(
            initialValue: _subject,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.supportSubject,
              border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
            ),
            items: [
              for (final s in SupportSubject.values)
                DropdownMenuItem(value: s, child: Text(_subjectLabel(s))),
            ],
            onChanged: (s) => setState(() => _subject = s ?? _subject),
          ),
          const SizedBox(height: EpSpace.s4),
          TextField(
            key: const ValueKey('support-details'),
            controller: _details,
            minLines: 5,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: l10n.supportDetails,
              hintText: l10n.supportDetailsHint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
            ),
          ),
          const SizedBox(height: EpSpace.s4),
          FilledButton(
            onPressed: _details.text.trim().isEmpty ? null : () => _send(email),
            child: Text(l10n.supportSend),
          ),
          const SizedBox(height: EpSpace.s1),
          Text(l10n.supportSendNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: EpSpace.s6),
          Text(l10n.supportDirect, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          InkWell(
            onTap: () => Launcher.email(context, to: email),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: EpSpace.s2),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded),
                  const SizedBox(width: EpSpace.s2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: EpColors.fillPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(l10n.supportHours, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
