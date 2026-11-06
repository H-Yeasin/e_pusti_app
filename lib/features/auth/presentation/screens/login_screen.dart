import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/backend_config.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/auth_repository.dart';
import '../auth_messages.dart';
import '../phone_number.dart';
import '../providers/auth_controller.dart';

/// LAU-03 (and LAU-06 when [changeNumber] is true): phone number entry.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.returnTo, this.changeNumber = false});

  final String? returnTo;
  final bool changeNumber;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _submitted = false;
  bool _sending = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    final phone = PhoneNumber.normalize(_phone.text);
    if (phone == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (widget.changeNumber) {
        await auth.requestPhoneChange(phone);
      } else {
        await auth.requestCode(phone);
      }
      if (!mounted) return;
      context.push(
        AppRoutes.verifyCode(
          phone: phone,
          returnTo: widget.returnTo,
          changeNumber: widget.changeNumber,
        ),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final unavailable = ref.watch(backendKindProvider) == BackendKind.none;
    final invalid = _submitted && PhoneNumber.normalize(_phone.text) == null;
    final error = _error;

    return Scaffold(
      appBar: EpAppBar(
        title: widget.changeNumber ? l10n.changeNumberTitle : l10n.loginTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.s6),
        children: [
          Text(
            widget.changeNumber ? l10n.changeNumberHeading : l10n.phoneHeading,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: EpSpace.s2),
          Text(
            widget.changeNumber ? l10n.changeNumberBody : l10n.phoneReason,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: EpSpace.s6),
          if (unavailable)
            EpBanner(
              icon: Icons.info_outline_rounded,
              message: l10n.authUnavailable,
            )
          else ...[
            TextField(
              key: const ValueKey('login-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯ \-]')),
                LengthLimitingTextInputFormatter(14),
              ],
              style: const TextStyle(
                fontSize: EpTextSize.bodyLarge,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                prefixText: '+880 ',
                hintText: l10n.phoneHint,
                errorText: invalid ? l10n.phoneInvalid : null,
                filled: true,
                fillColor: EpColors.surface,
                border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
              ),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: EpSpace.s3),
            if (!widget.changeNumber)
              Text(l10n.phoneOperatorNote, style: theme.textTheme.bodySmall),
            if (error != null) ...[
              const SizedBox(height: EpSpace.s3),
              EpBanner(
                key: const ValueKey('login-error'),
                tone: EpBannerTone.destructive,
                message: authFailureMessage(context, error),
              ),
            ],
            const SizedBox(height: EpSpace.s8),
            if (!widget.changeNumber)
              Text(
                l10n.phoneTermsNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: EpSpace.s2),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.sendCodeAction),
            ),
          ],
        ],
      ),
    );
  }
}
