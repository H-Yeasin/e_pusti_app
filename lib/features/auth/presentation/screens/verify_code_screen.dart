import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/backend_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/auth_repository.dart';
import '../auth_messages.dart';
import '../login_completion.dart';
import '../phone_number.dart';
import '../providers/auth_controller.dart';

/// LAU-04: six-digit code with a resend countdown, wrong-code, expired,
/// too-many-attempts and slow-SMS states.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.phone,
    this.returnTo,
    this.changeNumber = false,
  });

  final String phone;
  final String? returnTo;
  final bool changeNumber;

  static const codeLength = 6;
  static const resendAfter = Duration(seconds: 60);

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  late int _secondsLeft;
  bool _verifying = false;
  bool _lockedOut = false;
  bool _waitedLong = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _code.addListener(() {
      // Typing a new code clears the last error; clearing the field after a
      // failed attempt must not hide it.
      setState(() {
        if (_code.text.isNotEmpty) _error = null;
      });
      if (_code.text.length == VerifyCodeScreen.codeLength) _verify();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = VerifyCodeScreen.resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _waitedLong = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text;
    if (code.length != VerifyCodeScreen.codeLength ||
        _verifying ||
        _lockedOut) {
      return;
    }
    setState(() => _verifying = true);
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (widget.changeNumber) {
        await auth.verifyPhoneChange(widget.phone, code);
      } else {
        await auth.verifyCode(widget.phone, code);
      }
      if (!mounted) return;
      await completeLogin(
        context,
        ref,
        returnTo: widget.returnTo,
        changedNumber: widget.changeNumber,
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _lockedOut = e is TooManyAttemptsFailure;
        _code.clear();
      });
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _lockedOut = false;
      _waitedLong = false;
      _code.clear();
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (widget.changeNumber) {
        await auth.requestPhoneChange(widget.phone);
      } else {
        await auth.requestCode(widget.phone);
      }
      _startCountdown();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final error = _error;
    final isDevBackend = ref.watch(backendKindProvider) == BackendKind.local;
    final countdown =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: EpAppBar(title: l10n.otpTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.s6),
        children: [
          Text(l10n.otpSentTo, style: theme.textTheme.bodyMedium),
          const SizedBox(height: EpSpace.s1),
          Row(
            children: [
              Flexible(
                child: Text(
                  context.digits(PhoneNumber.display(widget.phone)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.changeAction),
              ),
            ],
          ),
          const SizedBox(height: EpSpace.s5),
          _CodeBoxes(
            controller: _code,
            focusNode: _focus,
            enabled: !_lockedOut && !_verifying,
            hasError: error is InvalidCodeFailure,
          ),
          if (error != null) ...[
            const SizedBox(height: EpSpace.s3),
            EpBanner(
              key: const ValueKey('otp-error'),
              tone: EpBannerTone.destructive,
              message: authFailureMessage(context, error),
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
          const SizedBox(height: EpSpace.s6),
          FilledButton(
            onPressed:
                _code.text.length == VerifyCodeScreen.codeLength &&
                    !_verifying &&
                    !_lockedOut
                ? _verify
                : null,
            child: Text(l10n.otpVerify),
          ),
          const SizedBox(height: EpSpace.s3),
          Text(
            _waitedLong ? l10n.otpDelayedHint : l10n.otpNoCodeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (isDevBackend) ...[
            const SizedBox(height: EpSpace.s4),
            Text(
              l10n.devOtpHint(LocalBackend.devOtpCode),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// One hidden field drawn as six boxes, so paste and SMS autofill work.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < VerifyCodeScreen.codeLength; i++) ...[
              if (i > 0) const SizedBox(width: EpSpace.s2),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasError
                          ? EpColors.destructiveTint
                          : EpColors.surface,
                      borderRadius: EpRadius.mdAll,
                      border: Border.all(
                        width: i == text.length ? 2 : 1,
                        color: hasError
                            ? EpColors.destructiveGraphic
                            : i == text.length
                            ? EpColors.borderSelected
                            : EpColors.borderDefault,
                      ),
                    ),
                    child: Text(
                      i < text.length ? context.digits(text[i]) : '',
                      style: const TextStyle(
                        fontSize: EpTextSize.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              key: const ValueKey('otp-field'),
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              inputFormatters: [
                _BanglaToAsciiDigits(),
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(VerifyCodeScreen.codeLength),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BanglaToAsciiDigits extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = normalizeDigits(newValue.text);
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
