class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.lastMessageAt,
    this.otherName = 'Usuario',
    this.otherUsername = '',
    this.lastMessageBody,
  });
  final String id, requesterId, recipientId, status, otherName, otherUsername;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  bool get pending => status == 'pending';
  bool get accepted => status == 'accepted';
  factory ChatConversation.fromJson(
    Map<String, dynamic> j, {
    String? otherName,
    String? otherUsername,
  }) => ChatConversation(
    id: j['id'] as String,
    requesterId: j['requester_id'] as String,
    recipientId: j['recipient_id'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    lastMessageAt: j['last_message_at'] == null
        ? null
        : DateTime.parse(j['last_message_at'] as String),
    otherName: otherName ?? 'Usuario',
    otherUsername: otherUsername ?? '',
    lastMessageBody: j['last_message_body'] as String?,
  );
  ChatConversation copyWithLastMessage(String? body) => ChatConversation(
    id: id,
    requesterId: requesterId,
    recipientId: recipientId,
    status: status,
    createdAt: createdAt,
    lastMessageAt: lastMessageAt,
    otherName: otherName,
    otherUsername: otherUsername,
    lastMessageBody: body,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });
  final String id, conversationId, senderId, body;
  final DateTime createdAt;
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId: j['sender_id'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
