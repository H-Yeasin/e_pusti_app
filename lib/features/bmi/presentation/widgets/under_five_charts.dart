import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../profile/domain/profile_models.dart';
import '../../data/who_under_five_reference.dart';
import '../../domain/entities/bmi_models.dart';
import 'growth_chart.dart';

enum UnderFiveIndicator { weightForAge, heightForAge, weightForHeight }

/// Days are the WHO tables' unit; charts show months.
const _daysPerMonth = 30.4375;

/// Up to and including 1856 days (5 years) is covered by the 2006 tables.
const underFiveMaxDays = 1856;

int ageInDays(DateTime dob, DateTime at) => DateTime(
  at.year,
  at.month,
  at.day,
).difference(DateTime(dob.year, dob.month, dob.day)).inDays;

/// P2-1 (under 5): the child's measurements on the WHO 2006 Child Growth
/// Standards — weight-for-age, length/height-for-age and
/// weight-for-length/height ("উচ্চতা-অনুযায়ী ওজন" in BMI-02 case 3).
class UnderFiveCharts extends StatefulWidget {
  const UnderFiveCharts({
    super.key,
    required this.reference,
    required this.sex,
    required this.dateOfBirth,
    required this.records,
  });

  final UnderFiveReference reference;
  final Sex sex;
  final DateTime dateOfBirth;
  final List<Measurement> records;

  @override
  State<UnderFiveCharts> createState() => _UnderFiveChartsState();
}

class _UnderFiveChartsState extends State<UnderFiveCharts> {
  UnderFiveIndicator _indicator = UnderFiveIndicator.weightForAge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aged = [
      for (final m in widget.records)
        if (ageInDays(widget.dateOfBirth, m.measuredAt) case final d
            when d >= 0 && d <= underFiveMaxDays)
          (days: d, m: m),
    ];
    if (aged.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('under-five-charts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.under5Title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EpSpace.s2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<UnderFiveIndicator>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: UnderFiveIndicator.weightForAge,
                label: Text(l10n.indWeightForAge),
              ),
              ButtonSegment(
                value: UnderFiveIndicator.heightForAge,
                label: Text(l10n.indHeightForAge),
              ),
              ButtonSegment(
                value: UnderFiveIndicator.weightForHeight,
                label: Text(l10n.indWeightForHeight),
              ),
            ],
            selected: {_indicator},
            onSelectionChanged: (s) => setState(() => _indicator = s.first),
          ),
        ),
        const SizedBox(height: EpSpace.s3),
        _chart(context, aged),
      ],
    );
  }

  Widget _chart(BuildContext context, List<({int days, Measurement m})> aged) {
    final l10n = context.l10n;
    final sex = widget.sex;
    final ref = widget.reference;

    if (_indicator == UnderFiveIndicator.weightForHeight) {
      // Lying length under 2 years, standing height from 2 years; plot the
      // position of the most recent measurement.
      final latest = aged.reduce((a, b) => a.days >= b.days ? a : b);
      final lying = latest.days < 731;
      final table = lying ? ref.weightForLength : ref.weightForHeight;
      final pts = [
        for (final a in aged)
          if ((a.days < 731) == lying &&
              (a.m.heightCm * 10).round() >= table.minKey &&
              (a.m.heightCm * 10).round() <= table.maxKey)
            Offset(a.m.heightCm, a.m.weightKg),
      ];
      if (pts.isEmpty) {
        return Text(
          l10n.under5OutOfRange,
          style: Theme.of(context).textTheme.bodySmall,
        );
      }
      final xs = pts.map((p) => p.dx);
      final from = math.max(table.minKey / 10, xs.reduce(math.min) - 5);
      final to = math.min(table.maxKey / 10, xs.reduce(math.max) + 5);
      return ReferenceChart(
        chartKey: const ValueKey('chart-weight-for-height'),
        curves: {
          for (final z in referenceCurves)
            z: [
              for (var t = (from * 10).round(); t <= (to * 10).round(); t += 5)
                if (table.at(sex, t) case final lms?)
                  Offset(t / 10, bmiAtZ(lms, z)),
            ],
        },
        points: pts,
        xFrom: from,
        xTo: to,
        xStep: (to - from) > 30 ? 10 : 5,
        xLabel: (x) => context.digits(x.round()),
        shadeTo: 2,
        legend:
            '${l10n.under5Legend} ${l10n.under5AxisCm} ${l10n.under5LengthNote}',
        semanticLabel: l10n.growthChartSemantic(context.digits(pts.length)),
      );
    }

    final table = _indicator == UnderFiveIndicator.weightForAge
        ? ref.weightForAge
        : ref.lengthHeightForAge;
    double value(Measurement m) =>
        _indicator == UnderFiveIndicator.weightForAge ? m.weightKg : m.heightCm;
    final days = aged.map((a) => a.days);
    final fromDay = math.max(0, days.reduce(math.min) - 60);
    final toDay = math.min(underFiveMaxDays, days.reduce(math.max) + 60);

    return ReferenceChart(
      chartKey: ValueKey(
        _indicator == UnderFiveIndicator.weightForAge
            ? 'chart-weight-for-age'
            : 'chart-height-for-age',
      ),
      curves: {
        for (final z in referenceCurves)
          z: [
            for (var d = fromDay; d <= toDay; d += 7)
              if (table.at(sex, d) case final lms?)
                Offset(d / _daysPerMonth, bmiAtZ(lms, z)),
          ],
      },
      points: [
        for (final a in aged) Offset(a.days / _daysPerMonth, value(a.m)),
      ],
      xFrom: fromDay / _daysPerMonth,
      xTo: toDay / _daysPerMonth,
      xStep: (toDay - fromDay) / _daysPerMonth > 24 ? 6 : 3,
      xLabel: (x) => context.digits(x.round()),
      shadeTo: 2,
      legend: '${l10n.under5Legend} ${l10n.under5AxisMonths}',
      semanticLabel: l10n.growthChartSemantic(context.digits(aged.length)),
    );
  }
}
