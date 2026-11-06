import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../certificates/domain/certificate_models.dart';
import '../../digiskills/data/fixture_module_repository.dart';
import '../../digiskills/domain/module_models.dart';
import '../domain/learning_models.dart';
import 'fixture_assessments.dart';

/// Dev-backend learning data, per account, in shared preferences. Grading
/// mirrors the `submit_assessment` database function.
class LocalLearningBackend implements LearningBackend {
  LocalLearningBackend(
    this._prefs,
    this.accountId, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final String accountId;
  final DateTime Function() _clock;

  String get _progressKey => 'local_${accountId}_progress';
  String get _attemptsKey => 'local_${accountId}_attempts';

  /// Certificates are kept outside the account's keys so they survive
  /// account deletion and stay verifiable, like the real backend.
  static const certificateRegistryKey = 'local_certificate_registry';

  // ---- progress ----------------------------------------------------------

  @override
  Future<List<ItemProgress>> load() async {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return [];
    return [
      for (final row in jsonDecode(raw) as List<Object?>)
        ItemProgress.fromJson((row as Map).cast<String, Object?>()),
    ];
  }

  Future<void> _saveProgress(List<ItemProgress> items) => _prefs.setString(
    _progressKey,
    jsonEncode([for (final i in items) i.toJson()]),
  );

  @override
  Future<void> markStarted(LearningItemType type, String itemId) async {
    final items = await load();
    if (items.any((i) => i.type == type && i.itemId == itemId)) return;
    await _saveProgress([
      ...items,
      ItemProgress(
        type: type,
        itemId: itemId,
        status: ProgressStatus.inProgress,
      ),
    ]);
  }

  Future<void> _complete(
    LearningItemType type,
    String itemId,
    int score,
  ) async {
    final items = await load();
    final existing = items
        .where((i) => i.type == type && i.itemId == itemId)
        .firstOrNull;
    final best =
        existing?.scorePercent == null || existing!.scorePercent! < score
        ? score
        : existing.scorePercent!;
    await _saveProgress([
      ...items.where((i) => !(i.type == type && i.itemId == itemId)),
      ItemProgress(
        type: type,
        itemId: itemId,
        status: ProgressStatus.completed,
        scorePercent: best,
      ),
    ]);
  }

  // ---- assessments -------------------------------------------------------

  KeyedAssessment _keyed(String id) =>
      fixtureAssessments[id] ??
      (throw ArgumentError.value(id, 'assessmentId', 'Unknown assessment'));

  List<Map<String, Object?>> _attempts(String assessmentId) {
    final raw = _prefs.getString(_attemptsKey);
    if (raw == null) return [];
    final all = (jsonDecode(raw) as Map<String, Object?>);
    return [
      for (final row in (all[assessmentId] as List<Object?>? ?? const []))
        (row as Map).cast<String, Object?>(),
    ];
  }

  Future<void> _addAttempt(
    String assessmentId,
    Map<String, Object?> row,
  ) async {
    final raw = _prefs.getString(_attemptsKey);
    final all = raw == null
        ? <String, Object?>{}
        : (jsonDecode(raw) as Map<String, Object?>);
    all[assessmentId] = [..._attempts(assessmentId), row];
    await _prefs.setString(_attemptsKey, jsonEncode(all));
  }

  @override
  Future<Assessment> fetch(String assessmentId) async =>
      _keyed(assessmentId).assessment;

  @override
  Future<AttemptStatus> status(String assessmentId) async {
    final a = _keyed(assessmentId).assessment;
    final now = _clock();
    final attempts = _attempts(assessmentId);
    final recent =
        attempts
            .map((r) => DateTime.parse(r['at']! as String))
            .where((t) => now.difference(t) < a.cooldown)
            .toList()
          ..sort();
    final left = (a.maxAttempts - recent.length).clamp(0, a.maxAttempts);
    return AttemptStatus(
      attemptsLeft: left,
      passed: attempts.any((r) => r['passed'] == true),
      lockedUntil: left == 0 ? recent.first.add(a.cooldown) : null,
    );
  }

  @override
  Future<AssessmentResult> submit(
    String assessmentId,
    Map<String, int> answers, {
    required String holderName,
  }) async {
    final keyed = _keyed(assessmentId);
    final a = keyed.assessment;
    final before = await status(assessmentId);
    final now = _clock();
    if (before.isLocked(now)) {
      throw AttemptsExhaustedFailure(before.lockedUntil!);
    }
    if (a.issuesCertificate && holderName.trim().isEmpty) {
      throw const NameRequiredFailure();
    }

    final review = [
      for (final q in a.questions)
        ReviewItem(
          questionId: q.id,
          prompt: q.prompt,
          options: q.options,
          chosenIndex: answers[q.id],
          correctIndex: keyed.keys[q.id]!.correctIndex,
          explanation: keyed.keys[q.id]!.explanation,
        ),
    ];
    final correct = review.where((r) => r.isCorrect).length;
    final percent = (correct * 100 / a.questions.length).round();
    final passed = percent >= a.passMarkPercent;
    await _addAttempt(assessmentId, {
      'at': now.toIso8601String(),
      'passed': passed,
      'score': percent,
    });

    String? code;
    if (passed) {
      await _complete(a.itemType, a.itemId, percent);
      if (a.issuesCertificate) {
        code = await _issueCertificate(a, holderName.trim(), now);
      }
    }
    final after = await status(assessmentId);
    return AssessmentResult(
      assessmentId: assessmentId,
      correct: correct,
      total: a.questions.length,
      passMarkPercent: a.passMarkPercent,
      passed: passed,
      attemptsLeft: after.attemptsLeft,
      lockedUntil: after.lockedUntil,
      review: review,
      certificateCode: code,
    );
  }

  // ---- certificates ------------------------------------------------------

  List<Map<String, Object?>> _registry() {
    final raw = _prefs.getString(certificateRegistryKey);
    if (raw == null) return [];
    return [
      for (final row in jsonDecode(raw) as List<Object?>)
        (row as Map).cast<String, Object?>(),
    ];
  }

  Future<String> _issueCertificate(
    Assessment a,
    String holderName,
    DateTime now,
  ) async {
    final registry = _registry();
    final existing = registry
        .where((r) => r['account'] == accountId && r['assessment'] == a.id)
        .firstOrNull;
    if (existing != null) return existing['code']! as String;

    final source =
        FixtureModuleRepository.modules
            .where((m) => m.id == a.itemId)
            .firstOrNull
            ?.source
            .label ??
        '';
    final cert = Certificate(
      code: generateCertificateCode(now),
      holderName: holderName,
      title: a.title,
      sourceLabel: source,
      issuedAt: now,
    );
    registry.add({...cert.toJson(), 'account': accountId, 'assessment': a.id});
    await _prefs.setString(certificateRegistryKey, jsonEncode(registry));
    return cert.code;
  }

  @override
  Future<List<Certificate>> list() async => [
    for (final r in _registry())
      if (r['account'] == accountId) Certificate.fromJson(r),
  ]..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

  @override
  Future<Certificate?> byCode(String code) async {
    final row = _registry().where((r) => r['code'] == code).firstOrNull;
    return row == null ? null : Certificate.fromJson(row);
  }
}
