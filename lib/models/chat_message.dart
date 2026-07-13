enum ChatSender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final ChatSender sender;
  final String content;
  final DateTime timestamp;

  ChatMessage copyWith({
    String? id,
    ChatSender? sender,
    String? content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
