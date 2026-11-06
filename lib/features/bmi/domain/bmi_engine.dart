import 'dart:math' as math;

import 'entities/bmi_models.dart';

/// Routes a measurement to one of the BMI-02 result cases.
///
/// Thresholds follow WHO: adult bands 18.5 / 25 / 30; BMI-for-age (WHO 2007)
/// thinness < −2 SD (severe < −3 SD), overweight > +1 SD, obesity > +2 SD.
/// Result copy is pending clinical sign-off (open items O-13 / O-17).
class BmiEngine {
  const BmiEngine(this.reference);

  /// Null when the WHO 2007 tables are not bundled.
  final BmiForAgeReference? reference;

  static const adultFromMonths = 19 * 12;
  static const childFromMonths = 5 * 12;

  /// WHO 2007 tables start at 5 years 1 month.
  static const _firstReferenceMonth = 61;

  BmiOutcome evaluate(BmiInput input) {
    final bmi = input.bmi;
    final age = input.ageMonths;

    if (age == null) {
      return NoAgeOutcome(input, bmi: bmi, category: adultCategory(bmi));
    }
    if (age >= adultFromMonths) {
      return AdultBmiOutcome(input, bmi: bmi, category: adultCategory(bmi));
    }
    if (age < childFromMonths) {
      return UnderFiveOutcome(input);
    }

    final sex = input.sex;
    if (sex == null || sex == Sex.other) {
      return NoReferenceOutcome(input);
    }

    final lms = reference?.lookup(sex, math.max(age, _firstReferenceMonth));
    if (lms == null) {
      return ChildReferenceUnavailableOutcome(input, bmi: bmi);
    }
    final z = zScore(bmi, lms);
    return ChildBmiOutcome(
      input,
      bmi: bmi,
      zScore: z,
      category: childCategory(z),
    );
  }

  static AdultBmiCategory adultCategory(double bmi) {
    if (bmi < 18.5) return AdultBmiCategory.underweight;
    if (bmi < 25) return AdultBmiCategory.normal;
    if (bmi < 30) return AdultBmiCategory.overweight;
    return AdultBmiCategory.obesity;
  }

  static ChildBmiCategory childCategory(double z) {
    if (z < -3) return ChildBmiCategory.severeThinness;
    if (z < -2) return ChildBmiCategory.thinness;
    if (z <= 1) return ChildBmiCategory.normal;
    if (z <= 2) return ChildBmiCategory.overweight;
    return ChildBmiCategory.obesity;
  }

  /// LMS z-score. Beyond ±3 SD the WHO restricted-tail adjustment changes
  /// the value but not the category, so it is not applied here.
  static double zScore(double bmi, Lms lms) {
    if (lms.l == 0) {
      return math.log(bmi / lms.m) / lms.s;
    }
    return (math.pow(bmi / lms.m, lms.l) - 1) / (lms.l * lms.s);
  }
}

/// Feet + inches → centimetres.
double feetInchesToCm(int feet, double inches) => (feet * 12 + inches) * 2.54;

/// Plausible input ranges; outside them the form asks the user to check.
abstract final class BmiLimits {
  static const minHeightCm = 40.0;
  static const maxHeightCm = 250.0;
  static const minWeightKg = 2.0;
  static const maxWeightKg = 300.0;
}
