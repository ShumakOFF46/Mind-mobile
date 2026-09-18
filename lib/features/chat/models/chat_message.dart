class ChatMessage {
  final String    text;
  final bool      isUser;
  final String?   imageUrl;   // сетевой URL загруженного фото
  final DateTime  timestamp;
  bool liked;

  /// SDUI-блоки сообщения (generic `blocks` из контракта app_chat.py SSE:
  /// content → blocks? → calendar_proposal? → conversation_id → [DONE]).
  /// null, если бэкенд не прислал непустой список блоков в этом ходу
  /// (см. ProjectFull.md: пустой список не порождает событие вообще).
  final List<Map<String, dynamic>>? blocks;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageUrl,
    this.blocks,
    DateTime? timestamp,
    this.liked = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? liked,
    List<Map<String, dynamic>>? blocks,
  }) => ChatMessage(
    text:      text      ?? this.text,
    isUser:    isUser,
    imageUrl:  imageUrl,
    blocks:    blocks    ?? this.blocks,
    timestamp: timestamp,
    liked:     liked     ?? this.liked,
  );
}
