import 'user_model.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final List<UserModel> participants;
  final List<MessageModel> messages;
  final MessageModel? lastMessage;

  ChatModel({
    required this.id,
    required this.participants,
    this.messages = const [],
    this.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => MessageModel.fromJson(m))
              .toList()
          : <MessageModel>[];
    
    return ChatModel(
      id: json['id'],
      participants: (json['participants'] as List)
          .map((p) => UserModel.fromJson(p))
          .toList(),
      messages: messages,
      lastMessage: json['lastMessage'] != null 
          ? MessageModel.fromJson(json['lastMessage'])
          : (messages.isNotEmpty ? messages.last : null),
    );
  }

  ChatModel copyWith({
    String? id,
    List<UserModel>? participants,
    List<MessageModel>? messages,
    MessageModel? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  // Helper to get the other participant in a 1:1 chat
  UserModel? otherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return null;
    }
  }
}
