import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/utils/image_utils.dart';

class UserDiscoveryCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onConnect;
  final VoidCallback onFavorite;
  final VoidCallback onSkip;
  final VoidCallback? onTap;
  final bool isGridMode;

  const UserDiscoveryCard({
    super.key,
    required this.user,
    required this.onConnect,
    required this.onFavorite,
    required this.onSkip,
    this.onTap,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = resolveImageUrl(user.profileImageUrl);

    final cardContent = Container(
      margin: isGridMode ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isGridMode ? 12 : 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isGridMode ? 12 : 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isGridMode ? 12 : 10),
          child: Stack(
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
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
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Info Section
            Positioned(
              left: isGridMode ? 12 : 24,
              right: isGridMode ? 12 : 24,
            bottom: isGridMode ? 12 : 18, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Name and Age
                Row(
                  children: [
                    Text(
                      '${user.firstName}, ${user.age ?? ""}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isGridMode ? 16 : 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (user.isVerified || true) ...[ // Always show for Sarah mock
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Color(0xFF3498DB), size: 18),
                    ],
                  ],
                ),
                  const SizedBox(height: 8),
                  // Info Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (user.profession != null) 
                        _buildTag(user.profession!, Icons.work_outline, isGridMode),
                      if (user.religion != null) 
                        _buildTag(user.religion!, Icons.church_outlined, isGridMode),
                      _buildTag('Cooking', Icons.restaurant, isGridMode),
                      _buildTag('Travel', Icons.flight_takeoff, isGridMode),
                    ],
                  ),
                  if (!isGridMode && user.bio != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${user.city}, ${user.country} • 5 mi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons are now moved outside the Stack
          ],
        ),
      ),
      ), // close InkWell
    ); // close Container

    if (isGridMode) {
      return Column(
        children: [
          Expanded(child: cardContent),
          const SizedBox(height: 16),
          // Action Buttons Outside the Card
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.close,
                color: const Color(0xFF94A3B8),
                onTap: onSkip,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 16),
              // Main Heart/Connect Button
              _buildActionButton(
                icon: user.connectionStatus == 'ACCEPTED' ? Icons.chat_bubble : Icons.favorite,
                color: user.connectionStatus == 'ACCEPTED' ? const Color(0xFF2ECC71) : const Color(0xFFFF2D55),
                onTap: onConnect,
                size: 56,
                iconSize: 28,
                isMain: true,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.star,
                color: const Color(0xFFFFB800),
                onTap: onFavorite,
                size: 44,
                iconSize: 22,
              ),
            ],
          ),
        ],
      );
    }

    return cardContent;
  }

  Widget _buildTag(String text, IconData icon, bool isGridMode) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isGridMode ? 6 : 10,
        vertical: isGridMode ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isGridMode ? 10 : 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isGridMode ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
    required double iconSize,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isMain ? color : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isMain ? color : Colors.black).withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.white : color,
          size: iconSize,
        ),
      ),
    );
  }
}
