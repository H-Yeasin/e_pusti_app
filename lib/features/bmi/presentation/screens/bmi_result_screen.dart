import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../../../notifications/presentation/engagement_providers.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/profile_labels.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../data/who_bmi_for_age_reference.dart';
import '../../domain/bmi_engine.dart';
import '../../domain/entities/bmi_models.dart';
import '../widgets/sex_label.dart';

/// BMI-02. Drawn in the clinical palette only — no green, amber or red
/// carries a health reading. Cases 3 and 4 show no number at all.
class BmiResultScreen extends ConsumerWidget {
  const BmiResultScreen({super.key, required this.input, this.personId});

  final BmiInput input;

  /// The family member this measurement is for, when chosen on entry.
  final String? personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reference = ref.watch(bmiForAgeReferenceProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.bmiResultTitle),
      body: reference.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ResultBody(
          outcome: const BmiEngine(null).evaluate(input),
          personId: personId,
        ),
        data: (table) => _ResultBody(
          outcome: BmiEngine(table).evaluate(input),
          personId: personId,
        ),
      ),
    );
  }
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.outcome, this.personId});

  final BmiOutcome outcome;
  final String? personId;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final here = GoRouterState.of(context).uri.toString();
    if (!ref.read(authControllerProvider).isLoggedIn) {
      showLoginPrompt(context, returnTo: here, body: l10n.bmiSavePromptBody);
      return;
    }
    final consent = await ref.read(consentProvider.future);
    if (!context.mounted) return;
    if (!consent.canStoreHealthData) {
      context.push(AppRoutes.consentReturningTo(here));
      return;
    }
    final family = await ref.read(familyProvider.future);
    if (!context.mounted) return;
    final person =
        family.where((p) => p.id == personId).firstOrNull ??
        await _choosePerson(context, family);
    if (person == null || !context.mounted) return;

    final input = outcome.input;
    final measurement = Measurement(
      id: newId(),
      personId: person.id,
      measuredAt: DateTime.now(),
      heightCm: input.heightCm,
      weightKg: input.weightKg,
    );
    await ref.read(measurementActionsProvider).save(measurement);
    if (!context.mounted) return;
    // P1-4: remind when the next measurement is due for this person.
    await ref
        .read(reminderPlannerProvider)
        .planMeasurement(
          person,
          measurement,
          title: l10n.reminderMeasureTitle,
          body: l10n.reminderMeasureBody(personName(context, person)),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.bmiSavedToast),
          action: SnackBarAction(
            label: l10n.bmiSeeHistory,
            onPressed: () => context.push(
              Uri(
                path: AppRoutes.bmiHistory,
                queryParameters: {'p': person.id},
              ).toString(),
            ),
          ),
        ),
      );
  }

  Future<Person?> _choosePerson(BuildContext context, List<Person> family) {
    final l10n = context.l10n;
    return showModalBottomSheet<Person>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EpSpace.s6),
              child: Text(
                l10n.bmiChoosePerson,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final p in family)
              ListTile(
                title: Text(personName(context, p)),
                subtitle: Text(personSummary(context, p, withRelation: true)),
                onTap: () => Navigator.of(sheetContext).pop(p),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final input = outcome.input;
    final person = (ref.watch(familyProvider).value ?? const <Person>[])
        .where((p) => p.id == personId)
        .firstOrNull;
    final ageText = input.ageMonths == null
        ? null
        : l10n.bmiAgeValue(
            context.digits(input.ageMonths! ~/ 12),
            context.digits(input.ageMonths! % 12),
          );

    String bmiText(double bmi) => context.digits(bmi.toStringAsFixed(1));

    final children = <Widget>[];
    var saveLabel = l10n.saveAction;

    switch (outcome) {
      case AdultBmiOutcome(:final bmi, :final category):
        children.addAll([
          _Headline(value: bmiText(bmi), label: _adultLabel(context, category)),
          if (ageText != null)
            _Subline(text: _personLine(context, ageText, person)),
          const SizedBox(height: EpSpace.s4),
          Text(_adultBody(context, category), style: theme.textTheme.bodyLarge),
          const SizedBox(height: EpSpace.s5),
          _AdultBands(current: category),
          const SizedBox(height: EpSpace.s4),
          _Disclaimer(text: l10n.bmiDisclaimer),
        ]);
      case NoAgeOutcome(:final bmi, :final category):
        children.addAll([
          _Headline(value: bmiText(bmi), label: l10n.bmiNoAgeLabel),
          _Subline(text: l10n.bmiNoAgeGiven),
          const SizedBox(height: EpSpace.s4),
          EpBanner(
            tone: EpBannerTone.clinical,
            icon: Icons.info_outline_rounded,
            message: l10n.bmiNoAgeBody,
          ),
          const SizedBox(height: EpSpace.s4),
          _AdultBands(current: category),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.bmiNoAgeHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: EpSpace.s3),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text(l10n.bmiAddAgeAction),
          ),
        ]);
      case ChildBmiOutcome(:final bmi, :final zScore, :final category):
        final group = childGroupLabel(context, input.sex!);
        final label = _childLabel(context, category);
        children.addAll([
          _Headline(value: bmiText(bmi), label: label),
          _Subline(text: '$ageText · $group'),
          const SizedBox(height: EpSpace.s4),
          EpBanner(
            tone: EpBannerTone.clinical,
            message: l10n.bmiChildStandardNote,
          ),
          const SizedBox(height: EpSpace.s5),
          Text(l10n.bmiChildPosition, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          _ChildScale(zScore: zScore),
          const SizedBox(height: EpSpace.s4),
          Text(
            l10n.bmiChildCompare(group, label),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: EpSpace.s4),
          _Disclaimer(text: l10n.bmiChildDisclaimer),
        ]);
      case ChildReferenceUnavailableOutcome(:final bmi):
        children.addAll([
          _Headline(value: bmiText(bmi), label: ''),
          _Subline(text: '$ageText · ${childGroupLabel(context, input.sex!)}'),
          const SizedBox(height: EpSpace.s4),
          EpBanner(
            tone: EpBannerTone.clinical,
            icon: Icons.info_outline_rounded,
            message: l10n.bmiChildTablesMissing,
          ),
          const SizedBox(height: EpSpace.s4),
          _Disclaimer(text: l10n.bmiChildDisclaimer),
        ]);
      case UnderFiveOutcome():
        saveLabel = l10n.bmiSaveDataAction;
        children.addAll([
          _Headline(value: null, label: l10n.bmiUnderFiveTitle),
          if (ageText != null)
            _Subline(
              text: input.sex == null || input.sex == Sex.other
                  ? ageText
                  : '$ageText · ${childGroupLabel(context, input.sex!)}',
            ),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.bmiUnderFiveBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: EpSpace.s3),
          Text(l10n.bmiUnderFiveSave, style: theme.textTheme.bodyMedium),
          const SizedBox(height: EpSpace.s4),
          EpBanner(
            tone: EpBannerTone.clinical,
            icon: Icons.local_hospital_outlined,
            message: l10n.bmiUnderFiveAdvice,
          ),
        ]);
      case NoReferenceOutcome():
        saveLabel = l10n.bmiSaveDataAction;
        children.addAll([
          _Headline(value: null, label: l10n.bmiNoReferenceTitle),
          _Subline(
            text: l10n.bmiNoReferenceSubtitle(
              context.digits(input.ageMonths! ~/ 12),
            ),
          ),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.bmiNoReferenceBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: EpSpace.s3),
          Text(l10n.bmiNoReferenceWhy, style: theme.textTheme.bodyMedium),
          const SizedBox(height: EpSpace.s3),
          Text(l10n.bmiNoReferenceSave, style: theme.textTheme.bodyMedium),
        ]);
    }

    return ListView(
      padding: const EdgeInsets.all(EpSpace.gutter),
      children: [
        ...children,
        const SizedBox(height: EpSpace.s8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: EpColors.clinicalStrong,
          ),
          onPressed: () => _save(context, ref),
          child: Text(saveLabel),
        ),
      ],
    );
  }

  String _personLine(BuildContext context, String ageText, Person? person) {
    final sex = outcome.input.sex;
    final parts = [
      if (person != null) personName(context, person),
      ageText,
      if (sex != null) sexLabel(context, sex),
    ];
    return parts.join(' · ');
  }
}

