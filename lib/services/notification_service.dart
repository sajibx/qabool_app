import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qabool_app/models/notification_model.dart';
import 'package:qabool_app/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../widgets/notification_overlay.dart';
import 'package:qabool_app/utils/navigation_utils.dart';

class NotificationService extends ChangeNotifier {
  final ApiService _apiService;
  IO.Socket? _socket;
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationService(this._apiService);

  // Filter to only show unread notifications in the UI
  List<NotificationModel> get notifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void initSocket(String token) {
    if (_socket != null) return;

    const String baseUrl = 'http://localhost:3000';
    _socket = IO.io(baseUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token}
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[NotificationSocket] Connected');
      // Fetch current state from DB once connected
      fetchUnreadCount();
      fetchNotifications();
    });

    _socket!.onDisconnect((_) => print('[NotificationSocket] Disconnected'));
    
    _setupSocketListeners();
  }


  void _setupSocketListeners() {
    _socket?.on('new_notification', (data) {
      print('[NotificationSocket] new_notification received: $data');
      _handleIncomingNotification(data);
    });

    _socket?.on('new_connection_request', (data) {
      print('[NotificationSocket] new_connection_request received: $data');
      // For specialized events, we might not have a full NotificationModel yet,
      // so we trigger a refresh of notifications and count.
      fetchNotifications(); 
      fetchUnreadCount();
      
      try {
        final requester = data['requester'];
        if (navigatorKey.currentContext != null && requester != null) {
          NotificationOverlay.show(
            context: navigatorKey.currentContext!,
            title: 'Connection Request! 🤝',
            message: '${requester['firstName']} sent you a connection request',
            imageUrl: requester['profileImageUrl'],
          );
        }
      } catch (e) {
        print('[NotificationSocket] Error showing connection banner: $e');
      }
    });

    _socket?.on('new_favorite', (data) {
      print('[NotificationSocket] new_favorite received: $data');
      fetchNotifications();
      fetchUnreadCount();
      
      try {
        final from = data['from'];
        if (navigatorKey.currentContext != null && from != null) {
          NotificationOverlay.show(
            context: navigatorKey.currentContext!,
            title: 'New Favorite! ⭐',
            message: '${from['firstName']} added you to favorites',
            imageUrl: from['profileImageUrl'],
          );
        }
      } catch (e) {
        print('[NotificationSocket] Error showing favorite banner: $e');
      }
    });

    _socket?.connect();
  }

  void _handleIncomingNotification(dynamic data) {
    try {
      Map<String, dynamic> jsonData;
      if (data is String) {
        jsonData = jsonDecode(data);
      } else {
        try {
          jsonData = jsonDecode(jsonEncode(data));
        } catch (_) {
          jsonData = Map<String, dynamic>.from(data as dynamic);
        }
      }
      
      final notification = NotificationModel.fromJson(jsonData);
      
      // Strict defensive check: only process if it's for current user session
      if (_apiService.currentUserId != null && 
          notification.userId.trim().toLowerCase() != _apiService.currentUserId?.trim().toLowerCase()) {
        print('[NotificationSocket] Ignoring notification for different user: ${notification.userId}');
        return;
      }

      // Check if duplicate (might have been added by specialized listener refetch)
      if (_notifications.any((n) => n.id == notification.id)) return;
      
      _addNotification(notification);
      // Ensure the unread count matches the backend after any new notification
      fetchUnreadCount();
      
      // Show overlay alert
      if (navigatorKey.currentContext != null) {
        NotificationOverlay.show(
          context: navigatorKey.currentContext!,
          title: _getNotificationTitle(notification),
          message: notification.message,
          imageUrl: notification.sender?.profileImageUrl,
        );
      }
    } catch (e) {
      print('[NotificationSocket] Error parsing: $e');
    }
  }

  String _getNotificationTitle(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.FAVORITE:
        return 'New Favorite! ⭐';
      case NotificationType.CONNECTION_REQUEST:
        return 'Connection Request! 🤝';
      case NotificationType.CONNECTION_ACCEPTED:
        return 'Match Found! ❤️';
    }
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _addNotification(NotificationModel notification) {
    // Check if duplicate
    if (_notifications.any((n) => n.id == notification.id)) return;
    
    _notifications.insert(0, notification);
    if (_notifications.length > 20) {
      _notifications = _notifications.sublist(0, 20);
    }
    
    if (!notification.isRead) {
      _unreadCount++;
    }
    
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.client.get('/notifications');
      if (response.statusCode == 200) {
        _notifications = (response.data as List)
            .map((n) => NotificationModel.fromJson(n))
            .toList();
        
        // Backend already keeps last 20, but we double check
        if (_notifications.length > 20) {
          _notifications = _notifications.sublist(0, 20);
        }
      }
      
      await fetchUnreadCount();
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.client.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        _unreadCount = response.data['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      await _apiService.client.patch('/notifications/$id/read');
    } catch (e) {
      print('Error marking as read: $e');
      // If failed, we should ideally revert or just re-fetch
      await fetchUnreadCount();
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiService.client.patch('/notifications/read-all');
      // Give the backend a moment to process the update before fetching the new count
      await Future.delayed(const Duration(milliseconds: 200));
      await fetchUnreadCount();
    } catch (e) {
      print('Error marking all as read: $e');
      await fetchUnreadCount();
    }
  }

  void clearData() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
