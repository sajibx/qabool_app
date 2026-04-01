import '../models/user_model.dart';

enum NotificationType {
  FAVORITE,
  CONNECTION_REQUEST,
  CONNECTION_ACCEPTED,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final UserModel? sender;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: _parseType(json['type']),
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
    );
  }

  static NotificationType _parseType(dynamic type) {
    final typeStr = type?.toString().toUpperCase() ?? '';
    if (typeStr.contains('FAVORITE')) return NotificationType.FAVORITE;
    if (typeStr.contains('CONNECTION_REQUEST')) return NotificationType.CONNECTION_REQUEST;
    if (typeStr.contains('CONNECTION_ACCEPTED')) return NotificationType.CONNECTION_ACCEPTED;
    return NotificationType.FAVORITE; // Default
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    UserModel? sender,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}
