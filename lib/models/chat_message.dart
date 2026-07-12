enum ChatSender {
  user,
  assistant,
}

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
}
