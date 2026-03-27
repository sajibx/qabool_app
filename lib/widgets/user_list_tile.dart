import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qabool_app/models/user_model.dart';
import 'package:qabool_app/utils/image_utils.dart';
import '../theme.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onConnect;
  final VoidCallback onFavorite;
  final VoidCallback onSkip;
  final bool isSelected;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.user,
    required this.onConnect,
    required this.onFavorite,
    required this.onSkip,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = resolveImageUrl(user.profileImageUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected && !isDark ? QaboolTheme.primary.withOpacity(0.05) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isSelected ? QaboolTheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${user.firstName}, ${user.age ?? ""}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified || true) ...[ // using mock assumed true
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF3498DB), size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.city}, ${user.country}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSmallButton(Icons.close, const Color(0xFF94A3B8), onSkip),
                    const SizedBox(width: 8),
                    _buildSmallButton(
                      user.connectionStatus == 'ACCEPTED' ? Icons.chat_bubble : Icons.favorite, 
                      user.connectionStatus == 'ACCEPTED' ? const Color(0xFF2ECC71) : const Color(0xFFFF2D55), 
                      onConnect, 
                      isMain: true
                    ),
                    const SizedBox(width: 8),
                    _buildSmallButton(Icons.star, const Color(0xFFFFB800), onFavorite),
                    const SizedBox(width: 4), // right padding inside cylinder
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, Color color, VoidCallback onTap, {bool isMain = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMain ? 40 : 32,
        height: isMain ? 40 : 32,
        decoration: BoxDecoration(
          color: isMain ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.white : color,
          size: isMain ? 20 : 16,
        ),
      ),
    );
  }
}
