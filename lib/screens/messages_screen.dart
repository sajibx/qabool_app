import 'package:flutter/material.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/widgets/chat_view.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/models/chat_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => MessagesScreenState();
}

class MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Master-Detail State
  String? _selectedChatId;
  UserModel? _selectedUser;

  Future<void> refreshData() async {
    await _fetchChats();
  }

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // Theme-based colors
    const primaryColor = QaboolTheme.primary;
    const accentGold = QaboolTheme.accentGold;
    const bgLight = QaboolTheme.backgroundLight;
    const bgDark = QaboolTheme.backgroundDark;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 900;
            
            if (isLargeScreen) {
              return Row(
                children: [
                  // Left Pane: Conversation List
                  SizedBox(
                    width: 350,
                    child: _buildConversationsList(isDark, primaryColor, accentGold, bgDark),
                  ),
                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  // Right Pane: Active Chat
                  Expanded(
                    child: _selectedChatId != null
                        ? ChatView(
                            key: ValueKey(_selectedChatId),
                            chatId: _selectedChatId,
                            otherUser: _selectedUser,
                            showBackButton: false,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a conversation to start chatting',
                                  style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            }

            // Mobile View
            return _buildConversationsList(isDark, primaryColor, accentGold, bgDark);
          },
        ),
    );
  }

  Widget _buildConversationsList(bool isDark, Color primaryColor, Color accentGold, Color bgDark) {
    return Column(
      children: [
        // Polished Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: isDark ? bgDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearching ? primaryColor.withOpacity(0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onTap: () => setState(() => _isSearching = true),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                      _isSearching = val.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search people or messages...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: _isSearching ? primaryColor : Colors.grey[400],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main List
        Expanded(
          child: Consumer2<ChatService, AuthService>(
            builder: (context, chatService, authService, _) {
              final currentUserId = authService.currentUser?.id ?? "";
              final chats = chatService.chats.where((chat) {
                if (_searchQuery.isEmpty) return true;
                final otherUser = chat.otherParticipant(currentUserId);
                if (otherUser == null) return false;
                
                final nameMatch = otherUser.fullName.toLowerCase().contains(_searchQuery);
                final messageMatch = chat.lastMessage?.content.toLowerCase().contains(_searchQuery) ?? false;
                
                return nameMatch || messageMatch;
              }).toList();

              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (chats.isEmpty) {
                return Center(
                  child: Text(_searchQuery.isEmpty ? 'No messages yet' : 'No matching conversations'),
                );
              }
              return RefreshIndicator(
                onRefresh: refreshData,
                color: primaryColor,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherUser = chat.otherParticipant(currentUserId);
                    if (otherUser == null) return const SizedBox.shrink();
                    
                    final isSelected = _selectedChatId == chat.id;

                    return _buildMessageItem(
                      context: context,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      accentGold: accentGold,
                      imageUrl: otherUser.profileImageUrl ?? 'https://via.placeholder.com/150',
                      name: otherUser.fullName,
                      time: chat.lastMessage?.timeString ?? '',
                      message: chat.lastMessage?.content ?? '',
                      isTyping: chatService.isTyping(chat.id, currentUserId),
                      isActive: isSelected,
                      isOnline: otherUser.isOnline,
                      isFavorited: otherUser.isFavorited,
                      unreadCount: chat.unreadCount,
                      onTap: () {
                        if (MediaQuery.of(context).size.width > 900) {
                          setState(() {
                            _selectedChatId = chat.id;
                            _selectedUser = otherUser;
                          });
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.id,
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required Color accentGold,
    required String imageUrl,
    required String name,
    required String time,
    required String message,
    bool isTyping = false,
    bool isActive = false,
    bool isOnline = false,
    bool isFavorited = false,
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
                      imageUrl: resolveImageUrl(imageUrl),
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
                      Expanded(
                        child: Row(
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
                            if (isFavorited) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                            ],
                          ],
                        ),
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
                  color: primaryColor,
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
