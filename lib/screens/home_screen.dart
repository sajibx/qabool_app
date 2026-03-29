import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/connection_service.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';
import 'package:qabool_app/widgets/user_discovery_card.dart';
import 'package:qabool_app/widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isAnimating = false;
  bool _isLoadingProfiles = true;
  bool _isLoadingChats = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _nearbyProfiles = [];
  List<UserModel> _likedMeProfiles = [];
  bool _isLoadingLikedMe = true;

  // Filter State
  String? _selectedReligion;
  String? _selectedLocation;
  RangeValues _ageRange = const RangeValues(18, 80);
  String? _selectedEducation;
  bool _showConnected = false;
  bool _showSkipped = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0), // Default swipe right
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    await Future.wait([
      _fetchProfiles(),
      _fetchLikedMeProfiles(),
      _fetchChats(),
    ]);
  }

  Future<void> _fetchProfiles({String? query, bool silent = false}) async {
    try {
      if (query != null || !silent) {
        setState(() => _isLoadingProfiles = true);
      }
      final profileService = context.read<ProfileService>();
      final authService = context.read<AuthService>();
      
      // If the user wants connected or skipped users, we must use the Explore API 
      // since the Home API rigidly filters them out.
      final profiles = await profileService.getExploreProfiles(_showConnected, _showSkipped);
      
      if (mounted) {
        final currentUser = authService.currentUser;
        setState(() {
          _nearbyProfiles = profiles.where((p) {
            // Filter out self
            if (p.id == currentUser?.id) return false;

            // Optional local search query matching if applicable
            if (query != null && query.isNotEmpty) {
               final nameMatch = p.firstName.toLowerCase().contains(query.toLowerCase()) || 
                                 p.lastName.toLowerCase().contains(query.toLowerCase());
               if (!nameMatch) return false;
            }

            // Filter based on past issues preferences (if not done in backend)
            if (currentUser != null && !currentUser.acceptsPastIssues && p.hasPastIssues) {
              return false;
            }

            // Local filters for Explore
            if (p.age != null && (p.age! < _ageRange.start || p.age! > _ageRange.end)) {
              return false;
            }
            if (_selectedEducation != null && p.education != _selectedEducation) {
              return false;
            }
            if (_selectedReligion != null && p.religion != _selectedReligion) {
              return false;
            }
            if (_selectedLocation != null && p.region != null && !p.region!.contains(_selectedLocation!)) {
              return false;
            }
            
            return true;
          }).toList();
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nearbyProfiles = [];
          _isLoadingProfiles = false;
        });
        // Remove mock data generation code on error for production
      }
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialAgeRange: _ageRange,
        initialReligion: _selectedReligion,
        initialEducation: _selectedEducation,
        initialLocation: _selectedLocation,
        initialShowConnected: _showConnected,
        initialShowSkipped: _showSkipped,
        onApply: (ageRange, religion, education, location, showConnected, showSkipped) {
          setState(() {
            _ageRange = ageRange;
            _selectedReligion = religion;
            _selectedEducation = education;
            _selectedLocation = location;
            _showConnected = showConnected;
            _showSkipped = showSkipped;
          });
          _fetchProfiles();
        },
      ),
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = MediaQuery.of(context).size.width > 800;

            if (isLargeScreen) {
              return Row(
                children: [
                  // Main Content Area
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(isDark, pColor, bgDark, bgLight, isLargeScreen: true),
                  ),
                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  // Sidebar Area (Recent Conversations)
                  SizedBox(
                    width: 350,
                    child: _buildSidebarConversations(isDark, pColor, bgDark, bgLight, neutralSoftUrlLight),
                  ),
                ],
              );
            }

            // Mobile View
            return _buildMainContent(isDark, pColor, bgDark, bgLight, isLargeScreen: false);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark, Color pColor, Color bgDark, Color bgLight, {required bool isLargeScreen}) {
    const neutralSoftUrlLight = Color(0xFFF4F1F0);
    return Column(
      children: [
        // Top Left Filter Settings Icon
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              InkWell(
                onTap: _showFilters,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                    ],
                  ),
                  child: Icon(Icons.tune, color: pColor, size: 24),
                ),
              ),
            ],
          ),
        ),

        if (isLargeScreen && _isSearching)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDark ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search people...',
                        hintStyle: const TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: pColor),
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
                    const SizedBox(height: 4),


                    // People Nearby Header (Only on Desktop)
                    if (isLargeScreen)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (!_isSearching)
                                  IconButton(
                                    icon: Icon(Icons.search, color: pColor, size: 20),
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
                                  child: Text(
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
                              child: Text(
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
                    if (isLargeScreen) const SizedBox(height: 16),

                    // People Section
                    Builder(builder: (context) {
                      if (isLargeScreen) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _isLoadingProfiles
                              ? const Center(child: CircularProgressIndicator())
                              : _nearbyProfiles.isEmpty
                                  ? const Center(child: Text('No profiles nearby'))
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                                        childAspectRatio: 0.55, // Taller cards
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: _nearbyProfiles.length,
                                      itemBuilder: (context, index) {
                                        final profile = _nearbyProfiles[index];
                                        return UserDiscoveryCard(
                                          user: profile,
                                          isGridMode: true,
                                          onConnect: () => _handleConnect(profile),
                                          onFavorite: () => _handleFavorite(profile),
                                          onSkip: () => _handleSkip(profile),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)));
                                          },
                                        );
                                      },
                                    ),
                        );
                      }

                      // Mobile Single-Card "Tinder" style
                      return _isLoadingProfiles
                          ? const Center(child: CircularProgressIndicator())
                          : _nearbyProfiles.isEmpty
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('No more profiles nearby', textAlign: TextAlign.center),
                                ))
                              : Column(
                                  children: [
                                    const SizedBox(height: 4),
                                    Center(
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.9,
                                        height: MediaQuery.of(context).size.height * 0.65,
                                        child: SlideTransition(
                                          position: _slideAnimation,
                                          child: UserDiscoveryCard(
                                            user: _nearbyProfiles.first,
                                            onConnect: () => _handleConnect(_nearbyProfiles.first),
                                            onFavorite: () => _handleFavorite(_nearbyProfiles.first),
                                            onSkip: () => _handleSkip(_nearbyProfiles.first),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProfileScreen(user: _nearbyProfiles.first),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Large Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildCircularButton(Icons.close, Colors.grey[400]!, 50, () => _handleSkip(_nearbyProfiles.first)),
                                        const SizedBox(width: 12),
                                        _buildCircularButton(Icons.favorite, QaboolTheme.primary, 65, () => _handleConnect(_nearbyProfiles.first), isHeart: true),
                                        const SizedBox(width: 12),
                                        _buildCircularButton(Icons.star, const Color(0xFFFFB800), 50, () => _handleFavorite(_nearbyProfiles.first)),
                                      ],
                                    ),
                                  ],
                                );
                    }),
                    const SizedBox(height: 24),

                    // Who Liked You Section (Only on Desktop)
                    if (isLargeScreen && _likedMeProfiles.isNotEmpty) ...[
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
                                          Hero(
                                            tag: 'user_profile_${profile.id}',
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundImage: profile.profileImageUrl != null
                                                  ? CachedNetworkImageProvider(getVersionedImageUrl(profile.profileImageUrl, profile.updatedAt))
                                                  : null,
                                              child: profile.profileImageUrl == null
                                                  ? const Icon(Icons.person)
                                                  : null,
                                            ),
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

                  // Mobile-only Chat Section (Hidden based on user request)
                  if (MediaQuery.of(context).size.width <= 800)
                    const SizedBox.shrink(), 
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarConversations(bool isDark, Color pColor, Color bgDark, Color bgLight, Color neutralSoftUrlLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: () => widget.onNavigate?.call(2),
                tooltip: 'Go to Messages',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildRecentChats(isDark, pColor, bgDark, neutralSoftUrlLight),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChats(bool isDark, Color pColor, Color bgDark, Color neutralSoftUrlLight) {
    return Consumer2<ChatService, AuthService>(
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
          children: chats.take(MediaQuery.of(context).size.width > 800 ? 10 : 3).map((chat) {
            final otherUser = chat.otherParticipant(currentUserId);
            if (otherUser == null) return const SizedBox.shrink();
            return _buildChatItem(
              context: context,
              isDark: isDark,
              imageUrl: resolveImageUrl(otherUser.profileImageUrl),
              name: otherUser.fullName,
              time: chat.lastMessage?.timeString ?? 'No messages',
              message: chat.lastMessage?.content ?? '',
              isOnline: otherUser.isOnline,
              isUnread: false,
              accentColor: pColor,
              cardBgColor: isDark ? bgDark : Colors.white,
              borderColor: isDark ? const Color(0xFF1E293B) : neutralSoftUrlLight,
              onTap: () {
                if (MediaQuery.of(context).size.width > 800) {
                  chatService.toggleFloatingChat(chat.id, open: true, otherUser: otherUser);
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
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleConnect(UserModel profile) async {
    if (profile.connectionStatus == 'ACCEPTED') {
      try {
        final chatService = context.read<ChatService>();
        final chat = await chatService.createChat(profile.id);
        final isLargeScreen = MediaQuery.of(context).size.width > 800;
        if (isLargeScreen) {
          chatService.toggleFloatingChat(chat.id, open: true, otherUser: profile);
        } else if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chat.id,
                otherUser: profile,
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to open chat: $e")),
          );
        }
      }
    } else if (profile.connectionStatus == 'PENDING_RECEIVED') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: profile),
          ),
        );
      }
    } else {
      try {
        final connectionService = context.read<ConnectionService>();
        await connectionService.sendConnectionRequest(profile.id);
        if (mounted) {
          await _swipeAway(profile, right: true); // Connect = Swipe Right
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send request: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleFavorite(UserModel profile) async {
    final profileService = context.read<ProfileService>();
    final wasFavorited = profile.isFavorited;
    try {
      // Optimistic UI update: Toggle favorited status instead of removing
      setState(() {
        final index = _nearbyProfiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          _nearbyProfiles[index] = profile.copyWith(isFavorited: !wasFavorited);
        }
      });
      
      if (wasFavorited) {
        await profileService.unfavoriteUser(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed ${profile.firstName} from favorites')),
          );
        }
      } else {
        await profileService.favoriteUser(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${profile.firstName} to favorites!')),
          );
        }
      }
      
      // Removed _fetchProfiles(silent: true) to prevent grid flicker.
      // The optimistic UI update is sufficient and avoids jumping cards.
    } catch (e) {
      // Revert if API fails
      setState(() {
        final index = _nearbyProfiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          _nearbyProfiles[index] = profile.copyWith(isFavorited: wasFavorited);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _swipeAway(UserModel profile, {bool right = true}) async {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(right ? 2.0 : -2.0, 0.2), // Swipe right or left
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ));
    });

    await _animationController.forward();
    
    if (mounted) {
      setState(() {
        _nearbyProfiles.removeWhere((p) => p.id == profile.id);
        _animationController.reset();
        _isAnimating = false;
      });
    }
  }

  void _handleSkip(UserModel profile) async {
    await _swipeAway(profile, right: false); // Skip = Swipe Left
    if (!mounted) return;
    
    // Add to skipped list in ProfileService
    context.read<ProfileService>().skipUser(profile);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped ${profile.firstName}'),
        duration: const Duration(seconds: 1),
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
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person, color: isDark ? Colors.grey[600] : Colors.grey[400])
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

  Widget _buildTopIconButton(IconData icon, bool isDark, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildCircularButton(IconData icon, Color color, double size, VoidCallback onTap, {bool isHeart = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isHeart ? color : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isHeart ? color : Colors.black).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isHeart ? Colors.white : color,
          size: size * 0.45,
        ),
      ),
    );
  }
}
