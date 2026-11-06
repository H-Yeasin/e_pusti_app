import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/profile_labels.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../data/who_bmi_for_age_reference.dart';
import '../../data/who_under_five_reference.dart';
import '../../domain/bmi_engine.dart';
import '../../domain/entities/bmi_models.dart';
import '../widgets/growth_chart.dart';
import '../widgets/under_five_charts.dart';

/// BMI-03 — records per person, correctable and deletable.
class BmiHistoryScreen extends ConsumerStatefulWidget {
  const BmiHistoryScreen({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<BmiHistoryScreen> createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends ConsumerState<BmiHistoryScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final family = ref.watch(familyProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.historyTitle),
      body: EpAsyncView(
        value: family,
        onRetry: () => ref.invalidate(familyProvider),
        data: (people) {
          if (people.isEmpty) return const SizedBox.shrink();
          final person =
              people
                  .where((p) => p.id == (_selected ?? widget.personId))
                  .firstOrNull ??
              people.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(EpSpace.gutter),
                child: Row(
                  children: [
                    for (final p in people)
                      Padding(
                        padding: const EdgeInsets.only(right: EpSpace.s2),
                        child: ChoiceChip(
                          label: Text(personName(context, p)),
                          selected: p.id == person.id,
                          onSelected: (_) => setState(() => _selected = p.id),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _PersonHistory(person: person)),
            ],
          );
        },
      ),
    );
  }
}

class _PersonHistory extends ConsumerWidget {
  const _PersonHistory({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final records = ref.watch(measurementsProvider(person.id));

    return EpAsyncView(
      value: records,
      onRetry: () => ref.invalidate(measurementsProvider(person.id)),
      data: (items) {
        if (items.isEmpty) {
          return EpStateView(
            key: const ValueKey('history-empty'),
            icon: Icons.straighten_rounded,
            title: l10n.historyEmptyTitle,
            body: l10n.historyEmptyBody,
            primaryLabel: l10n.historyAddAction,
            onPrimary: () => context.push(
              Uri(
                path: AppRoutes.bmi,
                queryParameters: {'p': person.id},
              ).toString(),
            ),
          );
        }
        final age = person.ageMonthsAt(DateTime.now());
        final header = [
          personName(context, person),
          if (age != null) ageLabel(context, age),
        ].join(' · ');
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: EpSpace.gutter),
          children: [
            Text(
              l10n.historyHeader(header, context.digits(items.length)),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: EpSpace.s3),
            for (final m in items)
              Card(
                margin: const EdgeInsets.only(bottom: EpSpace.s2),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    '${formatShortDate(context, m.measuredAt)} '
                    '${context.digits(m.measuredAt.year)}',
                  ),
                  subtitle: Text(
                    l10n.historyRowMeta(
                      m.heightCm.toStringAsFixed(1),
                      m.weightKg.toStringAsFixed(1),
                    ),
                  ),
                  trailing: Text(
                    _bmiText(context, person, m),
                    style: const TextStyle(
                      fontSize: EpTextSize.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: EpColors.clinicalStrong,
                    ),
                  ),
                  onTap: () => _edit(context, ref, m),
                ),
              ),
            const SizedBox(height: EpSpace.s3),
            _GrowthSection(person: person, records: items),
            const SizedBox(height: EpSpace.s6),
          ],
        );
      },
    );
  }

  /// No BMI number where the result screen would show none (under 5, or
  /// under 19 with sex "other").
  static String _bmiText(BuildContext context, Person person, Measurement m) {
    final age = person.ageMonthsAt(m.measuredAt);
    if (age != null && age < BmiEngine.childFromMonths) return '—';
    if (age != null &&
        age < BmiEngine.adultFromMonths &&
        (person.sex == null || person.sex == Sex.other)) {
      return '—';
    }
    return context.digits(m.bmi.toStringAsFixed(1));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Measurement m) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditSheet(measurement: m),
    );
  }
}

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.measurement});

  final Measurement measurement;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final _height = TextEditingController(
    text: widget.measurement.heightCm.toStringAsFixed(1),
  );
  late final _weight = TextEditingController(
    text: widget.measurement.weightKg.toStringAsFixed(1),
  );

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _valid {
    final h = parseLocalizedNumber(_height.text);
    final w = parseLocalizedNumber(_weight.text);
    return h != null &&
        w != null &&
        h >= BmiLimits.minHeightCm &&
        h <= BmiLimits.maxHeightCm &&
        w >= BmiLimits.minWeightKg &&
        w <= BmiLimits.maxWeightKg;
  }

  Future<void> _save() async {
    final m = widget.measurement;
    await ref
        .read(measurementActionsProvider)
        .save(
          Measurement(
            id: m.id,
            personId: m.personId,
            measuredAt: m.measuredAt,
            heightCm: parseLocalizedNumber(_height.text)!,
            weightKg: parseLocalizedNumber(_weight.text)!,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: EpColors.destructiveFill,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(measurementActionsProvider).delete(widget.measurement);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    InputDecoration deco(String label, String suffix) => InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EpSpace.s6,
        0,
        EpSpace.s6,
        EpSpace.s6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.historyEditTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: EpSpace.s4),
          TextField(
            key: const ValueKey('edit-height'),
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: deco(l10n.bmiHeight, l10n.bmiUnitCm),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: EpSpace.s3),
          TextField(
            key: const ValueKey('edit-weight'),
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: deco(l10n.bmiWeight, l10n.bmiKg),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: EpSpace.s5),
          FilledButton(
            onPressed: _valid ? _save : null,
            child: Text(l10n.saveAction),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: EpColors.destructiveFill,
            ),
            onPressed: _delete,
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }
}

