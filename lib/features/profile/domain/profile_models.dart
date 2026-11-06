import '../../bmi/domain/entities/bmi_models.dart';

enum Relationship { holder, child, spouse, parent, sibling, other }

enum Occupation {
  student,
  privateEmployee,
  governmentEmployee,
  business,
  teacher,
  farmer,
  homemaker,
  other,
}

enum Interest {
  balancedDiet,
  pregnancyNutrition,
  weightManagement,
  childNutrition,
  diabetesManagement,
  generalHealth,
}

/// The account holder or a dependant. Date of birth and sex are collected
/// because age-correct BMI needs them.
class Person {
  const Person({
    required this.id,
    required this.relationship,
    this.name,
    this.dateOfBirth,
    this.sex,
    this.districtId,
    this.occupation,
    this.pregnant = false,
    this.breastfeeding = false,
    this.interests = const {},
  });

  final String id;
  final Relationship relationship;
  final String? name;
  final DateTime? dateOfBirth;
  final Sex? sex;
  final String? districtId;
  final Occupation? occupation;
  final bool pregnant;
  final bool breastfeeding;
  final Set<Interest> interests;

  bool get isHolder => relationship == Relationship.holder;

  /// Completed months of age at [at]; null without a date of birth.
  int? ageMonthsAt(DateTime at) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    var months = (at.year - dob.year) * 12 + at.month - dob.month;
    if (at.day < dob.day) months--;
    return months < 0 ? 0 : months;
  }

  Person copyWith({
    Relationship? relationship,
    String? name,
    DateTime? dateOfBirth,
    Sex? sex,
    String? districtId,
    Occupation? occupation,
    bool? pregnant,
    bool? breastfeeding,
    Set<Interest>? interests,
    bool clearName = false,
  }) {
    return Person(
      id: id,
      relationship: relationship ?? this.relationship,
      name: clearName ? null : (name ?? this.name),
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      districtId: districtId ?? this.districtId,
      occupation: occupation ?? this.occupation,
      pregnant: pregnant ?? this.pregnant,
      breastfeeding: breastfeeding ?? this.breastfeeding,
      interests: interests ?? this.interests,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'relationship': relationship.name,
    'name': name,
    'date_of_birth': dateOfBirth == null ? null : _date(dateOfBirth!),
    'sex': sex?.name,
    'district': districtId,
    'occupation': occupation?.name,
    'pregnant': pregnant,
    'breastfeeding': breastfeeding,
    'interests': [for (final i in interests) i.name],
  };

  static Person fromJson(Map<String, Object?> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) =>
        values.where((v) => v.name == name).firstOrNull;
    final interests = json['interests'];
    return Person(
      id: json['id'] as String,
      relationship:
          byName(Relationship.values, json['relationship']) ??
          Relationship.other,
      name: json['name'] as String?,
      dateOfBirth: DateTime.tryParse('${json['date_of_birth']}'),
      sex: byName(Sex.values, json['sex']),
      districtId: json['district'] as String?,
      occupation: byName(Occupation.values, json['occupation']),
      pregnant: json['pregnant'] == true,
      breastfeeding: json['breastfeeding'] == true,
      interests: interests is List
          ? {for (final i in interests) ?byName(Interest.values, i)}
          : const {},
    );
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class Measurement {
  const Measurement({
    required this.id,
    required this.personId,
    required this.measuredAt,
    required this.heightCm,
    required this.weightKg,
  });

  final String id;
  final String personId;
  final DateTime measuredAt;
  final double heightCm;
  final double weightKg;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  Map<String, Object?> toJson() => {
    'id': id,
    'person_id': personId,
    'measured_at': measuredAt.toUtc().toIso8601String(),
    'height_cm': heightCm,
    'weight_kg': weightKg,
  };

  static Measurement fromJson(Map<String, Object?> json) => Measurement(
    id: json['id'] as String,
    personId: json['person_id'] as String,
    measuredAt: DateTime.parse(json['measured_at'] as String).toLocal(),
    heightCm: (json['height_cm'] as num).toDouble(),
    weightKg: (json['weight_kg'] as num).toDouble(),
  );
}

class ConsentRecord {
  const ConsentRecord({this.termsAcceptedAt, this.healthDataAcceptedAt});

  static const none = ConsentRecord();

  final DateTime? termsAcceptedAt;
  final DateTime? healthDataAcceptedAt;

  bool get hasAnswered => termsAcceptedAt != null;
  bool get canStoreHealthData =>
      termsAcceptedAt != null && healthDataAcceptedAt != null;
}

abstract interface class ProfileRepository {
  Future<List<Person>> loadFamily();

  Future<void> savePerson(Person person);

  Future<void> deletePerson(String personId);
}

abstract interface class MeasurementRepository {
  Future<List<Measurement>> listFor(String personId);

  Future<void> save(Measurement measurement);

  Future<void> delete(String measurementId);

  /// Used when health-data consent is withdrawn.
  Future<void> deleteAll();
}

abstract interface class ConsentRepository {
  Future<ConsentRecord> load();

  Future<void> accept({required bool healthData});

  Future<void> withdrawHealthData();
}