String _adultLabel(BuildContext context, AdultBmiCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    AdultBmiCategory.underweight => l10n.bmiAdultUnderweight,
    AdultBmiCategory.normal => l10n.bmiAdultNormal,
    AdultBmiCategory.overweight => l10n.bmiAdultOverweight,
    AdultBmiCategory.obesity => l10n.bmiAdultObesity,
  };
}

String _adultBody(BuildContext context, AdultBmiCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    AdultBmiCategory.underweight => l10n.bmiAdultUnderweightBody,
    AdultBmiCategory.normal => l10n.bmiAdultNormalBody,
    AdultBmiCategory.overweight => l10n.bmiAdultOverweightBody,
    AdultBmiCategory.obesity => l10n.bmiAdultObesityBody,
  };
}

String _childLabel(BuildContext context, ChildBmiCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    ChildBmiCategory.severeThinness => l10n.bmiChildSevereThinness,
    ChildBmiCategory.thinness => l10n.bmiChildThinness,
    ChildBmiCategory.normal => l10n.bmiChildNormal,
    ChildBmiCategory.overweight => l10n.bmiChildOverweight,
    ChildBmiCategory.obesity => l10n.bmiChildObesity,
  };
}

class _Headline extends StatelessWidget {
  const _Headline({required this.value, required this.label});

