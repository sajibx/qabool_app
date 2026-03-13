import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/screens/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      await context.read<ChatService>().fetchChats();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tailwind extracted colors
    const primaryColor = QaboolTheme.primary; // Gold: #d4af35
    const secondaryColor = QaboolTheme.maroon; // Maroon: #800000
    const bgLight = Color(0xFFF8F7F6);
    const bgDark = Color(0xFF201D12);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: isDark ? bgDark : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qabool',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? primaryColor : secondaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'MESSAGES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search,
                          color: isDark ? Colors.grey[200] : Colors.grey[700]),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ),

            // Main List
            Expanded(
              child: Consumer2<ChatService, AuthService>(
                builder: (context, chatService, authService, _) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final chats = chatService.chats;
                  if (chats.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }
                  final currentUserId = authService.currentUser?.id ?? "";
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUser = chat.otherParticipant(currentUserId);
                      if (otherUser == null) return const SizedBox.shrink();
                      return _buildMessageItem(
                        context: context,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        imageUrl: otherUser.profileImageUrl ?? 'https://via.placeholder.com/150',
                        name: otherUser.fullName,
                        time: chat.lastMessage?.timeString ?? '',
                        message: chat.lastMessage?.content ?? '',
                        isTyping: false,
                        isActive: false,
                        isOnline: otherUser.isOnline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.id,
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
    required String imageUrl,
    required String name,
    required String time,
    required String message,
    bool isTyping = false,
    bool isActive = false,
    bool isOnline = false,
    int unreadCount = 0,
    VoidCallback? onTap,
    IconData? msgStatusIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.05) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? primaryColor : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.5)
                  : const Color(0xFFF8FAFC),
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: isActive ? 2 : 1),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(Icons.person,
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? primaryColor : Colors.grey[400],
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (msgStatusIcon != null) ...[
                        Icon(msgStatusIcon, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle:
                                isTyping ? FontStyle.italic : FontStyle.normal,
                            fontWeight: (isActive || isTyping)
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: (isActive || isTyping)
                                ? (isDark ? Colors.grey[300] : Colors.grey[700])
                                : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unread Badge
            if (unreadCount > 0) ...[
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
