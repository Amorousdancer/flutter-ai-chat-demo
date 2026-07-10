class FeedbackResult {
  const FeedbackResult({
    required this.overallScore,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.optimizedReply,
  });

  final int overallScore;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final String optimizedReply;
}