  final String? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EpSpace.s5),
      decoration: BoxDecoration(
        color: EpColors.clinicalTint,
        borderRadius: EpRadius.lgAll,
        border: Border.all(color: EpColors.clinicalLine),
      ),
      child: Column(
        children: [
          if (value != null)
            Text(
              value!,
              key: const ValueKey('bmi-value'),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: EpColors.clinicalStrong,
              ),
            ),
          if (label.isNotEmpty)
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: EpTextSize.heading,
                fontWeight: FontWeight.w700,
                color: EpColors.clinicalText,
              ),
            ),
        ],
      ),
    );
  }
}

class _Subline extends StatelessWidget {
  const _Subline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: EpSpace.s2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _AdultBands extends StatelessWidget {
  const _AdultBands({required this.current});

  final AdultBmiCategory current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      (AdultBmiCategory.underweight, l10n.bmiBandUnder),
      (AdultBmiCategory.normal, l10n.bmiBandNormal),
      (AdultBmiCategory.overweight, l10n.bmiBandOver),
      (AdultBmiCategory.obesity, l10n.bmiBandObese),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: EpColors.clinicalLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(EpSpace.s3),
            child: Text(
              l10n.bmiAdultStandard,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: EpColors.clinicalStrong,
              ),
            ),
          ),
          for (final (category, range) in rows)
            Container(
              color: category == current ? EpColors.band1 : null,
              padding: const EdgeInsets.symmetric(
                horizontal: EpSpace.s3,
                vertical: EpSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      range,
                      style: const TextStyle(color: EpColors.clinicalText),
                    ),
                  ),
                  Text(
                    _adultLabel(context, category),
                    style: TextStyle(
                      color: EpColors.clinicalStrong,
                      fontWeight: category == current
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Three-band position scale (thinness · normal · obesity) with a marker.
class _ChildScale extends StatelessWidget {
  const _ChildScale({required this.zScore});

  final double zScore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Map −3…+3 SD onto the bar; −2 and +1 are the band edges.
    final position = ((zScore.clamp(-3.0, 3.0) + 3) / 6);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 8,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: EpRadius.smAll,
                      child: const Row(
                        children: [
                          Expanded(child: ColoredBox(color: EpColors.band2)),
                          Expanded(
                            flex: 3,
                            child: ColoredBox(color: EpColors.band1),
                          ),
                          Expanded(
                            flex: 2,
                            child: ColoredBox(color: EpColors.band2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width * position - 2).clamp(0, width - 4),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: EpColors.n900),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: EpSpace.s1),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.bmiChildThinness,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                l10n.bmiChildNormal,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                l10n.bmiChildObesity,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
