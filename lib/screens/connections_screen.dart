import 'package:qabool_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../theme.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => 
      context.read<ConnectionService>().fetchConnections()
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectionService = context.watch<ConnectionService>();
    final primaryColor = QaboolTheme.primary;
    
    return Scaffold(
      backgroundColor: isDark ? QaboolTheme.backgroundDark : QaboolTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? QaboolTheme.backgroundDark : QaboolTheme.backgroundLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'My Network', 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 24,
                  letterSpacing: -1,
                  color: isDark ? Colors.white : QaboolTheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: isDark ? Colors.white : primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : primaryColor).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.black : Colors.white,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Connected'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(connectionService.acceptedConnections, isPending: false),
                _buildList(connectionService.pendingRequests, isPending: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ConnectionModel> connections, {required bool isPending}) {
    if (connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: QaboolTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.auto_awesome_rounded : Icons.people_rounded,
                size: 64,
                color: QaboolTheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPending ? 'No pending requests' : 'Start connecting!',
              style: TextStyle(
                color: Colors.grey[isPending ? 500 : 400],
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending 
                ? 'Check back later for new interests' 
                : 'Browse profiles and send requests',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ConnectionService>().fetchConnections(),
      color: QaboolTheme.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      edgeOffset: 20,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final connection = connections[index];
          final currentUserId = context.read<AuthService>().currentUser?.id;
          
          final otherUser = connection.requester?.id == currentUserId 
              ? connection.recipient 
              : connection.requester;
          
          final isIncoming = connection.recipient?.id == currentUserId;
          
          return _buildConnectionCard(
            connection, 
            otherUser, 
            isPending, 
            isIncoming,
            Theme.of(context).brightness == Brightness.dark,
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(
    ConnectionModel connection, 
    UserModel? otherUser, 
    bool isPending, 
    bool isIncoming,
    bool isDark,
  ) {
    final primaryColor = QaboolTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF64748B).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (otherUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: otherUser)),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with animated-like ring
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.4),
                              primaryColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                          backgroundImage: otherUser?.profileImageUrl != null 
                              ? CachedNetworkImageProvider(resolveImageUrl(otherUser!.profileImageUrl!)) 
                              : null,
                          child: otherUser?.profileImageUrl == null 
                              ? Icon(Icons.person_rounded, size: 44, color: Colors.grey[400]) 
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUser?.fullName ?? 'Anonymous Match',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: primaryColor.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    otherUser?.region ?? 'Location hidden',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!isPending)
                              _buildBadge(
                                'CONNECTED', 
                                const Color(0xFF10B981).withOpacity(0.12), 
                                const Color(0xFF10B981),
                              )
                            else if (isIncoming)
                              _buildBadge(
                                'INCOMING', 
                                primaryColor.withOpacity(0.12), 
                                primaryColor,
                              )
                            else
                              _buildBadge(
                                'REQUEST SENT', 
                                const Color(0xFFF59E0B).withOpacity(0.12), 
                                const Color(0xFFD97706),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Divider(
                    height: 1, 
                    thickness: 1, 
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)
                  ),
                  const SizedBox(height: 20),
                  
                  if (isPending && isIncoming)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Decline',
                            isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            isDark ? Colors.white70 : Colors.black87,
                            () => context.read<ConnectionService>()
                                .respondToRequest(connection.id, ConnectionStatus.REJECTED),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            'Accept',
                            primaryColor,
                            Colors.white,
                            () => context.read<ConnectionService>()
                                .respondToRequest(connection.id, ConnectionStatus.ACCEPTED),
                          ),
                        ),
                      ],
                    )
                  else if (isPending && !isIncoming)
                    _buildActionButton(
                      'Withdraw Request',
                      isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      isDark ? Colors.white70 : Colors.black87,
                      () => context.read<ConnectionService>()
                          .respondToRequest(connection.id, ConnectionStatus.REJECTED),
                      icon: Icons.cancel_outlined,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildActionButton(
                            'Send Message',
                            primaryColor.withOpacity(0.12),
                            primaryColor,
                            () async {
                              if (otherUser != null) {
                                final chat = await context.read<ChatService>().createChat(otherUser.id);
                                if (mounted) {
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
                              }
                            },
                            icon: Icons.chat_bubble_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildActionButton(
                            'Remove',
                            isDark ? const Color(0x1FFF4444) : const Color(0xFFFFEBEE),
                            Colors.redAccent,
                            () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Text('Remove connection?', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Text('Are you sure you want to remove ${otherUser?.firstName ?? "this member"}? You can always reconnect later.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false), 
                                      child: Text('KEEP', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true), 
                                      child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (mounted) {
                                  context.read<ConnectionService>().respondToRequest(connection.id, ConnectionStatus.REJECTED);
                                }
                              }
                            },
                            icon: Icons.remove_circle_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label, 
    Color bgColor, 
    Color textColor, 
    VoidCallback onPressed,
    {IconData? icon}
  ) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
