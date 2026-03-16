import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../screens/profile_screen.dart';
import '../main.dart';

class ChatView extends StatefulWidget {
  final String? chatId;
  final UserModel? otherUser;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ChatView({
    super.key, 
    this.chatId, 
    this.otherUser,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _activeChatId;
  Timer? _typingTimer;
  bool _isMeTyping = false;

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _scrollController.addListener(_onScroll);
    
    _updateActiveChat();
    _loadMessages();
    _messageController.addListener(_onTextChanged);
    _startStatusRefresh();
  }

  Timer? _statusRefreshTimer;
  UserModel? _freshOtherUser;

  void _startStatusRefresh() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshOtherUserStatus();
    });
  }

  UserModel get _effectiveOtherUser => _freshOtherUser ?? widget.otherUser!;

  Future<void> _refreshOtherUserStatus() async {
    final otherUserId = widget.otherUser?.id;
    if (otherUserId == null || !mounted) return;

    try {
      final user = await context.read<ProfileService>().getProfile(otherUserId);
      if (mounted) {
        setState(() {
          _freshOtherUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing user status: $e');
    }
  }

  void _onTextChanged() {
    if (_activeChatId == null || widget.otherUser == null) return;

    if (!_isMeTyping) {
      _isMeTyping = true;
      context.read<ChatService>().setTypingStatus(
        chatId: _activeChatId!,
        recipientId: widget.otherUser!.id,
        isTyping: true,
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isMeTyping) {
        _isMeTyping = false;
        context.read<ChatService>().setTypingStatus(
          chatId: _activeChatId!,
          recipientId: widget.otherUser!.id,
          isTyping: false,
        );
      }
    });
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId) {
      _activeChatId = widget.chatId;
      _isLoading = true;
      _updateActiveChat();
      _loadMessages();
    }
  }

  void _updateActiveChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatService>().setActiveChat(_activeChatId);
      }
    });
  }

  void _onScroll() {
    if (_activeChatId == null) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatService>().fetchMoreMessages(_activeChatId!);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _statusRefreshTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentContext?.read<ChatService>().setActiveChat(null);
    });
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
      
      chatService.setActiveChat(_activeChatId);

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
          0,
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
    final bgLight = QaboolTheme.backgroundLight;
    final bgDark = QaboolTheme.backgroundDark;

    final otherUser = widget.otherUser;

    if (otherUser == null && _activeChatId == null) {
      return Container(
        color: isDark ? bgDark : bgLight,
        child: const Center(child: Text('Select a conversation to start chatting')),
      );
    }

    return Container(
      color: isDark ? bgDark : bgLight,
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
                if (widget.showBackButton)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey[100] : Colors.grey[900]),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                  ),
                if (widget.showBackButton) const SizedBox(width: 8),
                if (otherUser != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(user: _effectiveOtherUser),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              backgroundImage: _effectiveOtherUser.profileImageUrl != null && _effectiveOtherUser.profileImageUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(resolveImageUrl(_effectiveOtherUser.profileImageUrl!))
                                  : null,
                              child: (_effectiveOtherUser.profileImageUrl == null || _effectiveOtherUser.profileImageUrl!.isEmpty)
                                  ? Icon(Icons.person, color: isDark ? Colors.grey[600] : Colors.grey[400])
                                  : null,
                            ),
                            if (_effectiveOtherUser.isOnline)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _effectiveOtherUser.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.grey[100] : Colors.grey[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _effectiveOtherUser.isOnline ? 'ONLINE NOW' : (_effectiveOtherUser.lastSeen != null ? 'LAST SEEN ${timeago.format(_effectiveOtherUser.lastSeen!).toUpperCase()}' : 'OFFLINE'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _effectiveOtherUser.isOnline ? primaryColor : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ),

          // Message History
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, _) {
                if (_isLoading && _activeChatId != null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = _activeChatId != null ? chatService.getMessages(_activeChatId!) : [];
                final hasMore = _activeChatId != null ? chatService.hasMoreMessages(_activeChatId!) : false;
                final isLoadingMore = _activeChatId != null ? chatService.isLoadingMore(_activeChatId!) : false;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      _activeChatId == null ? 'Select a chat' : 'No messages yet. Say hi!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                final displayMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: displayMessages.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayMessages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: isLoadingMore
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final message = displayMessages[index];
                    final currentUserId = context.read<AuthService>().currentUser?.id;
                    final isMe = currentUserId != null && 
                        message.senderId.trim().toLowerCase() == currentUserId.trim().toLowerCase();
                    
                    if (isMe) {
                      return _buildSentMessage(
                        primaryColor: primaryColor,
                        message: message.content,
                        time: message.timeString,
                        isSeen: message.status == MessageStatus.READ,
                      );
                    } else {
                      return _buildReceivedMessage(
                        isDark: isDark,
                        imageUrl: resolveImageUrl(otherUser?.profileImageUrl),
                        message: message.content,
                        time: message.timeString,
                      );
                    }
                  },
                );
              },
            ),
          ),
          
          // Typing Indicator above input
          Consumer2<ChatService, AuthService>(
            builder: (context, chatService, authService, _) {
              if (chatService.isTyping(_activeChatId ?? "", authService.currentUser?.id)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${widget.otherUser?.firstName ?? "Someone"} is typing',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input Area
          if (_activeChatId != null)
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
