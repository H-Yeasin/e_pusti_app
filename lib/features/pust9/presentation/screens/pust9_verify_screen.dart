import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/phone_number.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/pust9_subscription.dart';
import '../providers/pust9_providers.dart';
import '../pust9_messages.dart';

/// Confirms a PUST9 subscription with the bdapps OTP. The charge is shown
/// next to the confirm button, as the operator requires.
class Pust9VerifyScreen extends ConsumerStatefulWidget {
  const Pust9VerifyScreen({super.key});

  static const codeLength = 6;
  static const resendAfter = Duration(seconds: 60);

  @override
  ConsumerState<Pust9VerifyScreen> createState() => _Pust9VerifyScreenState();
}

class _Pust9VerifyScreenState extends ConsumerState<Pust9VerifyScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _secondsLeft = Pust9VerifyScreen.resendAfter.inSeconds;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _code.addListener(() {
      setState(() {
        if (_code.text.isNotEmpty) _error = null;
      });
      if (_code.text.length == Pust9VerifyScreen.codeLength) _verify();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = Pust9VerifyScreen.resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  String? get _phone =>
      ref.read(pust9SubscriptionProvider).value?.phone ??
      ref.read(authControllerProvider).phoneNumber;

  Future<void> _verify() async {
    if (_busy || _code.text.length != Pust9VerifyScreen.codeLength) return;
    setState(() => _busy = true);
    try {
      await ref.read(pust9SubscriptionProvider.notifier).verifyOtp(_code.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = context.l10n.pust9SubscribedToast;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.pust9);
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on Pust9Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final phone = _phone;
    if (phone == null) return;
    setState(() {
      _error = null;
      _code.clear();
    });
    try {
      await ref.read(pust9SubscriptionProvider.notifier).requestOtp(phone);
      _startCountdown();
    } on Pust9Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final price = ref.watch(
      remoteConfigProvider.select((c) => c.pust9.pricePerDayTaka),
    );
    final phone = _phone;
    final error = _error;
    final countdown =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: EpAppBar(title: l10n.pust9OtpTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.s6),
        children: [
          Text(
            l10n.pust9OtpBody(
              context.digits(phone == null ? '' : PhoneNumber.display(phone)),
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: EpSpace.s5),
          TextField(
            key: const ValueKey('pust9-otp-field'),
            controller: _code,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: Pust9VerifyScreen.codeLength,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: EpTextSize.heading,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            inputFormatters: [
              _BanglaDigitsFormatter(),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: l10n.pust9OtpFieldLabel,
              counterText: '',
              errorText: error is Pust9InvalidCodeFailure ? '' : null,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: EpSpace.s3),
            EpBanner(
              key: const ValueKey('pust9-otp-error'),
              tone: EpBannerTone.destructive,
              message: pust9FailureMessage(context, error),
            ),
          ],
          const SizedBox(height: EpSpace.s4),
          if (_secondsLeft > 0)
            Text(
              l10n.otpResendIn(context.digits(countdown)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            )
          else
            TextButton(onPressed: _resend, child: Text(l10n.otpResend)),
          const SizedBox(height: EpSpace.s5),
          Text(
            l10n.pust9OtpCharge(context.digits(price)),
            key: const ValueKey('pust9-otp-charge'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: EpSpace.s3),
          FilledButton(
            key: const ValueKey('pust9-otp-confirm'),
            onPressed:
                _code.text.length == Pust9VerifyScreen.codeLength && !_busy
                ? _verify
                : null,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.pust9OtpConfirm),
          ),
        ],
      ),
    );
  }
}

/// Lets people type the code with a Bangla keyboard.
class _BanglaDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAllMapped(
      RegExp('[০-৯]'),
      (m) => String.fromCharCode(0x30 + m[0]!.codeUnitAt(0) - 0x09E6),
    );
    return newValue.copyWith(text: text);
  }
}
