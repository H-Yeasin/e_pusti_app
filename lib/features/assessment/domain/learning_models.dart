import '../../certificates/domain/certificate_models.dart';

enum LearningItemType { chapter, module }

enum ProgressStatus { inProgress, completed }

class ItemProgress {
  const ItemProgress({
    required this.type,
    required this.itemId,
    required this.status,
    this.scorePercent,
  });

  final LearningItemType type;
  final String itemId;
  final ProgressStatus status;

  /// Best passing score for assessed items.
  final int? scorePercent;

  bool get isCompleted => status == ProgressStatus.completed;

  Map<String, Object?> toJson() => {
    'item_type': type.name,
    'item_id': itemId,
    'status': status.name,
    'score': scorePercent,
  };

  static ItemProgress fromJson(Map<String, Object?> json) => ItemProgress(
    type: LearningItemType.values.firstWhere(
      (t) => t.name == json['item_type'],
      orElse: () => LearningItemType.chapter,
    ),
    itemId: json['item_id'] as String,
    status: json['status'] == 'completed'
        ? ProgressStatus.completed
        : ProgressStatus.inProgress,
    scorePercent: (json['score'] as num?)?.toInt(),
  );
}

abstract interface class ProgressRepository {
  Future<List<ItemProgress>> load();

  /// Marks an item as started; never downgrades a completed item.
  Future<void> markStarted(LearningItemType type, String itemId);
}

/// A question as the app receives it — without the answer key.
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<String> options;
}

class Assessment {
  const Assessment({
    required this.id,
    required this.title,
    required this.questions,
    required this.passMarkPercent,
    required this.maxAttempts,
    required this.cooldown,
    required this.issuesCertificate,
    required this.itemType,
    required this.itemId,
  });

  final String id;
  final String title;
  final List<Question> questions;
  final int passMarkPercent;

  /// Attempts allowed before [cooldown] applies (decision A7: 3 / 24 h).
  final int maxAttempts;
  final Duration cooldown;
  final bool issuesCertificate;
  final LearningItemType itemType;
  final String itemId;
}

class AttemptStatus {
  const AttemptStatus({
    required this.attemptsLeft,
    required this.passed,
    this.lockedUntil,
  });

  final int attemptsLeft;
  final bool passed;

  /// Set when all attempts are used; a new round opens at this time.
  final DateTime? lockedUntil;

  bool isLocked(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);
}

class ReviewItem {
  const ReviewItem({
    required this.questionId,
    required this.prompt,
    required this.options,
    required this.chosenIndex,
    required this.correctIndex,
    required this.explanation,
  });

  final String questionId;
  final String prompt;
  final List<String> options;
  final int? chosenIndex;
  final int correctIndex;
  final String explanation;

  bool get isCorrect => chosenIndex == correctIndex;
}

class AssessmentResult {
  const AssessmentResult({
    required this.assessmentId,
    required this.correct,
    required this.total,
    required this.passMarkPercent,
    required this.passed,
    required this.attemptsLeft,
    required this.review,
    this.lockedUntil,
    this.certificateCode,
  });

  final String assessmentId;
  final int correct;
  final int total;
  final int passMarkPercent;
  final bool passed;
  final int attemptsLeft;
  final DateTime? lockedUntil;
  final List<ReviewItem> review;

  /// Issued on a pass of a certificate assessment.
  final String? certificateCode;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
}

/// Why an assessment couldn't be taken or submitted.
sealed class AssessmentFailure implements Exception {
  const AssessmentFailure();
}

/// All attempts used; wait until [until].
final class AttemptsExhaustedFailure extends AssessmentFailure {
  const AttemptsExhaustedFailure(this.until);

  final DateTime until;
}

/// A certificate needs the holder's name printed on it.
final class NameRequiredFailure extends AssessmentFailure {
  const NameRequiredFailure();
}

/// One engine for both learning tracks. Grading happens behind this
/// interface (server-side in production); the app never holds the key.
abstract interface class AssessmentRepository {
  Future<Assessment> fetch(String assessmentId);

  Future<AttemptStatus> status(String assessmentId);

  /// [answers]: question id → chosen option index.
  Future<AssessmentResult> submit(
    String assessmentId,
    Map<String, int> answers, {
    required String holderName,
  });
}

/// Everything account-scoped about learning, provided by one backend.
abstract interface class LearningBackend
    implements
        ProgressRepository,
        AssessmentRepository,
        CertificateRepository {}
