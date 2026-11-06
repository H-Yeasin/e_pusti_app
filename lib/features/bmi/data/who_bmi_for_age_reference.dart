import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/bmi_models.dart';

/// WHO 2007 BMI-for-age reference loaded from a bundled CSV with the header
/// `sex,month,L,M,S` (sex: 1 = boys, 2 = girls), one row per month 61–228.
///
/// The file must be taken unmodified from the WHO "expanded tables" — never
/// typed in by hand.
class WhoBmiForAgeReference implements BmiForAgeReference {
  WhoBmiForAgeReference._(this._rows);

  static const assetPath = 'assets/who/bmi_for_age_2007.csv';

  final Map<(Sex, int), Lms> _rows;

  int get rowCount => _rows.length;

  static WhoBmiForAgeReference parse(String csv) {
    final rows = <(Sex, int), Lms>{};
    for (final line in csv.split('\n').skip(1)) {
      final cells = line.trim().split(',');
      if (cells.length < 5) continue;
      final sex = switch (cells[0].trim()) {
        '1' => Sex.male,
        '2' => Sex.female,
        _ => null,
      };
      final month = int.tryParse(cells[1].trim());
      final l = double.tryParse(cells[2].trim());
      final m = double.tryParse(cells[3].trim());
      final s = double.tryParse(cells[4].trim());
      if (sex == null || month == null || l == null || m == null || s == null) {
        continue;
      }
      rows[(sex, month)] = Lms(l, m, s);
    }
    return WhoBmiForAgeReference._(rows);
  }

  @override
  Lms? lookup(Sex sex, int ageMonths) => _rows[(sex, ageMonths)];
}

/// Null when the table is not bundled; the engine then shows no child
/// classification instead of guessing.
final bmiForAgeReferenceProvider = FutureProvider<BmiForAgeReference?>((
  ref,
) async {
  try {
    // The provider caches the parsed table, so skip the bundle's own cache.
    final csv = await rootBundle.loadString(
      WhoBmiForAgeReference.assetPath,
      cache: false,
    );
    final table = WhoBmiForAgeReference.parse(csv);
    return table.rowCount == 0 ? null : table;
  } catch (_) {
    return null;
  }
});
