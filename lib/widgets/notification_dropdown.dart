import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qabool_app/models/notification_model.dart';
import 'package:qabool_app/services/notification_service.dart';
import 'package:qabool_app/theme.dart';
import 'package:qabool_app/utils/image_utils.dart';
import 'package:qabool_app/screens/profile_screen.dart';
import 'package:qabool_app/screens/discovery_screen.dart';
import 'package:qabool_app/screens/messages_screen.dart';
import 'package:qabool_app/services/navigation_service.dart';
import 'package:intl/intl.dart';

class NotificationDropdown extends StatelessWidget {
  final VoidCallback onDismiss;

  const NotificationDropdown({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final notifications = notificationService.notifications;
        
        return Container(
          width: isLargeScreen ? 400 : 320,
          constraints: BoxConstraints(maxHeight: isLargeScreen ? 600 : 450),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (notificationService.unreadCount > 0)
                      TextButton(
                        onPressed: () => notificationService.markAllAsRead(),
                        style: TextButton.styleFrom(
                          foregroundColor: QaboolTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // List
              Flexible(
                child: notificationService.isLoading && notifications.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : notifications.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: QaboolTheme.primary.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.notifications_none_rounded, size: 48, color: QaboolTheme.primary.withOpacity(0.5)),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'All caught up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You have no new notifications.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _NotificationItem(
                                notification: notification,
                                onDismiss: onDismiss,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        context.read<NotificationService>().markAsRead(notification.id);
        onDismiss();
        _navigate(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : QaboolTheme.primary.withOpacity(0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar or Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: QaboolTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: notification.sender?.profileImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: resolveImageUrl(notification.sender!.profileImageUrl),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _buildTypeIcon(),
                      )
                    : _buildTypeIcon(),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread Dot
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: QaboolTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color color = QaboolTheme.primary;
    
    switch (notification.type) {
      case NotificationType.FAVORITE:
        iconData = Icons.star;
        color = const Color(0xFFFFB800);
        break;
      case NotificationType.CONNECTION_REQUEST:
        iconData = Icons.person_add;
        break;
      case NotificationType.CONNECTION_ACCEPTED:
        iconData = Icons.favorite;
        break;
    }
    
    return Icon(iconData, color: color, size: 20);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime); // e.g. 10:30 AM
  }

  void _navigate(BuildContext context) {
    final nav = context.read<NavigationService>();
    switch (notification.type) {
      case NotificationType.FAVORITE:
        if (notification.sender != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: notification.sender),
            ),
          );
        }
        break;
      case NotificationType.CONNECTION_REQUEST:
        // Navigate to Discovery tab -> Ready to Qabool -> Received
        nav.goToDiscovery(subTab: 1, readyToQaboolSubTab: 1);
        break;
      case NotificationType.CONNECTION_ACCEPTED:
        // Navigate to Messages tab
        nav.goToMessages();
        break;
    }
  }
}
