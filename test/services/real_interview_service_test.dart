import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offer_lab/models/chat_message.dart';
import 'package:offer_lab/models/feedback_result.dart';
import 'package:offer_lab/models/scenario.dart';
import 'package:offer_lab/services/interview_service.dart';
import 'package:offer_lab/services/real_interview_service.dart';

void main() {
  const scenario = Scenario(
    id: 'flutter-dev',
    title: 'Flutter 开发面试',
    subtitle: '测试场景',
    description: '测试描述',
    roleName: '面试官',
    roleTitle: '资深工程师',
    difficulty: ScenarioDifficulty.intermediate,
    tags: ['Flutter'],
    openingPrompt: '请先介绍一下你最近的项目。',
  );

  final history = <ChatMessage>[
    ChatMessage(
      id: 'assistant-opening',
      sender: ChatSender.assistant,
      content: '请先介绍一下你最近的项目。',
      timestamp: DateTime(2026, 7, 13, 12),
    ),
    ChatMessage(
      id: 'user-1',
      sender: ChatSender.user,
      content: '我最近负责了一个 Flutter 项目。',
      timestamp: DateTime(2026, 7, 13, 12, 1),
    ),
  ];

  test('returns ai reply when backend succeeds', () async {
    final service = RealInterviewService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'reply': '这是来自真实服务的回复',
            'score': 91,
            'summary': '总结',
            'strengths': ['亮点 1'],
            'improvements': ['改进 1'],
            'optimizedReply': '优化后的回答',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      retryBackoff: Duration.zero,
    );

    final reply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: history,
      userInput: '我最近负责了一个 Flutter 项目。',
      messageId: 'assistant-1',
    );

    expect(reply.content, '这是来自真实服务的回复');
  });

  test('retries retryable backend errors before succeeding', () async {
    var attempts = 0;
    final service = RealInterviewService(
      client: MockClient((request) async {
        attempts += 1;
        if (attempts < 3) {
          return http.Response(
            jsonEncode({'error': 'temporary failure'}),
            503,
            headers: const {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({
            'reply': '第三次成功',
            'score': 88,
            'summary': '总结',
            'strengths': ['亮点 1'],
            'improvements': ['改进 1'],
            'optimizedReply': '优化后的回答',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      retryBackoff: Duration.zero,
    );

    final reply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: history,
      userInput: '我最近负责了一个 Flutter 项目。',
      messageId: 'assistant-1',
    );

    expect(attempts, 3);
    expect(reply.content, '第三次成功');
  });

  test('falls back to local reply when retries are exhausted', () async {
    final service = RealInterviewService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'backend unavailable'}),
          503,
          headers: const {'content-type': 'application/json'},
        );
      }),
      fallbackService: _FakeInterviewService(),
      retryBackoff: Duration.zero,
    );

    final reply = await service.generateReply(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: history,
      userInput: '我最近负责了一个 Flutter 项目。',
      messageId: 'assistant-1',
    );

    expect(reply.content, startsWith('系统提示：真实 AI 服务暂时不可用'));
    expect(reply.content, contains('fallback reply'));
  });

  test('streamReply ignores start event and yields only text chunks', () async {
    final service = RealInterviewService(
      client: _SseClient('''
event: start
data: {}

data: {"text":"第一段"}

event: done
data: {}

'''),
      retryBackoff: Duration.zero,
    );

    final chunks = await service
        .streamReply(
          scenario: scenario,
          mode: InterviewMode.supportive,
          history: history,
          userInput: '我最近负责了一个 Flutter 项目。',
          messageId: 'assistant-1',
        )
        .toList();

    expect(chunks, ['第一段']);
  });

  test(
    'streamReply uses real non-stream reply when stream has no text',
    () async {
      final service = RealInterviewService(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/interview/stream')) {
            return http.Response(
              '''
event: start
data: {}

event: done
data: {}

''',
              200,
              headers: const {'content-type': 'text/event-stream'},
            );
          }

          return http.Response(
            jsonEncode({
              'reply': '真实非流式回复',
              'score': 86,
              'summary': '总结',
              'strengths': ['亮点 1'],
              'improvements': ['改进 1'],
              'optimizedReply': '优化后的回答',
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        fallbackService: _FakeInterviewService(),
        retryBackoff: Duration.zero,
      );

      final reply = await service
          .streamReply(
            scenario: scenario,
            mode: InterviewMode.supportive,
            history: history,
            userInput: '我最近负责了一个 Flutter 项目。',
            messageId: 'assistant-1',
          )
          .join();

      expect(reply, '真实非流式回复');
    },
  );

  test('streamReply uses local fallback when both real paths fail', () async {
    final service = RealInterviewService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/interview/stream')) {
          return http.Response(
            '''
event: start
data: {}

event: done
data: {}

''',
            200,
            headers: const {'content-type': 'text/event-stream'},
          );
        }

        return http.Response(
          jsonEncode({'error': 'backend unavailable'}),
          503,
          headers: const {'content-type': 'application/json'},
        );
      }),
      fallbackService: _FakeInterviewService(),
      retryBackoff: Duration.zero,
    );

    final reply = await service
        .streamReply(
          scenario: scenario,
          mode: InterviewMode.supportive,
          history: history,
          userInput: '我最近负责了一个 Flutter 项目。',
          messageId: 'assistant-1',
        )
        .join();

    expect(reply, startsWith('系统提示：真实 AI 服务暂时不可用'));
    expect(reply, contains('fallback reply'));
  });

  test('falls back to local feedback when backend keeps failing', () async {
    final service = RealInterviewService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'backend unavailable'}),
          503,
          headers: const {'content-type': 'application/json'},
        );
      }),
      fallbackService: _FakeInterviewService(),
      retryBackoff: Duration.zero,
    );

    final feedback = await service.buildFeedback(
      scenario: scenario,
      mode: InterviewMode.supportive,
      history: history,
    );

    expect(feedback.summary, startsWith('系统提示：真实 AI 服务暂时不可用'));
    expect(feedback.summary, contains('fallback summary'));
    expect(feedback.optimizedReply, 'fallback optimized reply');
  });
}

class _SseClient extends http.BaseClient {
  _SseClient(this.body);

  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode(body)]),
      200,
      headers: const {'content-type': 'text/event-stream'},
    );
  }
}

class _FakeInterviewService implements InterviewService {
  @override
  ChatMessage buildOpeningMessage({
    required Scenario scenario,
    required InterviewMode mode,
  }) {
    return ChatMessage(
      id: 'assistant-opening',
      sender: ChatSender.assistant,
      content: 'fallback opening',
      timestamp: DateTime(2026, 7, 13, 12),
    );
  }

  @override
  Future<FeedbackResult> buildFeedback({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
  }) async {
    return const FeedbackResult(
      overallScore: 80,
      summary: 'fallback summary',
      strengths: ['fallback strength'],
      improvements: ['fallback improvement'],
      optimizedReply: 'fallback optimized reply',
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
    return ChatMessage(
      id: messageId,
      sender: ChatSender.assistant,
      content: 'fallback reply',
      timestamp: DateTime(2026, 7, 13, 12, 2),
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
    yield (await generateReply(
      scenario: scenario,
      mode: mode,
      history: history,
      userInput: userInput,
      messageId: messageId,
    )).content;
  }
}
