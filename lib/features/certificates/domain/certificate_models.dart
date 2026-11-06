import 'dart:math';

/// Name and title are snapshots taken at issue; the code is random, not
/// sequential; a revoked certificate stays visible as revoked.
class Certificate {
  const Certificate({
    required this.code,
    required this.holderName,
    required this.title,
    required this.sourceLabel,
    required this.issuedAt,
    this.revokedAt,
  });

  final String code;
  final String holderName;
  final String title;
  final String sourceLabel;
  final DateTime issuedAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  Map<String, Object?> toJson() => {
    'code': code,
    'holder_name': holderName,
    'title': title,
    'source': sourceLabel,
    'issued_at': issuedAt.toUtc().toIso8601String(),
    'revoked_at': revokedAt?.toUtc().toIso8601String(),
  };

  static Certificate fromJson(Map<String, Object?> json) => Certificate(
    code: json['code'] as String,
    holderName: json['holder_name'] as String,
    title: json['title'] as String,
    sourceLabel: (json['source'] as String?) ?? '',
    issuedAt: DateTime.parse(json['issued_at'] as String).toLocal(),
    revokedAt: json['revoked_at'] == null
        ? null
        : DateTime.parse(json['revoked_at'] as String).toLocal(),
  );
}

/// `EP-<year>-XXXXXXXX` with an alphabet that avoids look-alike characters
/// (no 0/O, 1/I/L), matching the database function.
String generateCertificateCode(DateTime issuedAt, {Random? random}) {
  const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  final r = random ?? Random.secure();
  final body = List.generate(
    8,
    (_) => alphabet[r.nextInt(alphabet.length)],
  ).join();
  return 'EP-${issuedAt.year}-$body';
}

abstract interface class CertificateRepository {
  Future<List<Certificate>> list();

  Future<Certificate?> byCode(String code);
}
