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
    
    final profileService = context.watch<ProfileService>();
    
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
        backgroundColor:
            isDark ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QaboolTheme.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isMe)
            IconButton(
              icon: Icon(
                _displayUser!.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _displayUser!.isFavorited ? Colors.red : primaryColor,
              ),
              onPressed: () async {
                try {
                  if (_displayUser!.isFavorited) {
                    await profileService.unfavoriteUser(_displayUser!.id);
                  } else {
                    await profileService.favoriteUser(_displayUser!.id);
                  }
                  // Refresh profile to update local state
                  final updatedUser = await profileService.getProfile(_displayUser!.id);
                  if (mounted) {
                    setState(() {
                      _displayUser = updatedUser;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.settings, color: primaryColor),
              onPressed: () {},
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // Hero Section
            Container(
              color: isDark ? bgDark : Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 144,
                        height: 144,
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
                            imageUrl: _displayUser!.profileImageUrl ?? '',
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
                                constraints: const BoxConstraints(minHeight: 52),
                                child: const Text(
                                  'EDIT PROFILE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
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
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: const Icon(Icons.share, color: primaryColor),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final chatService = context.read<ChatService>();
                              final chat = await chatService.createChat(_displayUser!.id);
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
                                  SnackBar(content: Text('Failed to initiate chat: $e')),
                                );
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF800000), Color(0xFF4A0000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minHeight: 52),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    'CONNECT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Bio Section
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: const Icon(Icons.account_circle,
                                  color: primaryColor),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ABOUT ME',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: QaboolTheme.accentGold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayUser!.bio ?? (_isMe ? 'No bio added yet. Tell others bit about yourself!' : 'No bio provided.'),
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
                              child: const Icon(Icons.list_alt, color: primaryColor),
                            ),
                            const SizedBox(width: 8),
                            const Text(
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
                          icon: Icons.church,
                          label: 'RELIGION & CASTE',
                          value: '${_displayUser!.religion ?? "Not specified"}${_displayUser!.ethnicity != null ? ", ${_displayUser!.ethnicity}" : ""}',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  if (_isMe) ...[
                    const SizedBox(height: 32),
                    // Logout Button
                    OutlinedButton(
                      onPressed: () async {
                        await context.read<AuthService>().logout();
                        if (context.mounted) {
                          context.read<ChatService>().disconnectSocket();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 12),
                          Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
}
