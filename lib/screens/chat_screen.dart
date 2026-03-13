import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/models/message_model.dart';
import 'package:qabool_app/models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final UserModel? otherUser;

  const ChatScreen({super.key, this.chatId, this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _activeChatId;

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_activeChatId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final chatService = context.read<ChatService>();
      await chatService.fetchMessages(_activeChatId!);
      await chatService.markAsRead(_activeChatId!);
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeChatId == null) return;

    _messageController.clear();
    try {
      await context.read<ChatService>().sendMessage(
            chatId: _activeChatId!,
            recipientId: widget.otherUser?.id ?? "",
            content: text,
          );
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;
    final accentGold = QaboolTheme.accentGold;
    final bgLight = QaboolTheme.backgroundLight;
    final bgDark = QaboolTheme.backgroundDark;

    final otherUser = widget.otherUser;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey[100] : Colors.grey[900]),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (otherUser != null) ...[
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: otherUser.profileImageUrl != null && otherUser.profileImageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(otherUser.profileImageUrl!)
                              : null,
                          child: (otherUser.profileImageUrl == null || otherUser.profileImageUrl!.isEmpty)
                              ? Icon(Icons.person, color: isDark ? Colors.grey[600] : Colors.grey[400])
                              : null,
                        ),
                        if (otherUser.isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherUser.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.grey[100] : Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            otherUser.isOnline ? 'ONLINE NOW' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: otherUser.isOnline ? primaryColor : Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Message History
            Expanded(
              child: Consumer<ChatService>(
                builder: (context, chatService, _) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = _activeChatId != null ? chatService.getMessages(_activeChatId!) : [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hi!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }


                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final currentUserId = context.watch<AuthService>().currentUser?.id ?? "";
                      final isMe = message.senderId.trim() == currentUserId.trim();
                      
                      if (isMe) {
                        return _buildSentMessage(
                          primaryColor: primaryColor,
                          accentGold: accentGold,
                          message: message.content,
                          time: message.timeString,
                          isSeen: message.status == MessageStatus.READ,
                        );
                      } else {
                        return _buildReceivedMessage(
                          isDark: isDark,
                          imageUrl: otherUser?.profileImageUrl ?? 'https://via.placeholder.com/150',
                          message: message.content,
                          time: message.timeString,
                        );
                      }
                    },
                  );
                },
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      elevation: 4,
                    ),
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage({
    required bool isDark,
    required String imageUrl,
    required String message,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            backgroundImage: imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: imageUrl.isEmpty
                ? Icon(Icons.person, size: 8, color: isDark ? Colors.grey[600] : Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSentMessage({
    required Color primaryColor,
    required Color accentGold,
    required String message,
    required String time,
    required bool isSeen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 4),
                    if (isSeen)
                      Icon(Icons.done_all, size: 14, color: primaryColor)
                    else
                      Icon(Icons.done, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
