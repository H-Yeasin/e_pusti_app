import 'package:supabase_flutter/supabase_flutter.dart';

import '../../certificates/domain/certificate_models.dart';
import '../domain/learning_models.dart';

/// Supabase implementation. Grading runs in `submit_assessment()`; the
/// answer key table is unreadable by clients.
class SupabaseLearningBackend implements LearningBackend {
  SupabaseLearningBackend(this._client);

  final SupabaseClient _client;

  static LearningItemType _type(Object? v) =>
      v == 'module' ? LearningItemType.module : LearningItemType.chapter;

  @override
  Future<List<ItemProgress>> load() async {
    final rows = await _client.from('learning_progress').select();
    return [
      for (final r in rows)
        ItemProgress(
          type: _type(r['item_type']),
          itemId: r['item_id'] as String,
          status: r['status'] == 'completed'
              ? ProgressStatus.completed
              : ProgressStatus.inProgress,
          scorePercent: (r['score'] as num?)?.toInt(),
        ),
    ];
  }

  @override
  Future<void> markStarted(LearningItemType type, String itemId) async {
    await _client
        .from('learning_progress')
        .upsert(
          {'item_type': type.name, 'item_id': itemId, 'status': 'in_progress'},
          onConflict: 'account_id,item_type,item_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<Assessment> fetch(String assessmentId) async {
    final a = await _client
        .from('assessments')
        .select('*, assessment_questions(id, position, prompt, options)')
        .eq('id', assessmentId)
        .single();
    final questions = [
      for (final q in (a['assessment_questions'] as List<dynamic>))
        q as Map<String, dynamic>,
    ]..sort((x, y) => (x['position'] as int).compareTo(y['position'] as int));
    return Assessment(
      id: a['id'] as String,
      title: a['title'] as String,
      passMarkPercent: a['pass_mark'] as int,
      maxAttempts: a['max_attempts'] as int,
      cooldown: Duration(hours: a['cooldown_hours'] as int),
      issuesCertificate: a['issues_certificate'] as bool,
      itemType: _type(a['item_type']),
      itemId: a['item_id'] as String,
      questions: [
        for (final q in questions)
          Question(
            id: q['id'] as String,
            prompt: q['prompt'] as String,
            options: [for (final o in q['options'] as List<dynamic>) '$o'],
          ),
      ],
    );
  }

  static AttemptStatus _status(Map<String, dynamic> json) => AttemptStatus(
    attemptsLeft: (json['attempts_left'] as num).toInt(),
    passed: json['passed'] == true,
    lockedUntil: json['locked_until'] == null
        ? null
        : DateTime.parse(json['locked_until'] as String).toLocal(),
  );

  @override
  Future<AttemptStatus> status(String assessmentId) async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'assessment_status',
      params: {'p_assessment_id': assessmentId},
    );
    return _status(json);
  }

  @override
  Future<AssessmentResult> submit(
    String assessmentId,
    Map<String, int> answers, {
    required String holderName,
  }) async {
    final Map<String, dynamic> json;
    try {
      json = await _client.rpc<Map<String, dynamic>>(
        'submit_assessment',
        params: {
          'p_assessment_id': assessmentId,
          'p_answers': answers,
          'p_holder_name': holderName,
        },
      );
    } on PostgrestException catch (e) {
      final message = e.message;
      if (message.startsWith('attempts_exhausted:')) {
        throw AttemptsExhaustedFailure(
          DateTime.parse(message.split(':').skip(1).join(':')).toLocal(),
        );
      }
      if (message == 'name_required') throw const NameRequiredFailure();
      rethrow;
    }
    final status = _status(json);
    return AssessmentResult(
      assessmentId: assessmentId,
      correct: (json['correct'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      passMarkPercent: (json['pass_mark'] as num).toInt(),
      passed: json['passed'] == true,
      attemptsLeft: status.attemptsLeft,
      lockedUntil: status.lockedUntil,
      certificateCode: json['certificate_code'] as String?,
      review: [
        for (final r in json['review'] as List<dynamic>)
          ReviewItem(
            questionId: r['question_id'] as String,
            prompt: r['prompt'] as String,
            options: [for (final o in r['options'] as List<dynamic>) '$o'],
            chosenIndex: (r['chosen_index'] as num?)?.toInt(),
            correctIndex: (r['correct_index'] as num).toInt(),
            explanation: r['explanation'] as String,
          ),
      ],
    );
  }

  @override
  Future<List<Certificate>> list() async {
    final rows = await _client
        .from('certificates')
        .select('code, holder_name, title, source, issued_at, revoked_at')
        .order('issued_at', ascending: false);
    return [for (final r in rows) Certificate.fromJson(r)];
  }

  @override
  Future<Certificate?> byCode(String code) async {
    final row = await _client
        .from('certificates')
        .select('code, holder_name, title, source, issued_at, revoked_at')
        .eq('code', code)
        .maybeSingle();
    return row == null ? null : Certificate.fromJson(row);
  }
}
