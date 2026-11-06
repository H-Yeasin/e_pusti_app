import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/learning_models.dart';
import '../learning_providers.dart';

/// ASM-01. One question per screen; answers are kept on the device so
/// leaving, or a failed submit, never loses them.
class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final assessment = ref.watch(assessmentProvider(assessmentId));
    final status = ref.watch(attemptStatusProvider(assessmentId));

    final combined = switch ((assessment, status)) {
      (AsyncData(value: final a), AsyncData(value: final s)) => AsyncData((
        a,
        s,
      )),
      (AsyncError(:final error, :final stackTrace), _) ||
      (
        _,
        AsyncError(:final error, :final stackTrace),
      ) => AsyncError<(Assessment, AttemptStatus)>(error, stackTrace),
      _ => const AsyncLoading<(Assessment, AttemptStatus)>(),
    };

    if (combined case AsyncData(value: (final a, final s))) {
      if (s.isLocked(DateTime.now())) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.assessmentTitle)),
          body: AttemptsExhaustedView(until: s.lockedUntil!),
        );
      }
      return _QuizFlow(assessment: a, status: s);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assessmentTitle)),
      body: EpAsyncView(
        value: combined,
        onRetry: () {
          ref.invalidate(assessmentProvider(assessmentId));
          ref.invalidate(attemptStatusProvider(assessmentId));
        },
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

class AttemptsExhaustedView extends StatelessWidget {
  const AttemptsExhaustedView({super.key, required this.until});

  final DateTime until;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EpStateView(
      key: const ValueKey('attempts-exhausted'),
      icon: Icons.hourglass_top_rounded,
      title: l10n.attemptsExhaustedTitle,
      body: l10n.attemptsExhaustedBody(formatEventDateTime(context, until)),
      primaryLabel: l10n.backToHomeAction,
      onPrimary: () => context.go(AppRoutes.home),
    );
  }
}

class _QuizFlow extends ConsumerStatefulWidget {
  const _QuizFlow({required this.assessment, required this.status});

  final Assessment assessment;
  final AttemptStatus status;

  @override
  ConsumerState<_QuizFlow> createState() => _QuizFlowState();
}

class _QuizFlowState extends ConsumerState<_QuizFlow> {
  late Map<String, int> _answers;
  late int _index;
  bool _submitting = false;
  bool _submitFailed = false;

  Assessment get _a => widget.assessment;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(assessmentDraftStoreProvider)?.read(_a.id);
    _answers = {...?draft?.answers};
    _index = (draft?.index ?? 0).clamp(0, _a.questions.length - 1);
  }

  Future<void> _persist() async {
    await ref
        .read(assessmentDraftStoreProvider)
        ?.save(_a.id, AssessmentDraft(answers: _answers, index: _index));
  }

  void _choose(int option) {
    setState(() => _answers[_a.questions[_index].id] = option);
    _persist();
  }

  void _next() {
    setState(() => _index++);
    _persist();
  }

  Future<void> _exit() async {
    if (_answers.isEmpty) {
      context.pop();
      return;
    }
    final l10n = context.l10n;
    final leave = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EpSpace.s6,
            0,
            EpSpace.s6,
            EpSpace.s6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.exitAssessmentTitle,
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: EpSpace.s2),
              Text(l10n.exitAssessmentBody),
              const SizedBox(height: EpSpace.s6),
              OutlinedButton(
                onPressed: () => Navigator.of(sheet).pop(true),
                child: Text(l10n.exitAction),
              ),
              const SizedBox(height: EpSpace.s2),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(false),
                child: Text(l10n.keepGoingAction),
              ),
            ],
          ),
        ),
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  /// Certificates print the holder's name; ask for it once if missing.
  Future<String?> _holderName() async {
    final holder =
        ref.read(holderProvider) ??
        (await ref.read(
          familyProvider.future,
        )).where((p) => p.isHolder).firstOrNull;
    final existing = holder?.name?.trim() ?? '';
    if (existing.isNotEmpty || !_a.issuesCertificate) return existing;
    if (!mounted) return null;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NameDialog(),
    );
    if (name == null || name.trim().isEmpty) return null;
    if (holder != null) {
      await ref
          .read(familyProvider.notifier)
          .save(holder.copyWith(name: name.trim()));
    }
    return name.trim();
  }

  Future<void> _submit() async {
    final name = await _holderName();
    if (name == null || !mounted) return;
    setState(() {
      _submitting = true;
      _submitFailed = false;
    });
    final backend = ref.read(learningBackendProvider);
    try {
      final result = await backend!.submit(_a.id, _answers, holderName: name);
      await ref.read(assessmentDraftStoreProvider)?.clear(_a.id);
      ref.invalidate(attemptStatusProvider(_a.id));
      ref.invalidate(progressProvider);
      ref.invalidate(certificatesProvider);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.assessmentResult(_a.id), extra: result);
    } on AttemptsExhaustedFailure {
      ref.invalidate(attemptStatusProvider(_a.id));
    } catch (_) {
      if (mounted) setState(() => _submitFailed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final q = _a.questions[_index];
    final chosen = _answers[q.id];
    final last = _index == _a.questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const ValueKey('assessment-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: _exit,
          ),
          title: Text(l10n.assessmentTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.all(EpSpace.gutter),
          children: [
            Text(
              l10n.questionCounter(
                context.digits(_index + 1),
                context.digits(_a.questions.length),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: EpSpace.s2),
            ClipRRect(
              borderRadius: EpRadius.smAll,
              child: LinearProgressIndicator(
                value: (_index + 1) / _a.questions.length,
                minHeight: 6,
                backgroundColor: EpColors.n100,
                color: EpColors.fillPrimary,
              ),
            ),
            const SizedBox(height: EpSpace.s5),
            Text(q.prompt, style: theme.textTheme.titleLarge),
            const SizedBox(height: EpSpace.s4),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: EpSpace.s2),
                child: _OptionCard(
                  label: q.options[i],
                  selected: chosen == i,
                  onTap: () => _choose(i),
                ),
              ),
            if (_submitFailed) ...[
              const SizedBox(height: EpSpace.s2),
              EpBanner(
                key: const ValueKey('submit-failed'),
                tone: EpBannerTone.destructive,
                icon: Icons.cloud_off_rounded,
                message: l10n.submitFailed,
              ),
            ],
            const SizedBox(height: EpSpace.s5),
            FilledButton(
              key: const ValueKey('assessment-next'),
              onPressed: chosen == null || _submitting
                  ? null
                  : (last ? _submit : _next),
              child: Text(last ? l10n.submitAction : l10n.nextAction),
            ),
            if (_index > 0)
              TextButton(
                onPressed: () {
                  setState(() => _index--);
                  _persist();
                },
                child: Text(l10n.previousAction),
              ),
            const SizedBox(height: EpSpace.s2),
            Text(
              l10n.attemptsLeftNote(context.digits(widget.status.attemptsLeft)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? EpColors.green50 : EpColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: EpRadius.mdAll,
          side: BorderSide(
            width: selected ? 2 : 1,
            color: selected ? EpColors.borderSelected : EpColors.borderDefault,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(EpSpace.s4),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? EpColors.fillPrimary : EpColors.n500,
                ),
                const SizedBox(width: EpSpace.s3),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: EpTextSize.body),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.certificateNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.certificateNameBody),
          const SizedBox(height: EpSpace.s3),
          TextField(
            key: const ValueKey('certificate-name'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l10n.fieldNameHint),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        TextButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_name.text),
          child: Text(l10n.saveAction),
        ),
      ],
    );
  }
}
