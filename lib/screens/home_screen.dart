import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoadingProfiles = true;
  bool _isLoadingChats = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _nearbyProfiles = [];
  List<UserModel> _likedMeProfiles = [];
  bool _isLoadingLikedMe = true;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    await Future.wait([
      _fetchProfiles(),
      _fetchLikedMeProfiles(),
      _fetchChats(),
    ]);
  }

  Future<void> _fetchProfiles({String? query}) async {
    try {
      if (query != null) {
        setState(() => _isLoadingProfiles = true);
      }
      final authService = context.read<AuthService>();
      final profileService = context.read<ProfileService>();
      final profiles = await profileService.getDiscoveryList(search: query);
      if (mounted) {
        final currentUser = authService.currentUser;
        setState(() {
          _nearbyProfiles = profiles.where((p) {
            // Filter out self
            if (p.id == currentUser?.id) return false;
            
            // If current user has gender set, show only opposite gender
            if (currentUser?.gender != null) {
              if (currentUser!.gender == 'Male') {
                return p.gender == 'Female';
              } else if (currentUser.gender == 'Female') {
                return p.gender == 'Male';
              }
            }
            
            return true;
          }).toList();
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  Future<void> _fetchLikedMeProfiles() async {
    try {
      final profileService = context.read<ProfileService>();
      final profiles = await profileService.getUsersWhoFavoritedMe();
      if (mounted) {
        setState(() {
          _likedMeProfiles = profiles;
          _isLoadingLikedMe = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLikedMe = false);
    }
  }

  Future<void> _fetchChats() async {
    try {
      final chatService = context.read<ChatService>();
      await chatService.fetchChats();
      if (mounted) {
        setState(() {
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const pColor = QaboolTheme.primary;
    const bgLight = QaboolTheme.backgroundLight;
    const bgDark = QaboolTheme.backgroundDark;
    const neutralSoftUrlLight = Color(0xFFF4F1F0);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Cleaned up to avoid empty space)
            if (_isSearching)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isDark ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search people...',
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.search, size: 20, color: pColor),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _isSearching = false);
                                _fetchProfiles();
                              },
                            ),
                          ),
                          onSubmitted: (val) {
                            _fetchProfiles(query: val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshData,
                color: pColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Who Liked You Section
                    if (_likedMeProfiles.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Who Liked You',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[100] : Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: _isLoadingLikedMe
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _likedMeProfiles.length,
                                itemBuilder: (context, index) {
                                  final profile = _likedMeProfiles[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(user: profile),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: profile.profileImageUrl != null
                                                ? CachedNetworkImageProvider(profile.profileImageUrl!)
                                                : null,
                                            child: profile.profileImageUrl == null
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            profile.firstName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // People Nearby Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (!_isSearching)
                                IconButton(
                                  icon: const Icon(Icons.search, color: pColor, size: 20),
                                  onPressed: () => setState(() => _isSearching = true),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              if (!_isSearching) const SizedBox(width: 8),
                              Text(
                                _isSearching ? 'Search Results' : 'People Nearby',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[100] : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => widget.onNavigate?.call(1), // Switch to Discovery tab
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: pColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Profile Cards List
                    SizedBox(
                      height: 320,
                      child: _isLoadingProfiles
                          ? const Center(child: CircularProgressIndicator())
                          : _nearbyProfiles.isEmpty
                              ? const Center(child: Text('No profiles nearby'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _nearbyProfiles.length,
                                  itemBuilder: (context, index) {
                                    final profile = _nearbyProfiles[index];
                                    return _buildProfileCard(
                                      context: context,
                                      profile: profile,
                                      onConnect: () async {
                                        try {
                                          final chatService = context.read<ChatService>();
                                          final chat = await chatService.createChat(profile.id);
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                chatId: chat.id,
                                                otherUser: profile,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to connect: $e')),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 24),

                    // Chat Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Recent Conversations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[100] : Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Consumer2<ChatService, AuthService>(
                        builder: (context, chatService, authService, _) {
                          if (_isLoadingChats) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final chats = chatService.chats;
                          if (chats.isEmpty) {
                            return const Center(child: Text('No recent conversations'));
                          }
                          final currentUserId = authService.currentUser?.id ?? "";
                          return Column(
                            children: chats.take(3).map((chat) {
                              final otherUser = chat.otherParticipant(currentUserId);
                              if (otherUser == null) return const SizedBox.shrink();
                              return _buildChatItem(
                                context: context,
                                isDark: isDark,
                                imageUrl: otherUser.profileImageUrl ?? 'https://via.placeholder.com/150',
                                name: otherUser.fullName,
                                time: chat.lastMessage?.timeString ?? 'No messages',
                                message: chat.lastMessage?.content ?? '',
                                isOnline: otherUser.isOnline,
                                isUnread: false, 
                                accentColor: pColor,
                                cardBgColor: isDark ? bgDark : Colors.white,
                                borderColor: isDark ? const Color(0xFF1E293B) : neutralSoftUrlLight,
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
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: OutlinedButton(
                        onPressed: () => widget.onNavigate?.call(2), // Switch to Messages tab
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                          side: BorderSide(
                            color: isDark ? const Color(0xFF1E293B) : neutralSoftUrlLight,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('See More Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProfileCard({
    required BuildContext context,
    required UserModel profile,
    required VoidCallback onConnect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const aColor = QaboolTheme.accentGold;
    const pColor = QaboolTheme.primary;
    
    final imageUrl = profile.profileImageUrl ?? 'https://via.placeholder.com/150';
    final name = profile.firstName;
    final age = profile.age?.toString() ?? "";
    final verified = profile.isVerified;
    final location = '${profile.city}, ${profile.country}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: profile),
          ),
        );
      },
      child: Container(
        width: 170, // Increased slightly to fit button
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark ? pColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final profileService = context.read<ProfileService>();
                          final wasFavorited = profile.isFavorited;
                          
                          try {
                            // Optimistic update in the local list
                            setState(() {
                              final index = _nearbyProfiles.indexWhere((p) => p.id == profile.id);
                              if (index != -1) {
                                _nearbyProfiles[index] = _nearbyProfiles[index].copyWith(isFavorited: !wasFavorited);
                              }
                            });

                            if (wasFavorited) {
                              await profileService.unfavoriteUser(profile.id);
                            } else {
                              await profileService.favoriteUser(profile.id);
                            }
                            
                            // Background refresh to ensure consistency
                            refreshData();
                          } catch (e) {
                            // Rollback on error
                            setState(() {
                              final index = _nearbyProfiles.indexWhere((p) => p.id == profile.id);
                              if (index != -1) {
                                _nearbyProfiles[index] = _nearbyProfiles[index].copyWith(isFavorited: wasFavorited);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            profile.isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: profile.isFavorited ? Colors.red : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$name, $age',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: aColor, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 32),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CONNECT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required bool isDark,
    required String imageUrl,
    required String name,
    required String time,
    required String message,
    bool isOnline = false,
    bool isUnread = false,
    required Color accentColor,
    required Color cardBgColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: cardBgColor != Colors.transparent
              ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person,
                          color: isDark ? Colors.grey[600] : Colors.grey[400])
                      : null,
                  onBackgroundImageError: imageUrl.isNotEmpty
                      ? (exception, stackTrace) {
                          // Handle error by showing child
                        }
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? accentColor : Colors.grey[500],
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUnread ? (isDark ? Colors.grey[300] : Colors.grey[800]) : Colors.grey[500],
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
