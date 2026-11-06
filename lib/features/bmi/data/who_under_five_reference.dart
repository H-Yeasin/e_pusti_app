import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/bmi_models.dart';

/// One WHO 2006 Child Growth Standards table from a bundled CSV with the
/// header `sex,<key>,L,M,S` (sex: 1 = boys, 2 = girls). The key is age in
/// days (0–1856) or length/height in cm with one decimal.
class LmsTable {
  LmsTable._(this._rows, this.minKey, this.maxKey);

  final Map<(Sex, int), Lms> _rows;

  /// Range of keys present, in table units (days, or tenths of a cm).
  final int minKey;
  final int maxKey;

  int get rowCount => _rows.length;

  /// [tenths]: true for length/height tables (keys stored as cm × 10).
  static LmsTable parse(String csv, {required bool tenths}) {
    final rows = <(Sex, int), Lms>{};
    var lo = 1 << 30, hi = -1;
    for (final line in csv.split('\n').skip(1)) {
      final c = line.trim().split(',');
      if (c.length < 5) continue;
      final sex = switch (c[0]) {
        '1' => Sex.male,
        '2' => Sex.female,
        _ => null,
      };
      final rawKey = double.tryParse(c[1]);
      final l = double.tryParse(c[2]);
      final m = double.tryParse(c[3]);
      final s = double.tryParse(c[4]);
      if (sex == null ||
          rawKey == null ||
          l == null ||
          m == null ||
          s == null) {
        continue;
      }
      final key = tenths ? (rawKey * 10).round() : rawKey.round();
      rows[(sex, key)] = Lms(l, m, s);
      if (key < lo) lo = key;
      if (key > hi) hi = key;
    }
    return LmsTable._(rows, lo, hi);
  }

  Lms? at(Sex sex, int key) => _rows[(sex, key)];

  /// Length/height lookup, rounded to the table's 0.1 cm steps.
  Lms? atCm(Sex sex, double cm) => _rows[(sex, (cm * 10).round())];
}

/// The four WHO 2006 indicators used for children under five.
class UnderFiveReference {
  const UnderFiveReference({
    required this.weightForAge,
    required this.lengthHeightForAge,
    required this.weightForLength,
    required this.weightForHeight,
  });

  static const assets = {
    'wfa': 'assets/who/wfa_2006.csv',
    'lhfa': 'assets/who/lhfa_2006.csv',
    'wfl': 'assets/who/wfl_2006.csv',
    'wfh': 'assets/who/wfh_2006.csv',
  };

  final LmsTable weightForAge;
  final LmsTable lengthHeightForAge;

  /// 45–110 cm, measured lying down (under 2 years).
  final LmsTable weightForLength;

  /// 65–120 cm, measured standing (2–5 years).
  final LmsTable weightForHeight;
}

/// Null when the tables are not bundled; the history then shows no chart.
final underFiveReferenceProvider = FutureProvider<UnderFiveReference?>((
  ref,
) async {
  try {
    // Bytes + utf8 instead of loadString: large assets would otherwise be
    // decoded in a background isolate. The provider caches the result, so
    // the bundle cache is skipped.
    Future<LmsTable> load(String key, {bool tenths = false}) async {
      final bytes = await rootBundle.load(UnderFiveReference.assets[key]!);
      return LmsTable.parse(
        utf8.decode(bytes.buffer.asUint8List()),
        tenths: tenths,
      );
    }

    final tables = await Future.wait([
      load('wfa'),
      load('lhfa'),
      load('wfl', tenths: true),
      load('wfh', tenths: true),
    ]);
    if (tables.any((t) => t.rowCount == 0)) return null;
    return UnderFiveReference(
      weightForAge: tables[0],
      lengthHeightForAge: tables[1],
      weightForLength: tables[2],
      weightForHeight: tables[3],
    );
  } catch (_) {
    return null;
  }
});
