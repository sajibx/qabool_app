import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/api_service.dart';
import 'package:qabool_app/models/chat_model.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/widgets/floating_chat_window.dart';

class FloatingChatOverlay extends StatelessWidget {
  final Widget child;

  const FloatingChatOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<ChatService>(
          builder: (context, chatService, _) {
            final isLargeScreen = MediaQuery.of(context).size.width > 800;
            final isMessagesPageActive = chatService.isMessagesPageActive;
            final floatingIds = chatService.activeFloatingChatIds;

            if (!isLargeScreen || isMessagesPageActive || floatingIds.isEmpty) {
              return const SizedBox.shrink();
            }

            return Positioned(
              bottom: 0,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: floatingIds.map((chatId) {
                    final otherUser = chatService.getFloatingOtherUser(chatId);
                    
                    if (otherUser == null) {
                      return const SizedBox.shrink();
                    }

                    return FloatingChatWindow(
                      chatId: chatId,
                      otherUser: otherUser,
                      onClose: () => chatService.toggleFloatingChat(chatId, open: false),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
