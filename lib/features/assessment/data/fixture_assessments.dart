import '../domain/learning_models.dart';

/// Answer key entry. Lives only in the grading side (dev backend here; the
/// `assessment_keys` table in Supabase, unreadable by clients).
class KeyedQuestion {
  const KeyedQuestion(
    this.question, {
    required this.correctIndex,
    required this.explanation,
  });

  final Question question;
  final int correctIndex;
  final String explanation;
}

class KeyedAssessment {
  const KeyedAssessment(this.assessment, this.keys);

  final Assessment assessment;
  final Map<String, KeyedQuestion> keys;
}

// Sample questions until BFSA-reviewed content is supplied. Q-safe, Q-2h and
// Q-shelf (with explanations) are from the ASM design; Q-wash and Q-fridge
// follow the WHO "Five Keys to Safer Food".
const _qSafe = KeyedQuestion(
  Question(
    id: 'q-safe',
    prompt: 'নিরাপদ খাদ্য বলতে কী বোঝায়?',
    options: [
      'শুধু টাটকা খাবার',
      'যে খাবার খেলে ক্ষতি হয় না',
      'দামি খাবার',
      'প্যাকেটজাত খাবার',
    ],
  ),
  correctIndex: 1,
  explanation:
      'টাটকা হলেই নিরাপদ নয় — দূষিত পানিতে ধোয়া টাটকা সবজিও অনিরাপদ হতে পারে।',
);

const _q2h = KeyedQuestion(
  Question(
    id: 'q-2h',
    prompt: 'রান্না করা খাবার ঘরের তাপমাত্রায় সর্বোচ্চ কত সময় রাখা নিরাপদ?',
    options: ['৬ ঘণ্টা', '২ ঘণ্টা', 'সারারাত', 'যতক্ষণ গন্ধ না বদলায়'],
  ),
  correctIndex: 1,
  explanation:
      'দুই ঘণ্টার বেশি রাখলে ব্যাকটেরিয়া দ্রুত বাড়ে। গরম আবহাওয়ায় এই সময় আরও কম।',
);

const _qShelf = KeyedQuestion(
  Question(
    id: 'q-shelf',
    prompt: 'কাঁচা মাংস ফ্রিজে কোথায় রাখা উচিত?',
    options: ['উপরের তাকে', 'নিচের তাকে', 'দরজার তাকে', 'সবজির সাথে'],
  ),
  correctIndex: 1,
  explanation:
      'নিচে রাখলে রস চুইয়ে অন্য খাবারে পড়ে না — ক্রস-কন্টামিনেশন এড়ানো যায়।',
);

const _qWash = KeyedQuestion(
  Question(
    id: 'q-wash',
    prompt: 'খাবার ধরার আগে সাবান দিয়ে অন্তত কত সময় হাত ঘষা উচিত?',
    options: ['৫ সেকেন্ড', '২০ সেকেন্ড', 'শুধু পানি দিলেই হয়', '২ মিনিট'],
  ),
  correctIndex: 1,
  explanation:
      'সাবান দিয়ে অন্তত ২০ সেকেন্ড ঘষলে হাতের বেশিরভাগ জীবাণু দূর হয়।',
);

const _qFridge = KeyedQuestion(
  Question(
    id: 'q-fridge',
    prompt: 'রান্না করা খাবার ফ্রিজে কত তাপমাত্রার নিচে রাখা উচিত?',
    options: ['৫°C', '১৫°C', '২৫°C', 'তাপমাত্রা গুরুত্বপূর্ণ নয়'],
  ),
  correctIndex: 0,
  explanation:
      '৫°C-এর নিচে জীবাণুর বৃদ্ধি অনেক ধীর হয়ে যায়, তাই খাবার বেশি সময় নিরাপদ থাকে।',
);

KeyedAssessment _build({
  required String id,
  required String title,
  required List<KeyedQuestion> questions,
  required bool issuesCertificate,
  required LearningItemType itemType,
  required String itemId,
}) => KeyedAssessment(
  Assessment(
    id: id,
    title: title,
    questions: [for (final q in questions) q.question],
    passMarkPercent: 70,
    maxAttempts: 3,
    cooldown: const Duration(hours: 24),
    issuesCertificate: issuesCertificate,
    itemType: itemType,
    itemId: itemId,
  ),
  {for (final q in questions) q.question.id: q},
);

final fixtureAssessments = <String, KeyedAssessment>{
  'a-m1': _build(
    id: 'a-m1',
    title: 'নিরাপদ খাদ্য: মৌলিক ধারণা',
    questions: const [_qSafe, _q2h, _qShelf, _qWash, _qFridge],
    issuesCertificate: true,
    itemType: LearningItemType.module,
    itemId: 'm1',
  ),
  'a-m2': _build(
    id: 'a-m2',
    title: 'খাদ্য সংরক্ষণ ও হাইজিন',
    questions: const [_qSafe, _q2h, _qShelf, _qWash, _qFridge],
    issuesCertificate: true,
    itemType: LearningItemType.module,
    itemId: 'm2',
  ),
  'a-c2': _build(
    id: 'a-c2',
    title: 'নিরাপদ খাদ্য ও অপচয়',
    questions: const [_q2h, _qWash, _qFridge],
    issuesCertificate: false,
    itemType: LearningItemType.chapter,
    itemId: 'c2',
  ),
};

/// Which academy chapters have a quiz.
const chapterAssessments = {'c2': 'a-c2'};
