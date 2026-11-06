/// Content partner that authored a module.
enum ContentSource { bfsa, unicef, iphn }

extension ContentSourceLabel on ContentSource {
  String get label => switch (this) {
    ContentSource.bfsa => 'BFSA',
    ContentSource.unicef => 'UNICEF',
    ContentSource.iphn => 'IPHN',
  };
}

class SkillModuleSummary {
  const SkillModuleSummary({
    required this.id,
    required this.order,
    required this.title,
    required this.source,
    required this.minutes,
    this.assessmentId,
    this.issuesCertificate = true,
  });

  final String id;
  final int order;
  final String title;
  final ContentSource source;
  final int minutes;

  /// Null while the module's assessment isn't published.
  final String? assessmentId;
  final bool issuesCertificate;

  Map<String, Object?> toJson() => {
    'id': id,
    'order': order,
    'title': title,
    'source': source.name,
    'minutes': minutes,
    'assessment_id': assessmentId,
    'issues_certificate': issuesCertificate,
  };

  static SkillModuleSummary fromJson(Map<String, Object?> json) =>
      SkillModuleSummary(
        id: json['id'] as String,
        order: (json['order'] as num).toInt(),
        title: json['title'] as String,
        source: ContentSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => ContentSource.bfsa,
        ),
        minutes: (json['minutes'] as num).toInt(),
        assessmentId: json['assessment_id'] as String?,
        issuesCertificate: json['issues_certificate'] != false,
      );
}

class SkillModule {
  const SkillModule({required this.summary, required this.paragraphs});

  final SkillModuleSummary summary;
  final List<String> paragraphs;
}

/// Module content is served from the VPS (not Supabase), so it can be
/// unreachable while progress is safe.
abstract interface class ModuleRepository {
  Future<List<SkillModuleSummary>> fetchModules();

  Future<SkillModule> fetchModule(String id);
}
