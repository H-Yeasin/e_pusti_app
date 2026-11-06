import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/platform/launcher.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/commercial/ad_slot.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/phone_number.dart';
import '../../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../../domain/entities/mobile_operator.dart';
import '../../domain/pust9_subscription.dart';
import '../providers/pust9_providers.dart';
import '../pust9_messages.dart';

/// SMS-01. One scrollable screen: the dial path and the SMS path are peers,
/// and copying has equal weight to dialling. Never a dead end.
class Pust9Screen extends ConsumerWidget {
  const Pust9Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pust9 = ref.watch(remoteConfigProvider.select((c) => c.pust9));
    final phone = ref.watch(authControllerProvider).phoneNumber;
    final notEligible =
        phone != null && !MobileOperator.fromPhoneNumber(phone).supportsPust9;
    final inApp = ref.watch(pust9InAppAvailableProvider);
    final subscription = ref.watch(pust9SubscriptionProvider);
    final status = subscription.value;
    final subscribed = status?.isSubscribed ?? false;
    // The status note says the app can't see the subscription; drop it once
    // bdapps has told us.
    final knowsStatus = inApp && status != null && !subscription.hasError;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EpAppBar(title: l10n.pust9Title),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          Text(
            l10n.pust9Headline(context.digits(pust9.courseDays)),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: EpSpace.s1),
          Text(l10n.pust9Tagline, style: theme.textTheme.bodyMedium),
          const SizedBox(height: EpSpace.s4),
          if (notEligible) ...[
            EpBanner(
              key: const ValueKey('pust9-not-eligible'),
              tone: EpBannerTone.info,
              icon: Icons.info_outline_rounded,
              message: l10n.pust9NotEligible,
            ),
          ] else
            EpBanner(
              icon: Icons.sim_card_outlined,
              message: l10n.pust9OperatorNote,
            ),
          const SizedBox(height: EpSpace.s3),
          _ChargeRow(price: context.digits(pust9.pricePerDayTaka)),
          const SizedBox(height: EpSpace.s5),
          if (subscribed)
            _SubscribedCard(status: status!)
          else ...[
            if (inApp && !notEligible) ...[
              _InAppCard(
                phone: phone,
                unsubscribed: status?.phase == Pust9Phase.unsubscribed,
              ),
              const SizedBox(height: EpSpace.s5),
              Text(l10n.pust9OrManual, style: theme.textTheme.titleMedium),
              const SizedBox(height: EpSpace.s3),
            ],
            _PathCard(
              badge: 'A',
              title: l10n.pust9PathATitle,
              fields: [_CodeField(value: pust9.ussdCode)],
              primaryLabel: l10n.pust9DialAction,
              primaryIcon: Icons.call_outlined,
              onPrimary: () => Launcher.dial(context, pust9.ussdCode),
              onCopy: () => Launcher.copy(context, pust9.ussdCode),
              steps: [
                l10n.pust9PathAStep1,
                l10n.pust9PathAStep2,
                l10n.pust9PathAStep3,
              ],
            ),
            const SizedBox(height: EpSpace.s4),
            _PathCard(
              badge: 'B',
              title: l10n.pust9PathBTitle,
              fields: [
                _CodeField(
                  label: l10n.pust9ShortcodeLabel,
                  value: 'To: ${pust9.shortcode}',
                ),
                _CodeField(label: l10n.pust9MessageLabel, value: pust9.keyword),
              ],
              primaryLabel: l10n.pust9OpenSmsAction,
              primaryIcon: Icons.sms_outlined,
              onPrimary: () => Launcher.sms(
                context,
                to: pust9.shortcode,
                body: pust9.keyword,
              ),
              onCopy: () => Launcher.copy(context, pust9.keyword),
              steps: [l10n.pust9PathBStep1, l10n.pust9PathBStep2],
            ),
            if (notEligible) ...[
              const SizedBox(height: EpSpace.s5),
              Text(l10n.pust9StillOpen, style: theme.textTheme.titleMedium),
              const SizedBox(height: EpSpace.s2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.courses),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l10n.homeCourse),
                    ),
                  ),
                  const SizedBox(width: EpSpace.s3),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.digiSkills),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(l10n.homeDigiSkill),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: EpSpace.s5),
          if (!knowsStatus)
            EpBanner(
              key: const ValueKey('pust9-status-note'),
              icon: Icons.help_outline_rounded,
              message: l10n.pust9StatusNote,
            ),
          if (!subscribed &&
              pust9.stopKeyword != null &&
              pust9.stopShortcode != null) ...[
            const SizedBox(height: EpSpace.s4),
            Text(l10n.pust9StopTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: EpSpace.s1),
            Text(
              l10n.pust9StopBody(pust9.stopKeyword!, pust9.stopShortcode!),
              key: const ValueKey('pust9-stop'),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Launcher.sms(
                  context,
                  to: pust9.stopShortcode!,
                  body: pust9.stopKeyword!,
                ),
                icon: const Icon(Icons.sms_outlined),
                label: Text(l10n.pust9OpenSmsAction),
              ),
            ),
          ],
          const SizedBox(height: EpSpace.s3),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.pust9Archive),
            icon: const Icon(Icons.history_rounded),
            label: Text(l10n.pust9ArchiveLink),
          ),
          const AdSlot(id: AdSlotId.pust9Banner),
          const SizedBox(height: EpSpace.s4),
          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.support),
              child: Text(l10n.pust9SupportLink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pust9ChargeLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: EpColors.textPrimary,
          ),
        ),
        const SizedBox(width: EpSpace.s3),
        Expanded(
          child: Text(
            l10n.pust9Charge(price),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _CodeField {
  const _CodeField({required this.value, this.label});

  final String? label;
  final String value;
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.badge,
    required this.title,
    required this.fields,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onCopy,
    required this.steps,
  });

  final String badge;
  final String title;
  final List<_CodeField> fields;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback onCopy;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(EpSpace.cardPadding),
      decoration: BoxDecoration(
        color: EpColors.surface,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: EpColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: EpColors.green100,
                foregroundColor: EpColors.green800,
                child: Text(
                  badge,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: EpSpace.s2),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: EpSpace.s3),
          for (final field in fields) ...[
            if (field.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: EpSpace.s1),
                child: Text(field.label!, style: theme.textTheme.bodySmall),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EpSpace.s3,
                vertical: EpSpace.s3,
              ),
              margin: const EdgeInsets.only(bottom: EpSpace.s2),
              decoration: const BoxDecoration(
                color: EpColors.n50,
                borderRadius: EpRadius.smAll,
              ),
              child: SelectableText(
                field.value,
                style: const TextStyle(
                  fontSize: EpTextSize.bodyLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: EpColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: EpSpace.s1),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: EpSpace.s3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.copyAction),
                ),
              ),
            ],
          ),
          const SizedBox(height: EpSpace.s4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: EpSpace.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      context.digits(i + 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EpColors.green700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(steps[i], style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The bdapps OTP path: one tap sends the code, the next screen confirms.
class _InAppCard extends ConsumerStatefulWidget {
  const _InAppCard({required this.phone, required this.unsubscribed});

  final String? phone;
  final bool unsubscribed;

  @override
  ConsumerState<_InAppCard> createState() => _InAppCardState();
}

class _InAppCardState extends ConsumerState<_InAppCard> {
  bool _busy = false;
  Object? _error;

  Future<void> _subscribe() async {
    final phone = widget.phone;
    final l10n = context.l10n;
    if (phone == null) {
      await showLoginPrompt(
        context,
        returnTo: AppRoutes.pust9,
        title: l10n.pust9LoginTitle,
        body: l10n.pust9LoginBody,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(pust9SubscriptionProvider.notifier).requestOtp(phone);
      if (mounted) await context.push(AppRoutes.pust9Verify);
    } on Pust9Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final phone = widget.phone;
    final error = _error;
    return Container(
      key: const ValueKey('pust9-in-app'),
      padding: const EdgeInsets.all(EpSpace.cardPadding),
      decoration: BoxDecoration(
        color: EpColors.green50,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: EpColors.green100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.pust9InAppTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          if (widget.unsubscribed) ...[
            Text(
              l10n.pust9Unsubscribed,
              key: const ValueKey('pust9-unsubscribed'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: EpSpace.s2),
          ],
          Text(
            phone == null
                ? l10n.pust9InAppBodyLoggedOut
                : l10n.pust9InAppBody(
                    context.digits(PhoneNumber.display(phone)),
                  ),
            style: theme.textTheme.bodyMedium,
          ),
          if (error != null) ...[
            const SizedBox(height: EpSpace.s3),
            EpBanner(
              key: const ValueKey('pust9-in-app-error'),
              tone: EpBannerTone.destructive,
              message: pust9FailureMessage(context, error),
            ),
          ],
          const SizedBox(height: EpSpace.s3),
          FilledButton.icon(
            key: const ValueKey('pust9-in-app-subscribe'),
            onPressed: _busy ? null : _subscribe,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(l10n.pust9InAppAction),
          ),
        ],
      ),
    );
  }
}

/// Live status from bdapps, with a confirmed stop.
class _SubscribedCard extends ConsumerStatefulWidget {
  const _SubscribedCard({required this.status});

  final Pust9Status status;

  @override
  ConsumerState<_SubscribedCard> createState() => _SubscribedCardState();
}

class _SubscribedCardState extends ConsumerState<_SubscribedCard> {
  bool _busy = false;
  Object? _error;

  Future<void> _stop() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pust9StopConfirmTitle),
        content: Text(l10n.pust9StopConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            key: const ValueKey('pust9-stop-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: EpColors.destructiveText,
            ),
            child: Text(l10n.pust9StopConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(pust9SubscriptionProvider.notifier).unsubscribe();
      messenger.showSnackBar(SnackBar(content: Text(l10n.pust9StoppedToast)));
    } on Pust9Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = widget.status;
    final error = _error;
    return Container(
      key: const ValueKey('pust9-subscribed'),
      padding: const EdgeInsets.all(EpSpace.cardPadding),
      decoration: BoxDecoration(
        color: EpColors.green50,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: EpColors.green100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: EpColors.green700),
              const SizedBox(width: EpSpace.s2),
              Expanded(
                child: Text(
                  l10n.pust9SubscribedTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (status.courseDays > 0) ...[
            const SizedBox(height: EpSpace.s3),
            Text(
              l10n.pust9SubscribedDay(
                context.digits(status.day),
                context.digits(status.courseDays),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: EpSpace.s2),
            ClipRRect(
              borderRadius: EpRadius.smAll,
              child: LinearProgressIndicator(
                value: status.day / status.courseDays,
                minHeight: 6,
              ),
            ),
          ],
          if (status.phone != null) ...[
            const SizedBox(height: EpSpace.s3),
            Text(
              l10n.pust9SubscribedPhone(
                context.digits(PhoneNumber.display(status.phone!)),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: EpSpace.s3),
            EpBanner(
              tone: EpBannerTone.destructive,
              message: pust9FailureMessage(context, error),
            ),
          ],
          const SizedBox(height: EpSpace.s3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('pust9-in-app-stop'),
              onPressed: _busy ? null : _stop,
              style: TextButton.styleFrom(
                foregroundColor: EpColors.destructiveText,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l10n.pust9StopAction),
            ),
          ),
        ],
      ),
    );
  }
}
