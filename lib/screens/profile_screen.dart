import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'blocked_users_screen.dart';
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
import 'package:qabool_app/screens/skipped_screen.dart';
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
  bool _isRefreshing = false;
  int _skippedCount = 0;
  String _activeDesktopSection = 'hero'; // 'hero', 'connections', 'favorites', 'skipped'

  @override
  void initState() {
    super.initState();
    _displayUser = widget.user;
    
    // Always refresh profile from server to ensure full details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _displayUser != null) {
        setState(() => _isRefreshing = true);
        _refreshProfile();
      }
    });

    _fetchSkippedCount();
  }

  Future<void> _fetchSkippedCount() async {
    try {
      final users = await context.read<ProfileService>().getSkippedUsers();
      if (mounted) setState(() => _skippedCount = users.length);
    } catch (e) {
      debugPrint('Error fetching skipped count: $e');
    }
  }

  Future<void> _refreshProfile() async {
    if (_displayUser == null) return;
    try {
      final updatedUser = await context.read<ProfileService>().getProfile(_displayUser!.id);
      if (mounted) {
        setState(() {
          _displayUser = updatedUser;
        });
        
        // If this is my profile, update the global AuthService as well
        if (_isMe && updatedUser != null) {
          await context.read<AuthService>().updateCurrentUser(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final currentUser = auth.currentUser;
    
    // Determine if it's my profile
    _isMe = widget.user == null || (currentUser != null && widget.user?.id == currentUser.id);

    // If it's my profile, always use the latest user data from AuthService (which we are watching)
    if (_isMe && currentUser != null) {
      if (_displayUser != currentUser) {
        debugPrint('ProfileScreen: Updating _displayUser from AuthService. New image: ${currentUser.profileImageUrl}');
        _displayUser = currentUser;
      }
    } else {
      _displayUser ??= widget.user;
    }
    
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, // Custom leading
        leading: !_isMe ? Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ) : null,
        actions: [
          if (!_isMe)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFavoriteButton(isDark, Colors.white),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      onSelected: (value) async {
                        if (value == 'block') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Block User?'),
                              content: Text('Are you sure you want to block ${_displayUser!.firstName}? They will no longer be able to see your profile or message you.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('BLOCK', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && mounted) {
                            try {
                              await context.read<ProfileService>().blockUser(_displayUser!.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${_displayUser!.firstName} blocked.')),
                                );
                                Navigator.pop(context); // Go back after blocking
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error blocking user: $e')),
                                );
                              }
                            }
                          }
                        } else if (value == 'report') {
                          await _showReportDialog();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('Block User'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                              SizedBox(width: 10),
                              Text('Report User'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    child: IconButton(
                      icon: const Icon(Icons.block, color: Colors.white, size: 20),
                      tooltip: 'Blocked Users',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BlockedUsersScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await context.read<AuthService>().logout();
                          if (context.mounted) {
                            context.read<ChatService>().disconnectSocket();
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
                        },
                      ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side (Details & Content) - Moved from right
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: _buildContentSections(isDark, primaryColor, accentGold, showRequirements: false),
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
                  child: Column(
                    children: [
                      if (_activeDesktopSection == 'hero')
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 0, bottom: 40),
                            child: Column(
                                children: [
                                  _buildHeroSection(isDark, bgDark, primaryColor, accentGold),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: _buildRequirementsSection(isDark, primaryColor, accentGold),
                                  ),
                                ],
                            ),
                          ),
                        )
                      else if (_activeDesktopSection == 'connections')
                        Expanded(
                          child: ConnectionsScreen(
                            isEmbedded: true,
                            onBack: () => setState(() => _activeDesktopSection = 'hero'),
                          ),
                        )
                      else if (_activeDesktopSection == 'favorites')
                        Expanded(
                          child: FavoritesScreen(
                            isEmbedded: true,
                            onBack: () => setState(() => _activeDesktopSection = 'hero'),
                          ),
                        )
                      else if (_activeDesktopSection == 'skipped')
                        Expanded(
                          child: SkippedScreen(
                            isEmbedded: true,
                            onBack: () => setState(() => _activeDesktopSection = 'hero'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, bottom: 40),
            child: Column(
              children: [
                _buildHeroSection(isDark, bgDark, primaryColor, accentGold),
                // if (_isMe) ...[
                //   const SizedBox(height: 16),
                //   Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 24),
                //     child: _buildActivitySection(isDark, primaryColor, accentGold),
                //   ),
                // ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _buildContentSections(isDark, primaryColor, accentGold, showRequirements: true),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteButton(bool isDark, Color iconColor) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final previousState = _displayUser!.isFavorited;
        final pService = context.read<ProfileService>();
        try {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(previousState ? 'Removed from favorites' : 'Added to favorites!'),
                backgroundColor: previousState ? Colors.grey[800] : const Color(0xFFFFB800),
              ),
            );
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
      child: Icon(
        _displayUser!.isFavorited ? Icons.star : Icons.star_border,
        color: _displayUser!.isFavorited ? const Color(0xFFFFB800) : iconColor,
        size: 20,
      ),
    );
  }

  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Report User', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please describe why you are reporting ${_displayUser!.firstName}. Your report will be reviewed by our team.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'e.g. Inappropriate behavior, fake profile...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide a reason for your report.';
                    }
                    if (val.trim().length < 10) {
                      return 'Reason must be at least 10 characters.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.flag, size: 16),
              label: const Text('REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      final reason = reasonController.text.trim();
      try {
        await context.read<ProfileService>().reportUser(_displayUser!.id, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text('${_displayUser!.firstName} has been reported. Thank you.'),
                ],
              ),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final message = e.toString().contains('already reported')
              ? 'You have already reported ${_displayUser!.firstName}.'
              : 'Failed to submit report: $e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.grey[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
  Widget _buildHeroSection(bool isDark, Color bgDark, Color primaryColor, Color accentGold) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.76,
          width: double.infinity,
          child: Stack(
            children: [
              // Full Cover Image
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.76,
                  minWidth: double.infinity,
                ),
                child: CachedNetworkImage(
                  key: ValueKey(getVersionedImageUrl(_displayUser!.profileImageUrl, _displayUser!.updatedAt)),
                  imageUrl: getVersionedImageUrl(_displayUser!.profileImageUrl, _displayUser!.updatedAt),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    debugPrint('CachedNetworkImage ERROR: $error for URL: $url');
                    return Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(Icons.person,
                          size: 100,
                          color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    );
                  },
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.1, 0.7, 1.0],
                    )
                  )
                )
              ),

              // User Info Title (Bottom left)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_displayUser!.verifiedStatus == 'active')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF3498DB), size: 18),
                                const SizedBox(width: 4),
                                const Text('Verified',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${_displayUser!.firstName}, ${_displayUser!.age ?? ""}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF2ECC71), width: 3),
                                ),
                              )
                            ]
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _displayUser!.region ?? 'No location added',
                                style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: _displayUser!.interests.map((interest) => 
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildInterestTag(interest, _getInterestIcon(interest)),
                          )
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_isMe) ...[
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (!_isMe)
          Container(
            margin: const EdgeInsets.only(top: 12, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : QaboolTheme.primary.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: QaboolTheme.primary.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayUser!.connectionStatus == 'ACCEPTED' ? 'Match Found!' :
                        _displayUser!.connectionStatus == 'PENDING_RECEIVED' ? 'Pending Request' :
                        'Ready to Qabool?',
                        style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w800, 
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayUser!.connectionStatus == 'ACCEPTED' ? 'You are connected.' :
                        _displayUser!.connectionStatus == 'PENDING_RECEIVED' ? 'They want to connect.' :
                        'Is ${_displayUser?.gender?.toLowerCase() == 'male' ? 'he' : 'she'} your perfect match?',
                        style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRefreshing && _displayUser!.connectionStatus == 'NONE')
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    else if (_displayUser!.connectionStatus == 'PENDING_RECEIVED') ...[
                      // Reject
                      GestureDetector(
                        onTap: () async {
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.respondToRequest(
                                _displayUser!.connectionId!,
                                v_conn.ConnectionStatus.REJECTED);
                            if (mounted) setState(() => _displayUser = _displayUser!.copyWith(connectionStatus: 'NONE'));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: QaboolTheme.primary, 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: QaboolTheme.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept
                      GestureDetector(
                        onTap: () async {
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.respondToRequest(
                                _displayUser!.connectionId!,
                                v_conn.ConnectionStatus.ACCEPTED);
                            if (mounted) setState(() => _displayUser = _displayUser!.copyWith(connectionStatus: 'ACCEPTED'));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71), 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 24),
                        ),
                      ),
                    ]
                    else if (_displayUser!.connectionStatus == 'ACCEPTED') ...[
                      // Remove Connection
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Connection'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('REMOVE', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              final connectionService = context.read<ConnectionService>();
                              await connectionService.respondToRequest(
                                  _displayUser!.connectionId!,
                                  v_conn.ConnectionStatus.REJECTED);
                              if (mounted) setState(() => _displayUser = _displayUser!.copyWith(connectionStatus: 'NONE'));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800], 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.person_remove, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Message
                      GestureDetector(
                        onTap: () async {
                            try {
                              final chatService = context.read<ChatService>();
                              final chat = await chatService.createChat(_displayUser!.id);
                              if (context.mounted) {
                                final isLargeScreen = MediaQuery.of(context).size.width > 800;
                                if (isLargeScreen) {
                                  chatService.toggleFloatingChat(chat.id, open: true, otherUser: _displayUser!);
                                } else {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.id, otherUser: _displayUser!)));
                                }
                              }
                            } catch (e) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71), 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                        ),
                      ),
                    ]
                    else if (_displayUser!.connectionStatus == 'PENDING_SENT' || _displayUser!.connectionStatus == 'PENDING') ...[
                      // Sent Request Actions
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Request?'),
                                content: Text('Are you sure you want to cancel your connection request to ${_displayUser?.firstName ?? 'this user'}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('CANCEL REQUEST', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              try {
                                final connectionService = context.read<ConnectionService>();
                                final cid = _displayUser?.connectionId;
                                if (cid != null) {
                                  await connectionService.cancelConnectionRequest(cid);
                                  if (mounted) {
                                    setState(() => _displayUser = _displayUser!.copyWith(connectionStatus: 'NONE'));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request cancelled.')));
                                  }
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
                               }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CANCEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time, color: Colors.grey[600], size: 18),
                      ),
                    ]
                    else ...[
                      // Default Actions (NONE)
                      GestureDetector(
                        onTap: () async {
                          try {
                            final profileService = context.read<ProfileService>();
                            await profileService.skipUser(_displayUser!);
                            if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User passed.')));
                            }
                          } catch (e) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E), 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF43F5E).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          final currentUser = context.read<AuthService>().currentUser;
                          if (currentUser?.verifiedStatus != 'active') {
                             showDialog(
                               context: context,
                               builder: (context) => AlertDialog(
                                 title: const Text('Profile Verification Required'),
                                 content: const Text('Your profile must be verified by an admin before you can send connection requests. Please wait for verification.'),
                                 actions: [
                                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                 ],
                               ),
                             );
                             return;
                          }
                          try {
                            final connectionService = context.read<ConnectionService>();
                            await connectionService.sendConnectionRequest(_displayUser!.id);
                            if (mounted) {
                              // We should refresh profile to get the connectionId
                              await _refreshProfile();
                            }
                          } catch (e) {
                             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: QaboolTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: QaboolTheme.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(Icons.favorite_border, color: Colors.white, size: 24),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContentSections(bool isDark, Color primaryColor, Color accentGold, {bool showRequirements = true}) {
    final cardBg = isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08);
    final sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white : const Color(0xFF1E293B),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Me
        Text('About Me', style: sectionTitleStyle),
        const SizedBox(height: 8),
        Text(
          _displayUser!.bio ?? (_isMe ? 'No bio added yet.' : 'No bio provided.'),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Info Grid
        LayoutBuilder(builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.7,
            crossAxisSpacing: 12.7,
            childAspectRatio: 3.44,
            children: [
              _buildInfoCard(Icons.wc, 'GENDER', _displayUser!.gender ?? 'Not set', isDark),
              _buildInfoCard(Icons.cake, 'AGE', _displayUser!.displayAge > 0 ? _displayUser!.displayAge.toString() : 'Not set', isDark),
              _buildInfoCard(Icons.favorite_border, 'MARITAL STATUS', _displayUser!.maritalStatus ?? 'Not set', isDark),
              _buildInfoCard(Icons.monitor_weight_outlined, 'WEIGHT', _displayUser!.weight != null ? '${_displayUser!.weight}kg' : 'Not set', isDark),
              _buildInfoCard(Icons.height, 'HEIGHT', _displayUser!.height != null ? '${_displayUser!.height}cm' : 'Not set', isDark),
              _buildInfoCard(Icons.location_city, 'CURRENT CITY', _displayUser!.currentCity ?? 'Not set', isDark),
              _buildInfoCard(Icons.school_outlined, 'EDUCATION', _displayUser!.education ?? 'Not set', isDark),
              _buildInfoCard(Icons.mosque_outlined, 'RELIGION', _displayUser!.religion ?? 'Not set', isDark),
              _buildInfoCard(Icons.account_balance, 'SECT', _displayUser!.sect ?? 'Not set', isDark),
              _buildInfoCard(Icons.groups_outlined, 'CASTE', _displayUser!.caste ?? 'Not set', isDark),
              _buildInfoCard(Icons.payments_outlined, 'MONTHLY INCOME', _displayUser!.monthlyIncome != null ? '€${_displayUser!.monthlyIncome}' : 'Not set', isDark),
              _buildInfoCard(Icons.work_outline, 'PROFESSION', _displayUser!.profession ?? 'Not set', isDark),
              _buildInfoCard(Icons.people_outline, 'SIBLINGS', _displayUser!.siblings?.toString() ?? 'Not set', isDark),
              _buildInfoCard(Icons.family_restroom_outlined, 'FAMILY MEMBERS', _displayUser!.familyMembers?.toString() ?? 'Not set', isDark),
            ],
          );
        }),
        const SizedBox(height: 24),

        if (showRequirements) ...[
          _buildRequirementsSection(isDark, primaryColor, accentGold),
          const SizedBox(height: 24),
        ],

        // Partner Preference & Past Issues Indicators
        _buildStatusIndicator(
          'Partner Preference',
          'Willing to accept a partner with past issues: ${_displayUser!.acceptsPastIssues ? 'Yes' : 'No'}',
          _displayUser!.acceptsPastIssues ? Icons.check_circle_outline : Icons.cancel_outlined,
          _displayUser!.acceptsPastIssues ? Colors.green : Colors.orange,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildStatusIndicator(
          'Personal History',
          'Has past issues: ${_displayUser!.hasPastIssues ? 'Yes' : 'No'}',
          _displayUser!.hasPastIssues ? Icons.history_edu_outlined : Icons.info_outline,
          _displayUser!.hasPastIssues ? Colors.orange : Colors.blue,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String title, String subtitle, IconData icon, Color accentColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : QaboolTheme.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : QaboolTheme.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: QaboolTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, String value, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: QaboolTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: QaboolTheme.primary, size: 14),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection(bool isDark, Color primaryColor, Color accentGold) {
    final sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white : const Color(0xFF1E293B),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isMe ? 'Your requirements' : 'Requirements', style: sectionTitleStyle),
              if (_isMe) Icon(Icons.edit_note, color: QaboolTheme.primary, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementItem('LOOKING FOR', _displayUser!.lookingForType ?? 'Not set', true),
          _buildRequirementItem('AGE', _displayUser!.lookingForAge ?? 'Not set', true),
          _buildRequirementItem('EDUCATION', _displayUser!.lookingForProfession ?? 'Not set', true),
        ],
      ),
    );
  }

  Widget _buildInterestTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInterestIcon(String interest) {
    switch (interest.toLowerCase()) {
      case 'cooking':
        return Icons.restaurant;
      case 'traveling':
        return Icons.flight_takeoff;
      case 'reading':
        return Icons.menu_book;
      case 'coding':
        return Icons.code;
      case 'gaming':
        return Icons.sports_esports;
      case 'music':
        return Icons.music_note;
      case 'art':
        return Icons.palette;
      case 'sports':
        return Icons.sports_soccer;
      case 'photography':
        return Icons.camera_alt;
      case 'fitness':
        return Icons.fitness_center;
      case 'movies':
        return Icons.movie;
      case 'outdoors':
        return Icons.terrain;
      case 'coffee':
        return Icons.coffee;
      case 'animals':
        return Icons.pets;
      case 'gardening':
        return Icons.local_florist;
      case 'hiking':
        return Icons.hiking;
      default:
        return Icons.favorite;
    }
  }

  Widget _buildActionPlaceholder(String title, String subtitle, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : QaboolTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              Icon(icon, color: QaboolTheme.primary, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = MediaQuery.of(context).size.width > 800;
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
                    onTap: () {
                      if (isLargeScreen) {
                        setState(() => _activeDesktopSection = 'connections');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ConnectionsScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActivityCard(
                    icon: Icons.favorite_border,
                    label: 'Favorites',
                    color: const Color(0xFFFF7074),
                    isDark: isDark,
                    onTap: () {
                      if (isLargeScreen) {
                        setState(() => _activeDesktopSection = 'favorites');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FavoritesScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActivityCard(
                    icon: Icons.block_flipped,
                    label: 'Skipped',
                    count: _skippedCount,
                    color: Colors.grey,
                    isDark: isDark,
                    onTap: () {
                      if (isLargeScreen) {
                        setState(() => _activeDesktopSection = 'skipped');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SkippedScreen()),
                        ).then((_) => _fetchSkippedCount());
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
