import 'package:epushti/core/localization/digits.dart';
import 'package:epushti/core/utils/version.dart';
import 'package:epushti/features/bmi/data/who_bmi_for_age_reference.dart';
import 'package:epushti/features/bmi/domain/bmi_engine.dart';
import 'package:epushti/features/bmi/domain/entities/bmi_models.dart';
import 'package:epushti/features/bmi/presentation/bmi_route_args.dart';
import 'package:epushti/features/pust9/domain/entities/mobile_operator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic reference for tests only (L = 1 makes z = (BMI/M − 1) / S).
/// Not WHO data.
class _FakeReference implements BmiForAgeReference {
  @override
  Lms? lookup(Sex sex, int ageMonths) =>
      ageMonths >= 61 && ageMonths <= 228 ? const Lms(1, 16, 0.1) : null;
}

BmiInput _input(double h, double w, {int? months, Sex? sex}) =>
    BmiInput(heightCm: h, weightKg: w, ageMonths: months, sex: sex);

void main() {
  const engine = BmiEngine(null);
  final withTables = BmiEngine(_FakeReference());

  group('adult (case 1)', () {
    test('computes BMI and WHO band', () {
      final outcome = engine.evaluate(_input(163, 57, months: 34 * 12));
      expect(outcome, isA<AdultBmiOutcome>());
      final adult = outcome as AdultBmiOutcome;
      expect(adult.bmi, closeTo(21.45, 0.01));
      expect(adult.category, AdultBmiCategory.normal);
    });

    test('band edges follow WHO cut-offs', () {
      expect(BmiEngine.adultCategory(18.49), AdultBmiCategory.underweight);
      expect(BmiEngine.adultCategory(18.5), AdultBmiCategory.normal);
      expect(BmiEngine.adultCategory(24.99), AdultBmiCategory.normal);
      expect(BmiEngine.adultCategory(25), AdultBmiCategory.overweight);
      expect(BmiEngine.adultCategory(29.99), AdultBmiCategory.overweight);
      expect(BmiEngine.adultCategory(30), AdultBmiCategory.obesity);
    });

    test('19 years exactly is adult', () {
      expect(
        engine.evaluate(_input(160, 50, months: 228)),
        isA<AdultBmiOutcome>(),
      );
    });
  });

  test('no age (case 5) uses the adult standard', () {
    final outcome = engine.evaluate(_input(163, 57));
    expect(outcome, isA<NoAgeOutcome>());
    expect((outcome as NoAgeOutcome).category, AdultBmiCategory.normal);
  });

  test('under five (case 3) gives no number', () {
    expect(
      engine.evaluate(_input(95, 14, months: 38, sex: Sex.female)),
      isA<UnderFiveOutcome>(),
    );
    expect(
      engine.evaluate(_input(95, 14, months: 59, sex: Sex.male)),
      isA<UnderFiveOutcome>(),
    );
  });

  test('sex "other" under 19 (case 4) gives no number', () {
    expect(
      withTables.evaluate(_input(155, 45, months: 14 * 12, sex: Sex.other)),
      isA<NoReferenceOutcome>(),
    );
  });

  group('age 5–19 (case 2)', () {
    test('classifies by z-score', () {
      // BMI 16 → z 0 → normal.
      final normal = withTables.evaluate(
        _input(100, 16, months: 9 * 12 + 4, sex: Sex.male),
      );
      expect(normal, isA<ChildBmiOutcome>());
      expect((normal as ChildBmiOutcome).zScore, closeTo(0, 1e-9));
      expect(normal.category, ChildBmiCategory.normal);
    });

    test('category edges', () {
      expect(BmiEngine.childCategory(-3.01), ChildBmiCategory.severeThinness);
      expect(BmiEngine.childCategory(-2.01), ChildBmiCategory.thinness);
      expect(BmiEngine.childCategory(-2), ChildBmiCategory.normal);
      expect(BmiEngine.childCategory(1), ChildBmiCategory.normal);
      expect(BmiEngine.childCategory(1.01), ChildBmiCategory.overweight);
      expect(BmiEngine.childCategory(2), ChildBmiCategory.overweight);
      expect(BmiEngine.childCategory(2.01), ChildBmiCategory.obesity);
    });

    test('5 years 0 months uses the first reference month', () {
      expect(
        withTables.evaluate(_input(100, 16, months: 60, sex: Sex.female)),
        isA<ChildBmiOutcome>(),
      );
    });

    test('without bundled tables shows no classification', () {
      expect(
        engine.evaluate(_input(132, 27.5, months: 112, sex: Sex.male)),
        isA<ChildReferenceUnavailableOutcome>(),
      );
    });

    test('LMS z-score formula, including L = 0', () {
      expect(BmiEngine.zScore(17.6, const Lms(1, 16, 0.1)), closeTo(1, 1e-9));
      expect(BmiEngine.zScore(16, const Lms(0, 16, 0.1)), closeTo(0, 1e-9));
    });
  });

  test('WHO CSV parser reads sex, month and LMS columns', () {
    final table = WhoBmiForAgeReference.parse(
      'sex,month,L,M,S\n1,61,-0.7,15.2,0.08\n2,61,-0.9,15.1,0.09\nbad,row\n',
    );
    expect(table.rowCount, 2);
    expect(table.lookup(Sex.male, 61)!.m, 15.2);
    expect(table.lookup(Sex.female, 61)!.s, 0.09);
    expect(table.lookup(Sex.male, 62), isNull);
  });

  test('feet and inches convert to centimetres', () {
    expect(feetInchesToCm(5, 4), closeTo(162.56, 0.001));
  });

  test('route args round-trip a measurement', () {
    final input = _input(132, 27.5, months: 112, sex: Sex.male);
    final back = BmiRouteArgs.fromQuery(BmiRouteArgs.toQuery(input))!;
    expect(back.heightCm, 132);
    expect(back.weightKg, 27.5);
    expect(back.ageMonths, 112);
    expect(back.sex, Sex.male);
    expect(BmiRouteArgs.fromQuery({'h': 'x'}), isNull);
  });

  group('helpers', () {
    test('parses Bangla digits', () {
      expect(parseLocalizedNumber('১৬৩'), 163);
      expect(parseLocalizedNumber('৫৭.৫'), 57.5);
      expect(parseLocalizedNumber('57,5'), 57.5);
      expect(parseLocalizedNumber(''), isNull);
    });

    test('version comparison', () {
      expect(isVersionBelow('1.0.0', '1.2.0'), isTrue);
      expect(isVersionBelow('1.10.0', '1.9.9'), isFalse);
      expect(isVersionBelow('1.2.0+5', '1.2.0'), isFalse);
      expect(compareVersions('2.0', '2.0.0'), 0);
    });

    test('operator detection from the number prefix', () {
      expect(
        MobileOperator.fromPhoneNumber('+880 1812-345678'),
        MobileOperator.robi,
      );
      expect(
        MobileOperator.fromPhoneNumber('01612345678'),
        MobileOperator.airtel,
      );
      expect(
        MobileOperator.fromPhoneNumber('+880 1712-345678'),
        MobileOperator.grameenphone,
      );
      expect(
        MobileOperator.fromPhoneNumber('০১৯১২৩৪৫৬৭৮'),
        MobileOperator.banglalink,
      );
      expect(MobileOperator.fromPhoneNumber('12345'), MobileOperator.unknown);
      expect(MobileOperator.robi.supportsPust9, isTrue);
      expect(MobileOperator.grameenphone.supportsPust9, isFalse);
    });
  });
}
