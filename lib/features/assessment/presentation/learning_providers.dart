import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/config/backend_config.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../certificates/domain/certificate_models.dart';
import '../../digiskills/data/fixture_module_repository.dart';
import '../../digiskills/domain/module_models.dart';
import '../data/local_learning_backend.dart';
import '../data/supabase_learning_backend.dart';
import '../domain/learning_models.dart';

/// Account-scoped learning backend; null while logged out.
final learningBackendProvider = Provider<LearningBackend?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabaseLearningBackend(Supabase.instance.client),
    BackendKind.local => LocalLearningBackend(
      ref.watch(sharedPreferencesProvider),
      userId,
    ),
    BackendKind.none => null,
  };
});

// ---- Digi Skills content (VPS) -------------------------------------------

final moduleRepositoryProvider = Provider<ModuleRepository>(
  (ref) => CachingModuleRepository(
    const FixtureModuleRepository(),
    ref.watch(sharedPreferencesProvider),
  ),
);

class ModuleList {
  const ModuleList(this.modules, {required this.fromCache});

  final List<SkillModuleSummary> modules;

  /// The content server was unreachable; this is the last known list.
  final bool fromCache;
}

final modulesProvider = FutureProvider<ModuleList>((ref) async {
  final repo = ref.watch(moduleRepositoryProvider);
  final modules = await repo.fetchModules();
  return ModuleList(
    [...modules]..sort((a, b) => a.order.compareTo(b.order)),
    fromCache: repo is CachingModuleRepository && repo.servedFromCache,
  );
});

final moduleProvider = FutureProvider.family<SkillModule, String>(
  (ref, id) => ref.watch(moduleRepositoryProvider).fetchModule(id),
);

// ---- progress --------------------------------------------------------------

class ProgressController extends AsyncNotifier<List<ItemProgress>> {
  @override
  Future<List<ItemProgress>> build() async {
    final backend = ref.watch(learningBackendProvider);
    if (backend == null) return const [];
    return backend.load();
  }

  Future<void> markStarted(LearningItemType type, String itemId) async {
    final backend = ref.read(learningBackendProvider);
    if (backend == null) return;
    final current = state.value ?? const [];
    if (current.any((p) => p.type == type && p.itemId == itemId)) return;
    await backend.markStarted(type, itemId);
    ref.invalidateSelf();
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressController, List<ItemProgress>>(
      ProgressController.new,
    );

ItemProgress? progressFor(
  List<ItemProgress> all,
  LearningItemType type,
  String id,
) => all.where((p) => p.type == type && p.itemId == id).firstOrNull;

// ---- assessments -----------------------------------------------------------

final assessmentProvider = FutureProvider.family<Assessment, String>((
  ref,
  id,
) async {
  final backend = ref.watch(learningBackendProvider);
  if (backend == null) throw StateError('not signed in');
  return backend.fetch(id);
});

final attemptStatusProvider = FutureProvider.family<AttemptStatus, String>((
  ref,
  id,
) async {
  final backend = ref.watch(learningBackendProvider);
  if (backend == null) throw StateError('not signed in');
  return backend.status(id);
});

// ---- certificates ----------------------------------------------------------

final certificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  final backend = ref.watch(learningBackendProvider);
  if (backend == null) return const [];
  return backend.list();
});

final certificateProvider = FutureProvider.family<Certificate?, String>((
  ref,
  code,
) async {
  final backend = ref.watch(learningBackendProvider);
  if (backend == null) return null;
  return backend.byCode(code);
});

// ---- answer drafts ---------------------------------------------------------

class AssessmentDraft {
  const AssessmentDraft({required this.answers, required this.index});

  final Map<String, int> answers;
  final int index;
}

/// Keeps answers on the device so leaving (or losing the connection on
/// submit) never loses them (ASM-01 exit confirm).
class AssessmentDraftStore {
  AssessmentDraftStore(this._prefs, this._accountId);

  final SharedPreferences _prefs;
  final String _accountId;

  String _key(String assessmentId) => 'local_${_accountId}_draft_$assessmentId';

  AssessmentDraft? read(String assessmentId) {
    final raw = _prefs.getString(_key(assessmentId));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, Object?>;
    return AssessmentDraft(
      answers: (json['answers'] as Map).map(
        (k, v) => MapEntry('$k', (v as num).toInt()),
      ),
      index: (json['index'] as num).toInt(),
    );
  }

  Future<void> save(String assessmentId, AssessmentDraft draft) =>
      _prefs.setString(
        _key(assessmentId),
        jsonEncode({'answers': draft.answers, 'index': draft.index}),
      );

  Future<void> clear(String assessmentId) => _prefs.remove(_key(assessmentId));
}

final assessmentDraftStoreProvider = Provider<AssessmentDraftStore?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return AssessmentDraftStore(ref.watch(sharedPreferencesProvider), userId);
});
