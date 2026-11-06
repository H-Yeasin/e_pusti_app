import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/learning_models.dart';
import 'assessment_screen.dart';

/// ASM-02. Every answer gets an explanation, right or wrong.
class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key, required this.result});

  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final passed = result.passed;
    final exhausted = !passed && result.attemptsLeft == 0;

    return Scaffold(
      appBar: EpAppBar(title: l10n.bmiResultTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          Container(
            key: ValueKey(passed ? 'result-passed' : 'result-failed'),
            padding: const EdgeInsets.all(EpSpace.s5),
            decoration: BoxDecoration(
              color: passed ? EpColors.green50 : EpColors.n100,
              borderRadius: EpRadius.lgAll,
            ),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  size: 48,
                  color: passed ? EpColors.fillPrimary : EpColors.textSecondary,
                ),
                const SizedBox(height: EpSpace.s2),
                Text(
                  passed ? l10n.resultPassedTitle : l10n.resultFailedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: EpSpace.s2),
                Text(
                  '${context.digits(result.percent)}%',
                  style: const TextStyle(
                    fontSize: EpTextSize.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.resultScoreLine(
                    context.digits(result.correct),
                    context.digits(result.total),
                    context.digits(result.passMarkPercent),
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: EpSpace.s4),
          if (passed && result.certificateCode != null)
            FilledButton(
              onPressed: () => context.pushReplacement(
                AppRoutes.certificate(result.certificateCode!),
              ),
              child: Text(l10n.viewCertificateAction),
            )
          else if (exhausted && result.lockedUntil != null)
            SizedBox(
              height: 260,
              child: AttemptsExhaustedView(until: result.lockedUntil!),
            )
          else if (!passed) ...[
            Text(
              l10n.resultFailedHint(context.digits(result.attemptsLeft)),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: EpSpace.s5),
          Text(l10n.answerReview, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          for (var i = 0; i < result.review.length; i++)
            _ReviewCard(number: i + 1, item: result.review[i]),
          if (!passed && !exhausted) ...[
            const SizedBox(height: EpSpace.s4),
            FilledButton(
              onPressed: () => context.pushReplacement(
                AppRoutes.assessment(result.assessmentId),
              ),
              child: Text(l10n.tryAgainAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.number, required this.item});

  final int number;
  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final chosen = item.chosenIndex;
    final chosenText = chosen == null || chosen >= item.options.length
        ? l10n.noAnswer
        : item.options[chosen];

    return Card(
      margin: const EdgeInsets.only(bottom: EpSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(EpSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.digits(number)}. ${item.prompt}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: EpSpace.s2),
            Row(
              children: [
                Expanded(child: Text('${l10n.yourAnswer}: $chosenText')),
                Icon(
                  item.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: item.isCorrect
                      ? EpColors.fillPrimary
                      : EpColors.destructiveFill,
                  semanticLabel: item.isCorrect ? '✓' : '✕',
                ),
              ],
            ),
            if (!item.isCorrect)
              Padding(
                padding: const EdgeInsets.only(top: EpSpace.s1),
                child: Text(
                  '${l10n.correctAnswer}: ${item.options[item.correctIndex]}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: EpColors.green800,
                  ),
                ),
              ),
            const SizedBox(height: EpSpace.s2),
            Text(item.explanation, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
