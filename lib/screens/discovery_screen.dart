import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/services/profile_service.dart';
import 'package:qabool_app/services/chat_service.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/screens/chat_screen.dart';
import 'package:qabool_app/services/auth_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _isLoading = true;
  List<UserModel> _profiles = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    final profileService = context.read<ProfileService>();
    final authService = context.read<AuthService>();
    try {
      final profiles = await profileService.getDiscoveryList();
      if (mounted) {
        setState(() {
          _profiles = profiles
              .where((p) => p.id != authService.currentUser?.id)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profiles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tailwind extracted colors
    const primaryColor = QaboolTheme.primary; // Gold: #d4af35
    const secondaryColor = QaboolTheme.maroon; // Maroon: #800000
    const bgLight = Color(0xFFF8F7F6);
    const bgDark = Color(0xFF201D12);
    const cardBgLight = Colors.white;
    const cardBgDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? bgDark.withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.search,
                          color: isDark ? primaryColor : secondaryColor,
                          size: 28),
                      Text(
                        'Qabool',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: isDark ? primaryColor : secondaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Icon(Icons.tune,
                          color: isDark ? primaryColor : secondaryColor,
                          size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Advanced Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton(
                            'Age', primaryColor, secondaryColor, isDark),
                        const SizedBox(width: 12),
                        _buildFilterButton(
                            'Religion', primaryColor, secondaryColor, isDark),
                        const SizedBox(width: 12),
                        _buildFilterButton(
                            'Education', primaryColor, secondaryColor, isDark),
                        const SizedBox(width: 12),
                        _buildFilterButton(
                            'Location', primaryColor, secondaryColor, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _profiles.isEmpty
                      ? const Center(child: Text('No profiles found Match your criteria'))
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                            childAspectRatio: 0.55,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            return _buildProfileCard(
                              profile: profile,
                              isDark: isDark,
                              cardBg: isDark ? cardBgDark : cardBgLight,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      String label, Color primaryColor, Color secondaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required UserModel profile,
    required bool isDark,
    required Color cardBg,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: profile.profileImageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person,
                            size: 40,
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 4),
                        Text(
                          'No Image',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.isOnline) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ACTIVE NOW',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '${profile.firstName}, ${profile.age ?? ""}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.profession ?? 'Member',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${profile.city}, ${profile.country}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12)
                  .copyWith(bottom: 12),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final chatService = context.read<ChatService>();
                    final chat = await chatService.createChat(profile.id);
                    if (context.mounted) {
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
                        SnackBar(content: Text('Failed to initiate chat: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? primaryColor : secondaryColor,
                  foregroundColor: isDark ? secondaryColor : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Connect',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
