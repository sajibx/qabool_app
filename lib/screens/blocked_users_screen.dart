import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/utils/image_utils.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    try {
      final users = await context.read<ProfileService>().getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching blocked users: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      await context.read<ProfileService>().unblockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked successfully')),
        );
        _fetchBlockedUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unblocking user: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFDFCFB),
      appBar: AppBar(
        title: const Text('Blocked Users', 
          style: TextStyle(fontWeight: FontWeight.bold, color: QaboolTheme.primary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: QaboolTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: user.profileImageUrl != null
                                ? CachedNetworkImageProvider(resolveImageUrl(user.profileImageUrl))
                                : null,
                            child: user.profileImageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${user.firstName} ${user.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (user.region != null)
                                  Text(user.region!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _unblockUser(user.id),
                            child: const Text('UNBLOCK',
                              style: TextStyle(
                                color: QaboolTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
