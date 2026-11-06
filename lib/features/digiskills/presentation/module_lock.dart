import '../../assessment/domain/learning_models.dart';
import '../domain/module_models.dart';

/// A module's assessment opens once the previous module is completed.
/// Reading is never locked (soft gate).
bool isAssessmentLocked(
  SkillModuleSummary module,
  List<SkillModuleSummary> ordered,
  List<ItemProgress> progress,
) {
  final index = ordered.indexWhere((m) => m.id == module.id);
  if (index <= 0) return false;
  final previous = ordered[index - 1];
  return !progress.any(
    (p) =>
        p.type == LearningItemType.module &&
        p.itemId == previous.id &&
        p.isCompleted,
  );
}
