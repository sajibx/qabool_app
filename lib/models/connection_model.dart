import 'user_model.dart';

enum ConnectionStatus { PENDING, ACCEPTED, REJECTED }

class ConnectionModel {
  final String id;
  final ConnectionStatus status;
  final UserModel? requester;
  final UserModel? recipient;
  final DateTime createdAt;

  ConnectionModel({
    required this.id,
    required this.status,
    this.requester,
    this.recipient,
    required this.createdAt,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'],
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.PENDING,
      ),
      requester: json['requester'] != null ? UserModel.fromJson(json['requester']) : null,
      recipient: json['recipient'] != null ? UserModel.fromJson(json['recipient']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
