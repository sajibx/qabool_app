import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qabool_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/services/auth_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/screens/edit_profile_screen.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/connection_service.dart';
import 'package:qabool_app/screens/connections_screen.dart';
import 'package:qabool_app/screens/favorites_screen.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:qabool_app/models/connection_model.dart' as v_conn;

class ProfileScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel? _displayUser;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _displayUser = widget.user;
    
    // Always refresh profile from server to ensure full details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _displayUser != null) {
        _refreshProfile();
      }
    });
  }

  Future<void> _refreshProfile() async {
    if (_displayUser == null) return;
    try {
      final updatedUser = await context.read<ProfileService>().getProfile(_displayUser!.id);
      if (mounted) {
        setState(() {
          _displayUser = updatedUser;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final currentUser = auth.currentUser;
    
    if (_displayUser == null && currentUser != null) {
      _displayUser = currentUser;
    }
    
    _isMe = _displayUser?.id == currentUser?.id;
    
    const primaryColor = QaboolTheme.primary; // Maroon
    const accentGold = QaboolTheme.accentGold; // Gold
    const bgDark = Color(0xFF1A1616);

    if (_displayUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? bgDark : const Color(0xFFFDFCFB),
      appBar: AppBar(
        title: _isMe
            ? const Text(
                'My Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: QaboolTheme.primary,
                ),
              )
            : null,
        centerTitle: true,
        automaticallyImplyLeading: !_isMe,
        backgroundColor:
            isDark ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (!_isMe)
            _buildFavoriteButton(isDark, primaryColor),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;

          if (isLargeScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side (Details & Content) - Moved from right
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: _buildContentSections(isDark, primaryColor, accentGold),
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: primaryColor.withOpacity(0.1),
                ),
                // Right Side (Profile Hero & Activity) - Moved from left
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Column(
                      children: [
                        _buildHeroSection(isDark, bgDark, primaryColor, accentGold),
                        const SizedBox(height: 48),
                        _buildActivitySection(isDark, primaryColor, accentGold),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                _buildHeroSection(isDark, bgDark, primaryColor, accentGold),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContentSections(isDark, primaryColor, accentGold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteButton(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final previousState = _displayUser!.isFavorited;
          final pService = context.read<ProfileService>();
          try {
            setState(() {
              _displayUser = _displayUser!.copyWith(isFavorited: !previousState);
            });
            if (previousState) {
              await pService.unfavoriteUser(_displayUser!.id);
            } else {
              await pService.favoriteUser(_displayUser!.id);
            }
            final updatedUser = await pService.getProfile(_displayUser!.id);
            if (mounted) {
              setState(() {
                _displayUser = updatedUser;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _displayUser = _displayUser!.copyWith(isFavorited: previousState);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(
              color: _displayUser!.isFavorited 
                ? const Color(0xFFFF7074).withOpacity(0.2) 
                : (isDark ? Colors.white10 : Colors.black12),
              width: 1,
            ),
          ),
          child: Icon(
            _displayUser!.isFavorited ? Icons.favorite : Icons.favorite_border,
            color: _displayUser!.isFavorited ? const Color(0xFFFF7074) : primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark, Color bgDark, Color primaryColor, Color accentGold) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    QaboolTheme.primary,
                    QaboolTheme.accentGold,
                    QaboolTheme.primary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: resolveImageUrl(_displayUser!.profileImageUrl),
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
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              ),
            ),
            if (_isMe)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF800000), Color(0xFF4A0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: isDark ? bgDark : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '${_displayUser!.fullName}${_displayUser!.age != null ? ", ${_displayUser!.age}" : ""}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.grey[100] : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              _displayUser!.region ?? 'No location added',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_isMe)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: primaryColor.withOpacity(0.2),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF800000), Color(0xFF4A0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 44),
                      child: const Text(
                        'EDIT PROFILE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: primaryColor.withOpacity(0.2), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Icon(Icons.share, color: primaryColor, size: 20),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              if (_displayUser!.connectionStatus == 'PENDING_RECEIVED')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.respondToRequest(
                                _displayUser!.connectionId!,
                                v_conn.ConnectionStatus.ACCEPTED);
                            if (mounted) {
                              setState(() {
                                _displayUser = _displayUser!.copyWith(
                                    connectionStatus: 'ACCEPTED');
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to accept: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('ACCEPT',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.respondToRequest(
                                _displayUser!.connectionId!,
                                v_conn.ConnectionStatus.REJECTED);
                            if (mounted) {
                              setState(() {
                                _displayUser = _displayUser!.copyWith(
                                    connectionStatus: 'NONE');
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to reject: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('REJECT',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: (_displayUser!.connectionStatus == 'PENDING_SENT' || _displayUser!.connectionStatus == 'PENDING')
                      ? () async {
                          // CANCEL REQUEST
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.respondToRequest(
                                _displayUser!.connectionId!,
                                v_conn.ConnectionStatus.REJECTED);
                            if (mounted) {
                              setState(() {
                                _displayUser = _displayUser!.copyWith(
                                    connectionStatus: 'NONE');
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to cancel request: $e')),
                              );
                            }
                          }
                        }
                      : () async {
                          if (_displayUser!.connectionStatus == 'ACCEPTED') {
                            try {
                              final chatService = context.read<ChatService>();
                              final chat = await chatService
                                  .createChat(_displayUser!.id);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chat.id,
                                      otherUser: _displayUser!,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to open chat: $e')),
                                );
                              }
                            }
                          } else {
                            try {
                              final connectionService =
                                  context.read<ConnectionService>();
                              await connectionService
                                  .sendConnectionRequest(_displayUser!.id);
                              if (mounted) {
                                setState(() {
                                  _displayUser = _displayUser!.copyWith(
                                      connectionStatus: 'PENDING_SENT');
                                });
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Connection request sent!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to send request: $e')),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: primaryColor.withOpacity(0.2),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _displayUser!.connectionStatus == 'ACCEPTED'
                            ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                            : ((_displayUser!.connectionStatus == 'PENDING_SENT' || _displayUser!.connectionStatus == 'PENDING')
                                ? [Colors.grey, Colors.grey]
                                : [const Color(0xFF800000), const Color(0xFF4A0000)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _displayUser!.connectionStatus == 'ACCEPTED'
                                ? Icons.chat_bubble
                                : (_displayUser!.connectionStatus == 'PENDING_RECEIVED' 
                                    ? Icons.check_circle_outline 
                                    : Icons.chat_bubble_outline),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _displayUser!.connectionStatus == 'ACCEPTED'
                                ? 'MESSAGE'
                                : (_displayUser!.connectionStatus == 'PENDING_RECEIVED'
                                    ? 'RESPOND'
                                    : (_displayUser!.connectionStatus == 'PENDING_SENT' || _displayUser!.connectionStatus == 'PENDING'
                                        ? 'CANCEL REQUEST'
                                        : 'CONNECT')),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_displayUser!.connectionStatus == 'ACCEPTED') ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Connection'),
                        content: const Text('Are you sure you want to remove this connection?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true), 
                            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        final connectionService = context.read<ConnectionService>();
                        await connectionService.respondToRequest(
                            _displayUser!.connectionId!,
                            v_conn.ConnectionStatus.REJECTED);
                        if (mounted) {
                          setState(() {
                            _displayUser = _displayUser!.copyWith(
                                connectionStatus: 'NONE');
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to remove connection: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'REMOVE CONNECTION',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildContentSections(bool isDark, Color primaryColor, Color accentGold) {
    return Column(
      children: [
                  // Bio Section
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.account_circle,
                          title: 'ABOUT ME',
                          accentGold: QaboolTheme.accentGold,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayUser!.bio ??
                              (_isMe
                                  ? 'No bio added yet. Tell others bit about yourself!'
                                  : 'No bio provided.'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Details
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Icon(Icons.list_alt, color: primaryColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PERSONAL DETAILS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: accentGold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.school,
                          label: 'EDUCATION',
                          value: _displayUser!.education ?? 'Not specified',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.work,
                          label: 'PROFESSION',
                          value: _displayUser!.profession ?? 'Not specified',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.height,
                          label: 'HEIGHT',
                          value: _displayUser!.height != null ? "${_displayUser!.height} cm" : 'Not specified',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.monitor_weight,
                          label: 'WEIGHT',
                          value: _displayUser!.weight != null ? "${_displayUser!.weight!.toStringAsFixed(1)} kg" : 'Not specified',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.church,
                          label: 'RELIGION & CASTE',
                          value: '${_displayUser!.religion ?? "Not specified"}${_displayUser!.ethnicity != null ? ", ${_displayUser!.ethnicity}" : ""}',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        if (_displayUser!.specialConsiderations != null && _displayUser!.specialConsiderations!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildDetailRow(
                            icon: Icons.info_outline,
                            label: 'SPECIAL CONSIDERATIONS',
                            value: _displayUser!.specialConsiderations!,
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isMe) ...[
                    const SizedBox(height: 32),
                    // Logout Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await context.read<AuthService>().logout();
                          if (context.mounted) {
                            context.read<ChatService>().disconnectSocket();
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (route) => false);
                          }
                        },
                        icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
            );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: QaboolTheme.primary.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accentGold,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: accentGold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String label,
    int? count,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 28),
                if (count != null && count > 0)
                  Positioned(
                    top: -5,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(bool isDark, Color primaryColor, Color accentGold) {
    if (!_isMe) return const SizedBox.shrink();
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.flash_on,
          title: 'MY ACTIVITY',
          accentGold: QaboolTheme.accentGold,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                icon: Icons.people_outline,
                label: 'Connections',
                count: context
                    .watch<ConnectionService>()
                    .pendingRequests
                    .length,
                color: Colors.blueAccent,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ConnectionsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityCard(
                icon: Icons.favorite_border,
                label: 'Favorites',
                color: const Color(0xFFFF7074),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
