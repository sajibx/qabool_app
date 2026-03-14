import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/chat_view.dart';

class ChatScreen extends StatelessWidget {
  final String? chatId;
  final UserModel? otherUser;

  const ChatScreen({super.key, this.chatId, this.otherUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ChatView(
          chatId: chatId,
          otherUser: otherUser,
        ),
      ),
    );
  }
}
