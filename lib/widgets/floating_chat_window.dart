import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/models/chat_model.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/widgets/chat_view.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FloatingChatWindow extends StatelessWidget {
  final String chatId;
  final UserModel otherUser;
  final VoidCallback onClose;

  const FloatingChatWindow({
    super.key,
    required this.chatId,
    required this.otherUser,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;
    final bgDark = const Color(0xFF0F172A);
    final bgLight = Colors.white;

    return Container(
      width: 320,
      height: 440,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: isDark ? bgDark : bgLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              // Maybe toggle minimize in future?
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    backgroundImage: otherUser.profileImageUrl != null && otherUser.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(resolveImageUrl(otherUser.profileImageUrl!))
                        : null,
                    child: (otherUser.profileImageUrl == null || otherUser.profileImageUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          otherUser.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (otherUser.isOnline)
                          const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          // Chat View Body
          Expanded(
            child: ChatView(
              chatId: chatId,
              otherUser: otherUser,
              showBackButton: false,
              isFloating: true,
            ),
          ),
        ],
      ),
    );
  }
}
