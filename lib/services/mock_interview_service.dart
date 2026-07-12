import '../models/feedback_result.dart';
import '../models/chat_message.dart';
import '../models/scenario.dart';

class MockInterviewService {
  const MockInterviewService({
    this.responseDelay = const Duration(milliseconds: 800),
  });

  final Duration responseDelay;

  ChatMessage buildOpeningMessage({
    required Scenario scenario,
    required InterviewMode mode,
  }) {
    return ChatMessage(
      id: 'assistant-opening',
      sender: ChatSender.assistant,
      content: '${_modeLead(mode)}${scenario.openingPrompt}',
      timestamp: DateTime.now(),
    );
  }

  Future<ChatMessage> generateReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async {
    await Future<void>.delayed(responseDelay);

    return ChatMessage(
      id: messageId,
      sender: ChatSender.assistant,
      content: _buildReply(
        scenario: scenario,
        mode: mode,
        userInput: userInput,
        historyCount: history.length,
      ),
      timestamp: DateTime.now(),
    );
  }

  String _modeLead(InterviewMode mode) {
    switch (mode) {
      case InterviewMode.supportive:
        return '我们先轻松热身一下。';
      case InterviewMode.pressure:
        return '我会用更直接的方式追问你。';
      case InterviewMode.deepDive:
        return '这轮我会重点深挖细节。';
    }
  }

  String _buildReply({
    required Scenario scenario,
    required InterviewMode mode,
    required String userInput,
    required int historyCount,
  }) {
    final shortenedInput = userInput.length > 24
        ? '${userInput.substring(0, 24)}...'
        : userInput;

    switch (mode) {
      case InterviewMode.supportive:
        return '你的回答方向是对的。我听到你提到了“$shortenedInput”。如果继续完善，我想请你结合 ${scenario.title} 再补一个更具体的例子。';
      case InterviewMode.pressure:
        return '这个回答还不够有说服力。你刚才提到“$shortenedInput”，但我还没听到明确结果。请直接告诉我你做了什么，以及结果如何。';
      case InterviewMode.deepDive:
        return '我想继续往下追问。你刚才说到“$shortenedInput”，那第 ${historyCount ~/ 2 + 1} 个关键决策是怎么做出来的？如果重来一次你会怎么优化？';
    }
  }

  FeedbackResult buildFeedback({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
  }) {
    final userMessages = history
        .where((message) => message.sender == ChatSender.user)
        .toList();
    final lastUserInput = userMessages.isEmpty ? '本轮回答' : userMessages.last.content;
    final score = _buildScore(mode: mode, userMessageCount: userMessages.length);

    return FeedbackResult(
      overallScore: score,
      summary: '你在 ${scenario.title} 中完成了 ${userMessages.length} 轮表达，整体结构已经建立起来，但还可以把结果和细节讲得更扎实。',
      strengths: [
        '回答没有明显跑题，能够围绕场景继续展开。',
        '表达节奏比较稳定，核心信息能被面试官快速听到。',
      ],
      improvements: [
        '把“做了什么”和“结果如何”拆开表达，避免内容混在一起。',
        '每轮回答都尽量补一个具体例子，让说服力更强。',
      ],
      optimizedReply: '如果让我重答这轮，我会这样说：围绕“$lastUserInput”，先交代背景，再说明我的动作，最后补充量化结果和复盘。',
    );
  }

  int _buildScore({
    required InterviewMode mode,
    required int userMessageCount,
  }) {
    final baseScore = switch (mode) {
      InterviewMode.supportive => 84,
      InterviewMode.pressure => 78,
      InterviewMode.deepDive => 80,
    };

    final bonus = userMessageCount.clamp(0, 4);
    return (baseScore + bonus).clamp(0, 100);
  }
}
