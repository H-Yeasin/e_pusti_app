import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/module_models.dart';

/// Sample Digi Skills catalogue from DGS-01 / DGS-02 until the VPS content
/// API exists. Module 2's text is from the design; the others carry a
/// placeholder line rather than invented content.
class FixtureModuleRepository implements ModuleRepository {
  const FixtureModuleRepository();

  static const _placeholder =
      'নমুনা কনটেন্ট — চূড়ান্ত মডিউলের লেখা কনটেন্ট সার্ভার থেকে আসবে।';

  static const modules = [
    SkillModuleSummary(
      id: 'm1',
      order: 1,
      title: 'নিরাপদ খাদ্য: মৌলিক ধারণা',
      source: ContentSource.bfsa,
      minutes: 15,
      assessmentId: 'a-m1',
    ),
    SkillModuleSummary(
      id: 'm2',
      order: 2,
      title: 'খাদ্য সংরক্ষণ ও হাইজিন',
      source: ContentSource.bfsa,
      minutes: 22,
      assessmentId: 'a-m2',
    ),
    SkillModuleSummary(
      id: 'm3',
      order: 3,
      title: 'শিশু পুষ্টি ও স্তন্যপান চর্চা',
      source: ContentSource.unicef,
      minutes: 18,
    ),
    SkillModuleSummary(
      id: 'm4',
      order: 4,
      title: 'কৈশোরকালীন পুষ্টি নির্দেশিকা',
      source: ContentSource.iphn,
      minutes: 20,
    ),
  ];

  @override
  Future<List<SkillModuleSummary>> fetchModules() async => modules;

  @override
  Future<SkillModule> fetchModule(String id) async {
    final summary = modules.firstWhere(
      (m) => m.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown module'),
    );
    if (id == 'm2') {
      return SkillModule(
        summary: summary,
        paragraphs: const [
          'খাদ্য সংরক্ষণের সঠিক পদ্ধতি না জানলে পুষ্টিগুণ নষ্ট হয় এবং খাদ্য অনিরাপদ হয়ে পড়ে। এই মডিউলে তাপমাত্রা নিয়ন্ত্রণ, পরিচ্ছন্নতা ও ক্রস-কন্টামিনেশন প্রতিরোধ নিয়ে আলোচনা করা হয়েছে।',
          'রান্না করা ও কাঁচা খাবার আলাদা রাখা কেন জরুরি — কাঁচা মাংস বা মাছ থেকে জীবাণু...',
          _placeholder,
        ],
      );
    }
    return SkillModule(summary: summary, paragraphs: const [_placeholder]);
  }
}

/// Keeps the last module list so DGS-01 still renders (with progress) when
/// the content server is unreachable.
class CachingModuleRepository implements ModuleRepository {
  CachingModuleRepository(this._inner, this._prefs);

  static const _key = 'digiskills_module_cache';

  final ModuleRepository _inner;
  final SharedPreferences _prefs;

  /// True when the last [fetchModules] answered from the cache.
  bool servedFromCache = false;

  @override
  Future<List<SkillModuleSummary>> fetchModules() async {
    try {
      final modules = await _inner.fetchModules();
      servedFromCache = false;
      await _prefs.setString(
        _key,
        jsonEncode([for (final m in modules) m.toJson()]),
      );
      return modules;
    } on ContentServerUnavailableFailure {
      final raw = _prefs.getString(_key);
      if (raw == null) rethrow;
      servedFromCache = true;
      return [
        for (final row in jsonDecode(raw) as List<Object?>)
          SkillModuleSummary.fromJson((row as Map).cast<String, Object?>()),
      ];
    }
  }

  @override
  Future<SkillModule> fetchModule(String id) => _inner.fetchModule(id);
}
