import '../models/chat_message.dart';
import '../models/feedback_result.dart';
import '../models/scenario.dart';

abstract class InterviewService {
  const InterviewService();

  ChatMessage buildOpeningMessage({
    required Scenario scenario,
    required InterviewMode mode,
  });

  Future<ChatMessage> generateReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  });

  Stream<String> streamReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async* {
    final reply = await generateReply(
      scenario: scenario,
      mode: mode,
      history: history,
      userInput: userInput,
      messageId: messageId,
    );
    yield reply.content;
  }

  Future<FeedbackResult> buildFeedback({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
  });
}
