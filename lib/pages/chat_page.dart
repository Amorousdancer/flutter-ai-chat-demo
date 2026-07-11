import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/practice_record.dart';
import '../models/scenario.dart';
import '../services/input_guard.dart';
import '../services/practice_store.dart';
import '../services/mock_interview_service.dart';
import 'feedback_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.scenario,
    required this.mode,
    this.service = const MockInterviewService(),
    this.inputGuard = const InputGuard(),
  });

  final Scenario scenario;
  final InterviewMode mode;
  final MockInterviewService service;
  final InputGuard inputGuard;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<ChatMessage> _messages;
  bool _isReplying = false;
  int _messageCounter = 0;

  int get _userMessageCount {
    return _messages.where((message) => message.sender == ChatSender.user).length;
  }

  bool get _canFinishPractice {
    return !_isReplying && _userMessageCount >= 3;
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
      _isReplying = true;
    });
    _scrollToBottom();

    final reply = await widget.service.generateReply(
      scenario: widget.scenario,
      mode: widget.mode,
      history: List<ChatMessage>.unmodifiable(_messages),
      userInput: content,
      messageId: 'assistant-${_messageCounter++}',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(reply);
      _isReplying = false;
    });
    _scrollToBottom();
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

    final feedback = widget.service.buildFeedback(
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
      highlightQuote: lastUserMessage.content,
    );

    PracticeStore.instance.addRecord(record);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedbackPage(
          feedback: feedback,
          record: record,
        ),
      ),
    );
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
          TextButton(
            key: const Key('finish-practice-button'),
            onPressed: _canFinishPractice ? _finishPractice : null,
            child: const Text('结束练习'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode.label,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.scenario.roleName} · ${widget.scenario.roleTitle}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _messages.length + (_isReplying ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isReplying && index == _messages.length) {
                  return const _TypingIndicator();
                }

                final message = _messages[index];
                return _MessageBubble(message: message);
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
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                message.content,
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
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text('AI 正在输入...'),
          ),
        ),
      ),
    );
  }
}
