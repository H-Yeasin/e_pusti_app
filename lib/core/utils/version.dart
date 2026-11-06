/// Compares dotted versions such as `1.2.0` and `1.10.3`.
/// Build suffixes (`+12`) and pre-release tags (`-beta`) are ignored.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();

  final left = parts(a);
  final right = parts(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) {
      return l.compareTo(r);
    }
  }
  return 0;
}

bool isVersionBelow(String version, String minimum) =>
    compareVersions(version, minimum) < 0;
