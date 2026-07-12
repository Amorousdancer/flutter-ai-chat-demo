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
}
