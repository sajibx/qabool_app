import 'package:qabool_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection_model.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import '../theme.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<ConnectionService>().fetchConnections()
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectionService = context.watch<ConnectionService>();
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1616) : const Color(0xFFFDFCFB),
        appBar: AppBar(
          title: const Text('Connections', style: TextStyle(fontWeight: FontWeight.bold, color: QaboolTheme.primary)),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Connected'),
              Tab(text: 'Pending'),
            ],
            labelColor: QaboolTheme.primary,
            indicatorColor: QaboolTheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(connectionService.acceptedConnections, isPending: false),
            _buildList(connectionService.pendingRequests, isPending: true),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ConnectionModel> connections, {required bool isPending}) {
    if (connections.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending requests' : 'No connections yet',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        final currentUserId = context.read<AuthService>().currentUser?.id;
        
        final otherUser = connection.requester?.id == currentUserId 
            ? connection.recipient 
            : connection.requester;
        
        final isIncoming = connection.recipient?.id == currentUserId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: otherUser?.profileImageUrl != null 
                  ? CachedNetworkImageProvider(resolveImageUrl(otherUser!.profileImageUrl!)) 
                  : null,
              child: otherUser?.profileImageUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(otherUser?.fullName ?? 'Unknown'),
            subtitle: Text(isPending 
                ? (isIncoming ? 'Sent you a request' : 'Request pending') 
                : 'Connected'),
            onTap: () {
              if (otherUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: otherUser)),
                );
              }
            },
            trailing: isPending
                ? (isIncoming 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => context.read<ConnectionService>()
                                .respondToRequest(connection.id, ConnectionStatus.ACCEPTED),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => context.read<ConnectionService>()
                                .respondToRequest(connection.id, ConnectionStatus.REJECTED),
                          ),
                        ],
                      )
                    : const Text('Pending', style: TextStyle(color: Colors.orange)))
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