/// Growth charts for the records this person has: WHO 2006 standards
/// before age 5, WHO 2007 BMI-for-age from 5 to 19, none for adults.
class _GrowthSection extends ConsumerWidget {
  const _GrowthSection({required this.person, required this.records});

  final Person person;
  final List<Measurement> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    final sex = person.sex;
    final dob = person.dateOfBirth;
    final childRecords = [
      for (final m in records)
        if (person.ageMonthsAt(m.measuredAt) case final age?
            when age < BmiEngine.adultFromMonths)
          m,
    ];
    final adultNow =
        (person.ageMonthsAt(DateTime.now()) ?? 0) >= BmiEngine.adultFromMonths;

    if (dob == null) {
      return adultNow
          ? const SizedBox.shrink()
          : Text(
              l10n.growthNeedsDob,
              textAlign: TextAlign.center,
              style: small,
            );
    }
    if (childRecords.isEmpty) return const SizedBox.shrink();
    if (sex == null || sex == Sex.other) {
      return Text(
        l10n.growthNeedsSex,
        textAlign: TextAlign.center,
        style: small,
      );
    }

    final under5 = ref.watch(underFiveReferenceProvider).value;
    final bmiRef = ref.watch(bmiForAgeReferenceProvider).value;
    final under5Records = [
      for (final m in childRecords)
        if (ageInDays(dob, m.measuredAt) <= underFiveMaxDays) m,
    ];
    final bmiPoints = [
      for (final m in childRecords)
        if (person.ageMonthsAt(m.measuredAt) case final age?
            when age >= BmiEngine.childFromMonths)
          GrowthPoint(ageMonths: age, bmi: m.bmi),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (under5 != null && under5Records.isNotEmpty) ...[
          UnderFiveCharts(
            reference: under5,
            sex: sex,
            dateOfBirth: dob,
            records: under5Records,
          ),
          const SizedBox(height: EpSpace.s5),
        ],
        if (bmiRef != null && bmiPoints.isNotEmpty) ...[
          Text(
            l10n.growthChartTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EpSpace.s2),
          GrowthChart(reference: bmiRef, sex: sex, points: bmiPoints),
          const SizedBox(height: EpSpace.s2),
        ],
        Text(l10n.bmiChildDisclaimer, style: small),
      ],
    );
  }
}
