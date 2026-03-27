import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/connection_service.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/models/connection_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/screens/profile_screen.dart';
import 'package:qabool_app/widgets/user_list_tile.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => DiscoveryScreenState();
}

class DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  bool _isLoading = true;
  List<UserModel> _favorites = [];
  List<UserModel> _passed = [];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    refreshData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    if (mounted) setState(() => _isLoading = true);
    final profileService = context.read<ProfileService>();
    final connectionService = context.read<ConnectionService>();
    try {
      final results = await Future.wait([
        profileService.getMyFavorites(),
        profileService.getSkippedUsers(),
        connectionService.fetchConnections(),
      ]);
      if (mounted) {
        setState(() {
          _favorites = results[0] as List<UserModel>;
          _passed = results[1] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silently handle error or show snackbar occasionally 
      }
    }
  }

  // Action Handlers
  Future<void> _handleConnect(UserModel profile) async {
    try {
      if (profile.connectionStatus == 'ACCEPTED') {
        final chatService = context.read<ChatService>();
        final chat = await chatService.createChat(profile.id);
        if (mounted) {
          final isLargeScreen = MediaQuery.of(context).size.width > 800;
          if (isLargeScreen) {
             chatService.toggleFloatingChat(chat.id, open: true, otherUser: profile);
          } else {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat.id, otherUser: profile)));
          }
        }
      } else {
        await context.read<ConnectionService>().sendConnectionRequest(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
          refreshData();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleFavorite(UserModel profile) async {
    final profileService = context.read<ProfileService>();
    try {
      if (profile.isFavorited) {
        await profileService.unfavoriteUser(profile.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${profile.firstName} from favorites')));
      } else {
        await profileService.favoriteUser(profile.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${profile.firstName} to favorites!')));
      }
      refreshData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleSkip(UserModel profile) async {
    final profileService = context.read<ProfileService>();
    try {
      await profileService.skipUser(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Skipped ${profile.firstName}')));
        refreshData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleAcceptRequest(String connectionId) async {
    try {
      await context.read<ConnectionService>().respondToRequest(connectionId, ConnectionStatus.ACCEPTED);
      refreshData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  Future<void> _handleRejectRequest(String connectionId) async {
    try {
      await context.read<ConnectionService>().respondToRequest(connectionId, ConnectionStatus.REJECTED);
      refreshData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
    }
  }

  Future<void> _handleUnskip(UserModel profile) async {
    try {
      await context.read<ProfileService>().unskipUser(profile.id);
      refreshData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error unskipping user: $e')));
    }
  }

  Future<void> _handleRemoveConnection(UserModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection?'),
        content: Text('Are you sure you want to remove your connection with ${profile.firstName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final connections = context.read<ConnectionService>().connections;
        final auth = context.read<AuthService>();
        final currentUserId = auth.currentUser?.id;
        
        // Find the active ACCEPTED connection for this user
        final conn = connections.firstWhere((c) => 
          c.status == ConnectionStatus.ACCEPTED && 
          (c.requester?.id == profile.id || c.recipient?.id == profile.id)
        );

        await context.read<ConnectionService>().respondToRequest(conn.id, ConnectionStatus.REJECTED);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection with ${profile.firstName} removed.')));
          refreshData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing connection: $e')));
      }
    }
  }

  // Build Helpers
  Widget _buildList(List<UserModel> users, {
    String emptyMessage = "No users found",
    void Function(UserModel)? customOnConnect,
    void Function(UserModel)? customOnSkip,
  }) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return Center(child: Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)));

    return RefreshIndicator(
      onRefresh: refreshData,
      color: QaboolTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8), // tile margin handles horizontal space
        itemCount: users.length,
        itemBuilder: (context, index) {
          final profile = users[index];
          return UserListTile(
            user: profile,
            onConnect: () => customOnConnect != null ? customOnConnect(profile) : _handleConnect(profile),
            onFavorite: () => _handleFavorite(profile),
            onSkip: () => customOnSkip != null ? customOnSkip(profile) : _handleSkip(profile),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: profile)));
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const pColor = QaboolTheme.primary;
    const bgDark = QaboolTheme.backgroundDark;
    const bgLight = QaboolTheme.backgroundLight;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: isDark ? bgDark : bgLight,
        elevation: 0,
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: pColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: pColor,
          indicatorWeight: 3,
          dividerColor: isDark ? Colors.white10 : Colors.black12,
          tabs: const [
            Tab(text: "My History"),
            Tab(text: "Ready to Qabool"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildMyHistoryTab(isDark, pColor),
          _buildReadyToQaboolTab(isDark, pColor),
        ],
      ),
    );
  }

  Widget _buildMyHistoryTab(bool isDark, Color pColor) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: isDark ? Colors.black12 : Colors.grey[50],
            child: TabBar(
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: pColor,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Favorites"),
                Tab(text: "Liked"),
                Tab(text: "Passed"),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<AuthService, ConnectionService>(
              builder: (context, auth, connections, child) {
                final currentUserId = auth.currentUser?.id;
                
                final likedUsers = currentUserId == null ? <UserModel>[] : connections.connections
                    .where((c) => c.status == ConnectionStatus.PENDING && c.requester?.id == currentUserId)
                    .map((c) => c.recipient)
                    .whereType<UserModel>()
                    .toList();

                return TabBarView(
                  children: [
                    _buildList(_favorites, emptyMessage: "No favorites yet"),
                    _buildList(likedUsers, emptyMessage: "No sent requests"),
                    _buildList(
                      _passed, 
                      emptyMessage: "No passed users",
                      customOnSkip: (u) => _handleUnskip(u),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToQaboolTab(bool isDark, Color pColor) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: isDark ? Colors.black12 : Colors.grey[50],
            child: TabBar(
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: pColor,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Mutual"),
                Tab(text: "Received"),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<AuthService, ConnectionService>(
              builder: (context, auth, connections, child) {
                final currentUserId = auth.currentUser?.id;

                final mutualUsers = currentUserId == null ? <UserModel>[] : connections.connections
                    .where((c) => c.status == ConnectionStatus.ACCEPTED)
                    .map((c) => c.requester?.id == currentUserId ? c.recipient : c.requester)
                    .whereType<UserModel>()
                    .toList();

                final receivedConnections = currentUserId == null ? <ConnectionModel>[] : connections.connections
                    .where((c) => c.status == ConnectionStatus.PENDING && c.recipient?.id == currentUserId)
                    .toList();
                    
                final receivedUsers = receivedConnections.map((c) => c.requester).whereType<UserModel>().toList();

                return TabBarView(
                  children: [
                    _buildList(
                      mutualUsers, 
                      emptyMessage: "No mutual connections yet",
                      customOnSkip: (u) => _handleRemoveConnection(u),
                    ),
                    _buildList(
                      receivedUsers, 
                      emptyMessage: "No received requests",
                      customOnConnect: (u) {
                         final conn = receivedConnections.firstWhere((c) => c.requester?.id == u.id);
                         _handleAcceptRequest(conn.id);
                      },
                      customOnSkip: (u) {
                         final conn = receivedConnections.firstWhere((c) => c.requester?.id == u.id);
                         _handleRejectRequest(conn.id);
                      }
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
