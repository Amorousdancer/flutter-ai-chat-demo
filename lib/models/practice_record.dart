import 'scenario.dart';

class PracticeRecord {
  const PracticeRecord({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.mode,
    required this.completedAt,
    required this.score,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.optimizedReply,
    required this.highlightQuote,
  });

  factory PracticeRecord.fromJson(Map<String, dynamic> json) {
    return PracticeRecord(
      id: json['id'] as String? ?? '',
      scenarioId: json['scenarioId'] as String? ?? '',
      scenarioTitle: json['scenarioTitle'] as String? ?? '',
      mode: interviewModeFromName(json['mode'] as String? ?? ''),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      score: ((json['score'] as num?) ?? 0).round(),
      summary: json['summary'] as String? ?? '',
      strengths: _stringListFromJson(json['strengths']),
      improvements: _stringListFromJson(json['improvements']),
      optimizedReply: json['optimizedReply'] as String? ?? '',
      highlightQuote: json['highlightQuote'] as String? ?? '',
    );
  }

  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final InterviewMode mode;
  final DateTime completedAt;
  final int score;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final String optimizedReply;
  final String highlightQuote;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'scenarioTitle': scenarioTitle,
      'mode': mode.name,
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'summary': summary,
      'strengths': strengths,
      'improvements': improvements,
      'optimizedReply': optimizedReply,
      'highlightQuote': highlightQuote,
    };
  }

  static List<String> _stringListFromJson(Object? rawValue) {
    if (rawValue is! List<dynamic>) {
      return const [];
    }

    return rawValue.map((item) => item.toString()).toList();
  }
}
