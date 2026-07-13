enum ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum InterviewMode {
  supportive,
  pressure,
  deepDive,
}

extension ScenarioDifficultyLabel on ScenarioDifficulty {
  String get label {
    switch (this) {
      case ScenarioDifficulty.beginner:
        return '入门';
      case ScenarioDifficulty.intermediate:
        return '进阶';
      case ScenarioDifficulty.advanced:
        return '高压';
    }
  }
}

extension InterviewModeLabel on InterviewMode {
  String get label {
    switch (this) {
      case InterviewMode.supportive:
        return '友好模式';
      case InterviewMode.pressure:
        return '压力模式';
      case InterviewMode.deepDive:
        return '深挖模式';
    }
  }
}

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.roleName,
    required this.roleTitle,
    required this.difficulty,
    required this.tags,
    required this.openingPrompt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String roleName;
  final String roleTitle;
  final ScenarioDifficulty difficulty;
  final List<String> tags;
  final String openingPrompt;
}

InterviewMode interviewModeFromName(String rawValue) {
  return InterviewMode.values.firstWhere(
    (mode) => mode.name == rawValue,
    orElse: () => InterviewMode.supportive,
  );
}
