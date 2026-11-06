import 'dart:convert';
import 'dart:io';

import 'package:epushti/features/bmi/data/who_under_five_reference.dart';
import 'package:epushti/features/bmi/domain/entities/bmi_models.dart';
import 'package:epushti/features/bmi/presentation/widgets/growth_chart.dart';
import 'package:epushti/features/bmi/presentation/widgets/under_five_charts.dart';
import 'package:epushti/features/profile/domain/profile_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

LmsTable _load(String key, {bool tenths = false}) => LmsTable.parse(
  File(UnderFiveReference.assets[key]!).readAsStringSync(),
  tenths: tenths,
);

const _account = 'acc1';

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
).last;

void main() {
  group('WHO 2006 tables reproduce published values', () {
    final wfa = _load('wfa');
    final lhfa = _load('lhfa');
    final wfl = _load('wfl', tenths: true);
    final wfh = _load('wfh', tenths: true);

    test('coverage', () {
      expect(wfa.rowCount, 2 * 1857);
      expect(lhfa.rowCount, 2 * 1857);
      expect((wfa.minKey, wfa.maxKey), (0, 1856));
      expect((wfl.minKey, wfl.maxKey), (450, 1100));
      expect((wfh.minKey, wfh.maxKey), (650, 1200));
    });

    test('published SD values (from the same WHO files)', () {
      // (table, sex, key, z, published value)
      final cases = [
        (wfa, Sex.male, 0, 0.0, 3.346),
        (wfa, Sex.male, 0, 2.0, 4.419),
        (wfa, Sex.male, 0, -2.0, 2.459),
        (wfa, Sex.male, 1856, 0.0, 18.497),
        (wfa, Sex.male, 1856, -2.0, 14.175),
        (lhfa, Sex.female, 0, 0.0, 49.148),
        (lhfa, Sex.female, 0, -2.0, 45.422),
        (lhfa, Sex.female, 1856, 0.0, 109.935),
        (lhfa, Sex.female, 1856, 2.0, 119.517),
        (wfl, Sex.male, 450, 0.0, 2.441),
        (wfl, Sex.male, 450, 2.0, 2.951),
        (wfl, Sex.male, 1100, 0.0, 18.269),
        (wfh, Sex.female, 650, 0.0, 7.24),
        (wfh, Sex.female, 650, -2.0, 6.071),
        (wfh, Sex.female, 1200, 0.0, 22.817),
      ];
      for (final (table, sex, key, z, value) in cases) {
        expect(
          bmiAtZ(table.at(sex, key)!, z),
          closeTo(value, 0.001),
          reason: '$sex $key z=$z',
        );
      }
      expect(wfl.atCm(Sex.male, 45.04), isNotNull);
    });

    test('age in days', () {
      expect(ageInDays(DateTime(2023, 9, 1), DateTime(2023, 9, 1, 18)), 0);
      expect(ageInDays(DateTime(2023, 9, 1), DateTime(2024, 9, 1)), 366);
    });
  });

  group('under-5 growth charts in BMI history', () {
    Map<String, Object> stored() {
      final dob = DateTime.now().subtract(const Duration(days: 3 * 365 + 60));
      final nadia = Person(
        id: 'k2',
        relationship: Relationship.child,
        name: 'Nadia',
        dateOfBirth: dob,
        sex: Sex.female,
      );
      Measurement m(String id, int daysOld, double h, double w) => Measurement(
        id: id,
        personId: 'k2',
        measuredAt: dob.add(Duration(days: daysOld)),
        heightCm: h,
        weightKg: w,
      );
      return {
        'local_backend_session': jsonEncode({
          'id': _account,
          'phone': '+8801812345678',
        }),
        'local_backend_accounts': jsonEncode({_account: '+8801812345678'}),
        'local_${_account}_people': jsonEncode([
          {'id': 'h1', 'relationship': 'holder', 'name': 'Rima'},
          nadia.toJson(),
        ]),
        'local_${_account}_measurements': jsonEncode([
          for (final x in [
            m('a', 800, 84, 11.2),
            m('b', 1000, 89, 12.1),
            m('c', 1150, 93, 13.0),
          ])
            x.toJson(),
        ]),
      };
    }

    testWidgets('weight-for-age by default; switch to weight-for-height', (
      tester,
    ) async {
      await pumpAppAtHome(tester, storedValues: stored());
      await pushRoute(tester, '/bmi/history?p=k2');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('chart-weight-for-age')),
        200,
        scrollable: _vertical,
      );
      expect(find.byKey(const ValueKey('under-five-charts')), findsOneWidget);

      await tapAndSettle(tester, find.text('Weight for height'));
      expect(
        find.byKey(const ValueKey('chart-weight-for-height')),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Height for age'));
      expect(
        find.byKey(const ValueKey('chart-height-for-age')),
        findsOneWidget,
      );
      // No BMI-for-age chart before 5 years.
      expect(find.byKey(const ValueKey('growth-chart')), findsNothing);
    });

    testWidgets('sex "other" explains why there is no chart', (tester) async {
      final values = stored();
      values['local_${_account}_people'] = jsonEncode([
        {'id': 'h1', 'relationship': 'holder', 'name': 'Rima'},
        {
          'id': 'k2',
          'relationship': 'child',
          'name': 'Nadia',
          'date_of_birth': DateTime.now()
              .subtract(const Duration(days: 1200))
              .toIso8601String()
              .substring(0, 10),
          'sex': 'other',
        },
      ]);
      await pumpAppAtHome(tester, storedValues: values);
      await pushRoute(tester, '/bmi/history?p=k2');
      await tester.scrollUntilVisible(
        find.textContaining('separate for boys and girls'),
        200,
        scrollable: _vertical,
      );

      expect(
        find.textContaining('separate for boys and girls'),
        findsOneWidget,
      );
    });
  });
}
