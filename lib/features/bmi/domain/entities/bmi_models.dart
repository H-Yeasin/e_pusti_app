enum Sex { female, male, other }

enum AdultBmiCategory { underweight, normal, overweight, obesity }

enum ChildBmiCategory { severeThinness, thinness, normal, overweight, obesity }

/// L, M, S parameters of the WHO 2007 BMI-for-age reference for one
/// sex and age in months.
class Lms {
  const Lms(this.l, this.m, this.s);

  final double l;
  final double m;
  final double s;
}

/// Source of BMI-for-age reference values (WHO 2007, 61–228 months).
abstract interface class BmiForAgeReference {
  Lms? lookup(Sex sex, int ageMonths);
}

class BmiInput {
  const BmiInput({
    required this.heightCm,
    required this.weightKg,
    this.ageMonths,
    this.sex,
    this.name,
  });

  final double heightCm;
  final double weightKg;

  /// Null when the age was not given (result case 5).
  final int? ageMonths;
  final Sex? sex;

  /// Person's name when known (logged-in family member); null when anonymous.
  final String? name;

  double get bmi {
    final metres = heightCm / 100;
    return weightKg / (metres * metres);
  }
}

/// The five result cases drawn in BMI-02, plus a guard for when the child
/// reference tables are not bundled.
sealed class BmiOutcome {
  const BmiOutcome(this.input);

  final BmiInput input;
}

/// Case 1 — adult 19+ on the WHO adult bands.
final class AdultBmiOutcome extends BmiOutcome {
  const AdultBmiOutcome(
    super.input, {
    required this.bmi,
    required this.category,
  });

  final double bmi;
  final AdultBmiCategory category;
}

/// Case 2 — age 5–19, BMI-for-age z-score against WHO 2007.
final class ChildBmiOutcome extends BmiOutcome {
  const ChildBmiOutcome(
    super.input, {
    required this.bmi,
    required this.zScore,
    required this.category,
  });

  final double bmi;
  final double zScore;
  final ChildBmiCategory category;
}

/// Case 3 — under 5: BMI is not used, no number is shown.
final class UnderFiveOutcome extends BmiOutcome {
  const UnderFiveOutcome(super.input);
}

/// Case 4 — under 19 with sex "other": no internationally recognised
/// reference exists, so no number is shown.
final class NoReferenceOutcome extends BmiOutcome {
  const NoReferenceOutcome(super.input);
}

/// Case 5 — no age given: computed on the adult standard, with a prompt to
/// add date of birth and sex.
final class NoAgeOutcome extends BmiOutcome {
  const NoAgeOutcome(super.input, {required this.bmi, required this.category});

  final double bmi;
  final AdultBmiCategory category;
}

/// Age 5–19 but the WHO 2007 tables are not available in this build.
/// Shows no classification rather than a wrong one.
final class ChildReferenceUnavailableOutcome extends BmiOutcome {
  const ChildReferenceUnavailableOutcome(super.input, {required this.bmi});

  final double bmi;
}
