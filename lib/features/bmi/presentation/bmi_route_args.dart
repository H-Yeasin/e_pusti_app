import '../domain/entities/bmi_models.dart';

/// Encodes a measurement in the result route's query so the result can be
/// rebuilt after login ("you'll return where you were").
abstract final class BmiRouteArgs {
  static Map<String, String> toQuery(BmiInput input, {String? personId}) => {
    'p': ?personId,
    'h': input.heightCm.toStringAsFixed(1),
    'w': input.weightKg.toStringAsFixed(1),
    if (input.ageMonths != null) 'a': '${input.ageMonths}',
    if (input.sex != null) 's': input.sex!.name,
  };

  static String? personIdFrom(Map<String, String> query) => query['p'];

  static BmiInput? fromQuery(Map<String, String> query) {
    final height = double.tryParse(query['h'] ?? '');
    final weight = double.tryParse(query['w'] ?? '');
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return null;
    }
    final age = int.tryParse(query['a'] ?? '');
    Sex? sex;
    for (final value in Sex.values) {
      if (value.name == query['s']) {
        sex = value;
      }
    }
    return BmiInput(
      heightCm: height,
      weightKg: weight,
      ageMonths: age != null && age >= 0 ? age : null,
      sex: sex,
    );
  }
}
