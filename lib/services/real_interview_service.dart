import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/feedback_result.dart';
import '../models/scenario.dart';
import 'interview_service.dart';
import 'mock_interview_service.dart';
import 'sensitive_data_sanitizer.dart';

const String _defaultOfferLabApiBaseUrl = String.fromEnvironment(
  'OFFERLAB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

class RealInterviewService implements InterviewService {
  static const Duration _bufferedStreamTick = Duration(milliseconds: 18);
  static const int _bufferedStreamChunkSize = 3;

  RealInterviewService({
    String? apiBaseUrl,
    http.Client? client,
    SensitiveDataSanitizer? sanitizer,
    InterviewService? fallbackService,
    this.maxAttempts = 3,
    this.requestTimeout = const Duration(seconds: 30),
    this.retryBackoff = const Duration(milliseconds: 600),
  }) : _apiBaseUrl = apiBaseUrl ?? _defaultOfferLabApiBaseUrl,
       _client = client ?? http.Client(),
       _sanitizer = sanitizer ?? const SensitiveDataSanitizer(),
       _fallbackService = fallbackService ?? const MockInterviewService();

  final String _apiBaseUrl;
  final http.Client _client;
  final SensitiveDataSanitizer _sanitizer;
  final InterviewService _fallbackService;
  final int maxAttempts;
  final Duration requestTimeout;
  final Duration retryBackoff;

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
    try {
      final payload = await _requestEvaluation(
        scenario: scenario,
        mode: mode,
        history: history,
        userInput: userInput,
        purpose: 'reply',
      );

      return ChatMessage(
        id: messageId,
        sender: ChatSender.assistant,
        content: payload.reply,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      final fallbackReply = await _fallbackService.generateReply(
        scenario: scenario,
        mode: mode,
        history: history,
        userInput: userInput,
        messageId: messageId,
      );

      return ChatMessage(
        id: fallbackReply.id,
        sender: fallbackReply.sender,
        content: '系统提示：真实 AI 服务暂时不可用，已自动切换到本地模拟。\n\n${fallbackReply.content}',
        timestamp: fallbackReply.timestamp,
      );
    }
  }

  @override
  Stream<String> streamReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async* {
    try {
      final chunks = _streamReplyChunks(
        scenario: scenario,
        mode: mode,
        history: history,
        userInput: userInput,
        messageId: messageId,
      );
      await for (final chunk in chunks) {
        yield chunk;
      }
    } catch (_) {
      try {
        final payload = await _requestEvaluation(
          scenario: scenario,
          mode: mode,
          history: history,
          userInput: userInput,
          purpose: 'reply',
        );
        yield* _streamBufferedText(payload.reply);
      } catch (_) {
        yield '系统提示：真实 AI 服务暂时不可用，已自动切换到本地模拟。\n\n';
        yield* _fallbackService.streamReply(
          scenario: scenario,
          mode: mode,
          history: history,
          userInput: userInput,
          messageId: messageId,
        );
      }
    }
  }

  @override
  Future<FeedbackResult> buildFeedback({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
  }) async {
    final lastUserInput = _findLastUserInput(history);

    try {
      final payload = await _requestEvaluation(
        scenario: scenario,
        mode: mode,
        history: history,
        userInput: lastUserInput,
        purpose: 'feedback',
      );

      return FeedbackResult(
        overallScore: payload.score,
        summary: payload.summary,
        strengths: payload.strengths,
        improvements: payload.improvements,
        optimizedReply: payload.optimizedReply,
      );
    } catch (_) {
      final fallbackFeedback = await _fallbackService.buildFeedback(
        scenario: scenario,
        mode: mode,
        history: history,
      );

      return FeedbackResult(
        overallScore: fallbackFeedback.overallScore,
        summary:
            '系统提示：真实 AI 服务暂时不可用，以下反馈来自本地模拟。\n\n${fallbackFeedback.summary}',
        strengths: fallbackFeedback.strengths,
        improvements: fallbackFeedback.improvements,
        optimizedReply: fallbackFeedback.optimizedReply,
      );
    }
  }

  Future<_InterviewResponsePayload> _requestEvaluation({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String purpose,
  }) async {
    _InterviewRequestException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        return await _requestEvaluationOnce(
          scenario: scenario,
          mode: mode,
          history: history,
          userInput: userInput,
          purpose: purpose,
        );
      } on _InterviewRequestException catch (error) {
        lastError = error;
        if (!error.retryable || attempt == maxAttempts) {
          break;
        }

        await Future<void>.delayed(_retryDelay(attempt));
      }
    }

    throw Exception(lastError?.message ?? 'AI 服务暂时不可用');
  }

  Stream<String> _streamReplyChunks({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async* {
    final endpoint = Uri.parse('$_apiBaseUrl/api/interview/stream');
    final request = http.Request('POST', endpoint)
      ..headers.addAll(const {'Content-Type': 'application/json'})
      ..body = jsonEncode(
        _buildRequestBody(
          scenario: scenario,
          mode: mode,
          history: history,
          userInput: userInput,
          purpose: 'reply',
        ),
      );

    final streamedResponse = await _client
        .send(request)
        .timeout(requestTimeout);

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final errorText = await utf8.decoder.bind(streamedResponse.stream).join();
      throw _InterviewRequestException(
        errorText.isEmpty ? 'AI 服务暂时不可用' : errorText,
        retryable: _isRetryableStatus(streamedResponse.statusCode),
      );
    }

    var hasChunk = false;
    String? currentEvent;
    final dataLines = <String>[];
    String? pendingChunk;

    void flushEvent() {
      if (dataLines.isEmpty) {
        currentEvent = null;
        return;
      }

      final payloadText = dataLines.join('\n');
      dataLines.clear();

      if (currentEvent == 'done' || currentEvent == 'start') {
        currentEvent = null;
        return;
      }

      final decoded = _tryDecodeJson(payloadText);
      if (decoded is Map<String, dynamic>) {
        final chunk = decoded['text']?.toString() ?? '';
        if (chunk.isNotEmpty) {
          hasChunk = true;
          pendingChunk = chunk;
        }
      }

      currentEvent = null;
    }

    await for (final line
        in utf8.decoder
            .bind(streamedResponse.stream)
            .transform(const LineSplitter())) {
      if (line.startsWith('event:')) {
        flushEvent();
        if (pendingChunk != null) {
          yield pendingChunk!;
          pendingChunk = null;
        }
        currentEvent = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
        continue;
      }

      if (line.isEmpty) {
        flushEvent();
        if (pendingChunk != null) {
          yield pendingChunk!;
          pendingChunk = null;
        }
      }
    }

    flushEvent();
    if (pendingChunk != null) {
      yield pendingChunk!;
    }

    if (!hasChunk) {
      throw const _InterviewRequestException('AI 服务返回内容为空', retryable: false);
    }
  }

  Future<_InterviewResponsePayload> _requestEvaluationOnce({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String purpose,
  }) async {
    final endpoint = Uri.parse('$_apiBaseUrl/api/interview');

    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
              _buildRequestBody(
                scenario: scenario,
                mode: mode,
                history: history,
                userInput: userInput,
                purpose: purpose,
              ),
            ),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const _InterviewRequestException('AI 服务响应超时', retryable: true);
    } on http.ClientException {
      throw const _InterviewRequestException('无法连接 AI 服务', retryable: true);
    }

    final decodedBody = _tryDecodeJson(response.body);
    if (response.statusCode != 200) {
      final message = decodedBody is Map<String, dynamic>
          ? decodedBody['error'] as String? ?? 'AI 服务暂时不可用'
          : 'AI 服务暂时不可用';
      throw _InterviewRequestException(
        message,
        retryable: _isRetryableStatus(response.statusCode),
      );
    }
    if (decodedBody is! Map<String, dynamic>) {
      throw const _InterviewRequestException('AI 服务返回格式不正确', retryable: false);
    }

    return _InterviewResponsePayload.fromJson(decodedBody);
  }

  Map<String, dynamic> _buildRequestBody({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String purpose,
  }) {
    return {
      'purpose': purpose,
      'scenario': {
        'id': scenario.id,
        'title': scenario.title,
        'subtitle': scenario.subtitle,
        'description': scenario.description,
        'roleName': scenario.roleName,
        'roleTitle': scenario.roleTitle,
        'difficulty': scenario.difficulty.name,
        'tags': scenario.tags,
        'openingPrompt': scenario.openingPrompt,
      },
      'mode': mode.name,
      'userInput': _sanitizer.sanitize(userInput),
      'history': history
          .map(
            (message) => {
              'id': message.id,
              'sender': message.sender.name,
              'content': _sanitizer.sanitize(message.content),
              'timestamp': message.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  Object? _tryDecodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 409 ||
        statusCode == 425 ||
        statusCode == 429 ||
        statusCode >= 500;
  }

  Duration _retryDelay(int attempt) {
    return Duration(milliseconds: retryBackoff.inMilliseconds * attempt);
  }

  Stream<String> _streamBufferedText(String text) async* {
    if (text.trim().isEmpty) {
      throw const _InterviewRequestException('AI 服务返回内容为空', retryable: false);
    }

    final runes = text.runes.toList();
    for (
      var index = 0;
      index < runes.length;
      index += _bufferedStreamChunkSize
    ) {
      final end = index + _bufferedStreamChunkSize > runes.length
          ? runes.length
          : index + _bufferedStreamChunkSize;
      if (index > 0) {
        await Future<void>.delayed(_bufferedStreamTick);
      }
      yield String.fromCharCodes(runes.sublist(index, end));
    }
  }

  String _findLastUserInput(List<ChatMessage> history) {
    for (var index = history.length - 1; index >= 0; index -= 1) {
      final message = history[index];
      if (message.sender == ChatSender.user) {
        return message.content;
      }
    }

    return '';
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
}

class _InterviewResponsePayload {
  const _InterviewResponsePayload({
    required this.reply,
    required this.score,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.optimizedReply,
  });

  factory _InterviewResponsePayload.fromJson(Map<String, dynamic> json) {
    return _InterviewResponsePayload(
      reply: json['reply'] as String? ?? '',
      score: ((json['score'] as num?) ?? 0).round(),
      summary: json['summary'] as String? ?? '',
      strengths: _stringListFromJson(json['strengths']),
      improvements: _stringListFromJson(json['improvements']),
      optimizedReply: json['optimizedReply'] as String? ?? '',
    );
  }

  final String reply;
  final int score;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final String optimizedReply;

  static List<String> _stringListFromJson(Object? rawValue) {
    if (rawValue is! List<dynamic>) {
      return const [];
    }

    return rawValue.map((item) => item.toString()).toList();
  }
}

class _InterviewRequestException implements Exception {
  const _InterviewRequestException(this.message, {required this.retryable});

  final String message;
  final bool retryable;
}
