import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/practice_record.dart';
import '../models/scenario.dart';
import '../services/interview_service.dart';
import '../services/input_guard.dart';
import '../services/practice_store.dart';
import '../services/sensitive_data_sanitizer.dart';
import 'feedback_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.scenario,
    required this.mode,
    required this.service,
    this.inputGuard = const InputGuard(),
  });

  final Scenario scenario;
  final InterviewMode mode;
  final InterviewService service;
  final InputGuard inputGuard;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const SensitiveDataSanitizer _sanitizer = SensitiveDataSanitizer();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<ChatMessage> _messages;
  bool _isWaitingForReply = false;
  bool _isStreamingReply = false;
  int _messageCounter = 0;

  int get _userMessageCount {
    return _messages
        .where((message) => message.sender == ChatSender.user)
        .length;
  }

  bool get _canFinishPractice {
    return !_isReplying && _userMessageCount >= 3;
  }

  int get _remainingTurnsToFinish {
    final remaining = 3 - _userMessageCount;
    return remaining > 0 ? remaining : 0;
  }

  @override
  void initState() {
    super.initState();
    _messages = [
      widget.service.buildOpeningMessage(
        scenario: widget.scenario,
        mode: widget.mode,
      ),
    ];
    _controller.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInputChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {});
  }

  InputGuardResult get _inputGuardResult {
    return widget.inputGuard.evaluate(_controller.text);
  }

  bool get _canSend {
    return !_isReplying && _inputGuardResult.canSend;
  }

  bool get _isReplying => _isWaitingForReply || _isStreamingReply;

  Future<void> _sendMessage() async {
    final guardResult = _inputGuardResult;
    if (!guardResult.canSend || _isReplying) {
      return;
    }
    final content = guardResult.normalizedText;

    final userMessage = ChatMessage(
      id: 'user-${_messageCounter++}',
      sender: ChatSender.user,
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isWaitingForReply = true;
    });
    _scrollToBottom();

    try {
      await _streamReply(
        scenario: widget.scenario,
        mode: widget.mode,
        history: List<ChatMessage>.unmodifiable(_messages),
        userInput: content,
        messageId: 'assistant-${_messageCounter++}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isWaitingForReply = false;
        _isStreamingReply = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _streamReply({
    required Scenario scenario,
    required InterviewMode mode,
    required List<ChatMessage> history,
    required String userInput,
    required String messageId,
  }) async {
    final streamedContent = StringBuffer();
    ChatMessage? reply;
    var replyIndex = -1;
    var hasReceivedChunk = false;

    if (!mounted) {
      return;
    }

    await for (final chunk in widget.service.streamReply(
      scenario: scenario,
      mode: mode,
      history: history,
      userInput: userInput,
      messageId: messageId,
    )) {
      if (!mounted) {
        return;
      }

      streamedContent.write(chunk);
      if (!hasReceivedChunk) {
        hasReceivedChunk = true;
        reply = ChatMessage(
          id: messageId,
          sender: ChatSender.assistant,
          content: streamedContent.toString(),
          timestamp: DateTime.now(),
        );
        setState(() {
          _isWaitingForReply = false;
          _isStreamingReply = true;
          replyIndex = _messages.length;
          _messages.add(reply!);
        });
      } else {
        setState(() {
          _messages[replyIndex] = reply!.copyWith(
            content: streamedContent.toString(),
          );
        });
      }
      _scrollToBottom();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isWaitingForReply = false;
      _isStreamingReply = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _finishPractice() async {
    if (!_canFinishPractice) {
      return;
    }

    try {
      final feedback = await widget.service.buildFeedback(
        scenario: widget.scenario,
        mode: widget.mode,
        history: List<ChatMessage>.unmodifiable(_messages),
      );
      final lastUserMessage = _messages.lastWhere(
        (message) => message.sender == ChatSender.user,
        orElse: () => _messages.first,
      );
      final record = PracticeRecord(
        id: 'record-${DateTime.now().microsecondsSinceEpoch}',
        scenarioId: widget.scenario.id,
        scenarioTitle: widget.scenario.title,
        mode: widget.mode,
        completedAt: DateTime.now(),
        score: feedback.overallScore,
        summary: feedback.summary,
        strengths: feedback.strengths,
        improvements: feedback.improvements,
        optimizedReply: feedback.optimizedReply,
        highlightQuote: _sanitizer.sanitize(lastUserMessage.content),
      );

      await PracticeStore.instance.addRecord(record);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FeedbackPage(feedback: feedback, record: record),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputGuardResult = _inputGuardResult;
    final hintColor = switch (inputGuardResult.level) {
      InputNoticeLevel.error => theme.colorScheme.error,
      InputNoticeLevel.hint => theme.colorScheme.secondary,
      InputNoticeLevel.none => theme.colorScheme.onSurfaceVariant,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scenario.title),
        actions: [
          TextButton.icon(
            key: const Key('finish-practice-button'),
            onPressed: _canFinishPractice ? _finishPractice : null,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('结束练习'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(widget.mode.label),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(
                            _canFinishPractice
                                ? '已满足结束条件'
                                : '再完成 $_remainingTurnsToFinish 轮可结束',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.scenario.roleName} · ${widget.scenario.roleTitle}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scenario.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _messages.length + (_isWaitingForReply ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isWaitingForReply && index == _messages.length) {
                  return const _TypingIndicator();
                }

                final message = _messages[index];
                final isStreamingMessage =
                    _isStreamingReply &&
                    index == _messages.length - 1 &&
                    message.sender == ChatSender.assistant;
                return _MessageBubble(
                  message: message,
                  isStreaming: isStreamingMessage,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('chat-input'),
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: '输入你的回答...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        key: const Key('send-button'),
                        onPressed: _canSend ? _sendMessage : null,
                        child: const Text('发送'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: inputGuardResult.hasMessage
                        ? Text(
                            key: const Key('chat-input-notice'),
                            inputGuardResult.message!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hintColor,
                            ),
                          )
                        : const SizedBox(
                            key: Key('chat-input-notice-empty'),
                            height: 0,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.isStreaming = false});

  final ChatMessage message;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                message.content.isEmpty && isStreaming
                    ? '...'
                    : message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text('AI 正在输入...'),
          ),
        ),
      ),
    );
  }
}
