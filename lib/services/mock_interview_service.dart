import '../models/chat_message.dart';
import '../models/feedback_result.dart';
import '../models/scenario.dart';
import 'interview_service.dart';

class MockInterviewService implements InterviewService {
  const MockInterviewService();

  static const Duration _streamTick = Duration(milliseconds: 18);
  static const int _streamChunkSize = 3;

  @override
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

  @override
  Future<ChatMessage> generateReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async {
    final userTurn = history
        .where((message) => message.sender == ChatSender.user)
        .length;

    return ChatMessage(
      id: messageId,
      sender: ChatSender.assistant,
      content: _buildReply(
        scenario: scenario,
        mode: mode,
        userInput: userInput,
        userTurn: userTurn,
      ),
      timestamp: DateTime.now(),
    );
  }

  @override
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

    final runes = reply.content.runes.toList();
    for (var index = 0; index < runes.length; index += _streamChunkSize) {
      final end = index + _streamChunkSize > runes.length
          ? runes.length
          : index + _streamChunkSize;
      yield String.fromCharCodes(runes.sublist(index, end));
      if (end < runes.length) {
        await Future<void>.delayed(_streamTick);
      }
    }
  }

  @override
  Future<FeedbackResult> buildFeedback({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
  }) async {
    final userMessages = history
        .where((message) => message.sender == ChatSender.user)
        .toList();
    final lastUserInput = userMessages.isEmpty
        ? '本轮回答'
        : userMessages.last.content;
    final score = _buildScore(
      mode: mode,
      userMessageCount: userMessages.length,
    );

    return FeedbackResult(
      overallScore: score,
      summary:
          '你在 ${scenario.title} 中完成了 ${userMessages.length} 轮表达，整体结构已经建立起来，但还可以把结果和细节讲得更扎实。',
      strengths: const ['回答没有明显跑题，能够围绕场景继续展开。', '表达节奏比较稳定，核心信息能被面试官快速听到。'],
      improvements: const [
        '把“做了什么”和“结果如何”拆开表达，避免内容混在一起。',
        '每轮回答都尽量补一个具体例子，让说服力更强。',
      ],
      optimizedReply:
          '如果让我重答这轮，我会这样说：围绕“$lastUserInput”，先交代背景，再说明我的动作，最后补充量化结果和复盘。',
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
    required int userTurn,
  }) {
    final shortenedInput = userInput.length > 24
        ? '${userInput.substring(0, 24)}...'
        : userInput;
    final turn = userTurn <= 1
        ? 1
        : userTurn == 2
        ? 2
        : 3;

    switch (mode) {
      case InterviewMode.supportive:
        return switch (turn) {
          1 =>
            '好的，我先帮你把这段回答拉具体一点。你提到“$shortenedInput”，HR 更想听到三件事：你负责什么、怎么做、结果如何。',
          2 => '这轮信息更完整了。接下来我会看稳定性和动机：你为什么离开上一段经历？下一份工作你最希望获得什么成长？',
          _ => '最后收一下岗位匹配度。如果我们给你这个机会，你入职前三个月准备优先做好哪两件事？请说得具体一点。',
        };
      case InterviewMode.pressure:
        return switch (turn) {
          1 => '我先追问一句：你刚才说到“$shortenedInput”，这里哪些是你独立负责的，哪些是团队结果？边界要说清楚。',
          2 => '如果我质疑这个结果不可验证，你能拿出什么数据、交付物或第三方反馈来支撑？不要只讲感受。',
          _ => '如果同样的问题下次再发生，你会提前做什么预防，而不是事后补救？我想听具体动作。',
        };
      case InterviewMode.deepDive:
        return switch (turn) {
          1 => '我们往下拆一下：你提到“$shortenedInput”，当时为什么选这个做法？有没有比较过其他方案？',
          2 => '这个过程中最难的判断是什么？你是怎么排优先级、协调资源，并确认方向没有跑偏的？',
          _ => '复盘来看，如果这段经历重做一次，你会保留什么、改掉什么？请给一个具体改进点。',
        };
    }
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
