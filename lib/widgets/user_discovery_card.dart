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

    return Container(
      margin: isGridMode ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isGridMode ? 24 : 32),
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
        borderRadius: BorderRadius.circular(isGridMode ? 24 : 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isGridMode ? 24 : 32),
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
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Info Section
            Positioned(
              left: isGridMode ? 12 : 20,
              right: isGridMode ? 12 : 20,
              bottom: isGridMode ? 85 : 145, // Moved higher to prevent button overlap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.firstName}, ${user.age ?? ""}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isGridMode ? 18 : 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, color: const Color(0xFF3498DB), size: isGridMode ? 18 : 24),
                      ],
                      if (user.hasPastIssues) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'User has past issues/problems',
                          child: Icon(Icons.info_outline, color: Colors.orangeAccent, size: isGridMode ? 18 : 24),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (user.profession != null) _buildTag(user.profession!, isDark, isSmall: isGridMode),
                      if (user.religion != null) _buildTag(user.religion!, isDark, isSmall: isGridMode),
                      if (!isGridMode && user.education != null) _buildTag(user.education!, isDark),
                    ],
                  ),
                  if (!isGridMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      user.bio ?? "Looking for someone shared my values...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${user.city}, ${user.country} • 5 mi',
                          style: TextStyle(color: Colors.white70, fontSize: isGridMode ? 11 : 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: isGridMode ? 12 : 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip Button (Cross)
                  _buildActionButton(
                    icon: Icons.close,
                    color: const Color(0xFF94A3B8), // slate 400
                    onTap: onSkip,
                    size: isGridMode ? 40 : 64,
                    iconSize: isGridMode ? 20 : 32,
                  ),
                  SizedBox(width: isGridMode ? 12 : 16),
                  // Connect Button (Heart)
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: const Color(0xFFFF2D55), // Red
                    onTap: onConnect,
                    size: isGridMode ? 52 : 84,
                    iconSize: isGridMode ? 24 : 38,
                    isMain: true,
                  ),
                  SizedBox(width: isGridMode ? 12 : 16),
                  // Favorite Button (Star)
                  _buildActionButton(
                    icon: Icons.star,
                    color: const Color(0xFFFFB800), // Gold
                    onTap: onFavorite,
                    size: isGridMode ? 40 : 64,
                    iconSize: isGridMode ? 20 : 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTag(String text, bool isDark, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmall ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
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
