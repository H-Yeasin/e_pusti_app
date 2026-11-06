import 'dart:io';
import 'dart:math' as math;

import 'package:epushti/features/bmi/data/who_bmi_for_age_reference.dart';
import 'package:epushti/features/bmi/domain/bmi_engine.dart';
import 'package:epushti/features/bmi/domain/entities/bmi_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the bundled WHO 2007 table against values published in the WHO
/// "z-score expanded tables" (SD columns of the same source files).
void main() {
  final table = WhoBmiForAgeReference.parse(
    File(WhoBmiForAgeReference.assetPath).readAsStringSync(),
  );

  double bmiAt(Sex sex, int month, double z) {
    final lms = table.lookup(sex, month)!;
    return lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l);
  }

  test('covers months 61–228 for boys and girls', () {
    expect(table.rowCount, 336);
    for (final sex in [Sex.male, Sex.female]) {
      expect(table.lookup(sex, 61), isNotNull);
      expect(table.lookup(sex, 228), isNotNull);
      expect(table.lookup(sex, 60), isNull);
      expect(table.lookup(sex, 229), isNull);
    }
  });

  test('reproduces published WHO SD values', () {
    // (sex, month, z, published BMI) from the WHO expanded tables.
    const published = [
      (Sex.male, 61, -2.0, 13.031),
      (Sex.male, 61, 0.0, 15.264),
      (Sex.male, 61, 1.0, 16.645),
      (Sex.male, 61, 2.0, 18.259),
      (Sex.female, 61, -2.0, 12.748),
      (Sex.female, 61, 0.0, 15.244),
      (Sex.female, 61, 2.0, 18.858),
      (Sex.female, 228, -2.0, 16.497),
      (Sex.female, 228, 1.0, 24.965),
      (Sex.female, 228, 2.0, 29.670),
    ];
    for (final (sex, month, z, value) in published) {
      expect(
        bmiAt(sex, month, z),
        closeTo(value, 0.001),
        reason: '$sex month $month z $z',
      );
    }
  });

  test('design example: boy 9 y 4 m, BMI 15.8 is normal', () {
    final outcome = BmiEngine(table).evaluate(
      const BmiInput(
        heightCm: 132,
        weightKg: 27.5,
        ageMonths: 112,
        sex: Sex.male,
      ),
    );
    expect(outcome, isA<ChildBmiOutcome>());
    expect((outcome as ChildBmiOutcome).category, ChildBmiCategory.normal);
  });

  test('girl 12 y with BMI above +2 SD is obesity', () {
    final bmi = bmiAt(Sex.female, 144, 2.2);
    final heightCm = 150.0;
    final weightKg = bmi * math.pow(heightCm / 100, 2);
    final outcome = BmiEngine(table).evaluate(
      BmiInput(
        heightCm: heightCm,
        weightKg: weightKg.toDouble(),
        ageMonths: 144,
        sex: Sex.female,
      ),
    );
    expect((outcome as ChildBmiOutcome).category, ChildBmiCategory.obesity);
    expect(outcome.zScore, closeTo(2.2, 1e-6));
  });
}
