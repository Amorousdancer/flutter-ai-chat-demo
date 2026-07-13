import 'package:flutter_test/flutter_test.dart';
import 'package:offer_lab/models/chat_message.dart';
import 'package:offer_lab/models/scenario.dart';
import 'package:offer_lab/services/mock_interview_service.dart';

void main() {
  const scenario = Scenario(
    id: 'flutter-dev',
    title: 'Flutter 开发面试',
    subtitle: '围绕项目实战',
    description: '测试 mock 面试官追问',
    roleName: '林老师',
    roleTitle: '招聘负责人',
    difficulty: ScenarioDifficulty.intermediate,
    tags: ['Flutter'],
    openingPrompt: '先做一个简单自我介绍。',
  );

  test('varies reply by turn and mode', () async {
    const service = MockInterviewService();
    final opening = service.buildOpeningMessage(
      scenario: scenario,
      mode: InterviewMode.supportive,
    );

    final firstReply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: [opening, _userMessage('我最近负责 Flutter 项目重构。')],
      userInput: '我最近负责 Flutter 项目重构。',
      messageId: 'assistant-1',
    );

    final secondReply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: [
        opening,
        _userMessage('我最近负责 Flutter 项目重构。'),
        firstReply,
        _userMessage('我把状态管理和性能优化一起做了。'),
      ],
      userInput: '我把状态管理和性能优化一起做了。',
      messageId: 'assistant-2',
    );

    final thirdReply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: [
        opening,
        _userMessage('我最近负责 Flutter 项目重构。'),
        firstReply,
        _userMessage('我把状态管理和性能优化一起做了。'),
        secondReply,
        _userMessage('我希望下一份工作能继续做核心模块。'),
      ],
      userInput: '我希望下一份工作能继续做核心模块。',
      messageId: 'assistant-3',
    );

    expect(firstReply.content, contains('三件事'));
    expect(secondReply.content, contains('成长'));
    expect(thirdReply.content, contains('前三个月'));
    expect(firstReply.content, isNot(equals(secondReply.content)));
    expect(secondReply.content, isNot(equals(thirdReply.content)));
  });
}

ChatMessage _userMessage(String content) {
  return ChatMessage(
    id: 'user-${content.hashCode}',
    sender: ChatSender.user,
    content: content,
    timestamp: DateTime(2026, 7, 13, 12),
  );
}
