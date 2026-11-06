import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_failure.dart';
import '../../localization/digits.dart';
import '../../localization/localization.dart';
import '../../theme/app_tokens.dart';
import 'ep_state_view.dart';

/// Renders an [AsyncValue] with the design's system states:
///
/// * loading → spinner, then after 3 s the slow-connection skeleton (SYS-02)
/// * [NoConnectionFailure] → offline message (SYS-01)
/// * [ContentServerUnavailableFailure] → content server message (DGS-02)
/// * anything else → server error with code and time (SYS-03)
class EpAsyncView<T> extends StatelessWidget {
  const EpAsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.onReportToSupport,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final VoidCallback? onReportToSupport;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    // Errors first: a provider that is reloading after a failure is
    // "loading with an error", and must still show the failure state.
    if (value.hasError) {
      return EpFailureView(
        failure: value.error!,
        onRetry: onRetry,
        onReportToSupport: onReportToSupport,
      );
    }
    if (value.hasValue) {
      return data(value.requireValue);
    }
    return const EpLoadingView();
  }
}

/// Spinner that becomes the slow-connection skeleton after [slowAfter].
class EpLoadingView extends StatefulWidget {
  const EpLoadingView({super.key, this.slowAfter = const Duration(seconds: 3)});

  final Duration slowAfter;

  @override
  State<EpLoadingView> createState() => _EpLoadingViewState();
}

class _EpLoadingViewState extends State<EpLoadingView> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.slowAfter, () {
      if (mounted) {
        setState(() => _slow = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_slow) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(EpSpace.gutter),
      children: [
        Container(
          padding: const EdgeInsets.all(EpSpace.s3),
          decoration: const BoxDecoration(
            color: EpColors.n100,
            borderRadius: EpRadius.mdAll,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: EpSpace.s3),
              Expanded(child: Text(l10n.slowConnection)),
              if (Navigator.of(context).canPop())
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.cancelAction),
                ),
            ],
          ),
        ),
        const SizedBox(height: EpSpace.s4),
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 72,
            decoration: const BoxDecoration(
              color: EpColors.n100,
              borderRadius: EpRadius.mdAll,
            ),
          ),
          const SizedBox(height: EpSpace.s3),
        ],
      ],
    );
  }
}

class EpFailureView extends StatelessWidget {
  const EpFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.onReportToSupport,
  });

  final Object failure;
  final VoidCallback onRetry;
  final VoidCallback? onReportToSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (failure) {
      NoConnectionFailure() => EpStateView(
        icon: Icons.wifi_off_rounded,
        title: l10n.offlineTitle,
        body: l10n.offlineBody,
        primaryLabel: l10n.retryAction,
        onPrimary: onRetry,
      ),
      ContentServerUnavailableFailure() => EpStateView(
        icon: Icons.cloud_off_rounded,
        title: l10n.contentServerTitle,
        body: l10n.contentServerBody,
        primaryLabel: l10n.retryAction,
        onPrimary: onRetry,
      ),
      _ => _ServerError(
        failure: failure,
        onRetry: onRetry,
        onReportToSupport: onReportToSupport,
      ),
    };
  }
}

class _ServerError extends StatelessWidget {
  const _ServerError({
    required this.failure,
    required this.onRetry,
    this.onReportToSupport,
  });

  final Object failure;
  final VoidCallback onRetry;
  final VoidCallback? onReportToSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = this.failure;
    final (code, at) = failure is ServerFailure
        ? (failure.code, failure.occurredAt)
        : ('ERR-APP', DateTime.now());
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';

    return EpStateView(
      tone: EpStateTone.destructive,
      icon: Icons.warning_amber_rounded,
      title: l10n.serverErrorTitle,
      body: l10n.serverErrorBody,
      primaryLabel: l10n.retryAction,
      onPrimary: onRetry,
      secondaryLabel: onReportToSupport == null ? null : l10n.reportToSupport,
      onSecondary: onReportToSupport,
      footnote: context.digits('$code · $stamp'),
    );
  }
}
