enum MessageType { TEXT, IMAGE }
enum MessageStatus { SENT, DELIVERED, READ }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      chatId: (json['chatId'] ?? json['chat']?['id'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender']?['id'])?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.TEXT,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'SENT'),
        orElse: () => MessageStatus.SENT,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get timeString {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
