import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart'; // Added
import 'api_service.dart';
import '../widgets/notification_overlay.dart';
import '../main.dart'; // To access navigatorKey
import '../screens/chat_screen.dart'; // To navigate on tap

class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }

  bool get hasMore => page < totalPages;
}

class ChatService extends ChangeNotifier {
  final ApiService _apiService;
  IO.Socket? _socket;
  
  List<ChatModel> _chats = [];
  Map<String, List<MessageModel>> _messages = {}; // chatId -> messages
  Map<String, PaginationMeta> _paginationMeta = {}; // chatId -> meta
  Map<String, bool> _isLoadingMore = {}; // chatId -> isloading
  Map<String, bool> _typingStates = {}; // chatId -> isTyping
  String? _activeChatId;

  ChatService(this._apiService);

  List<ChatModel> get chats => _chats;
  int get totalUnreadCount => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  List<MessageModel> getMessages(String chatId) => _messages[chatId] ?? [];
  bool hasMoreMessages(String chatId) => _paginationMeta[chatId]?.hasMore ?? false;
  bool isLoadingMore(String chatId) => _isLoadingMore[chatId] ?? false;
  bool isTyping(String chatId) => _typingStates[chatId] ?? false;

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  void initSocket(String token) {
    if (_socket != null && _socket!.connected) return;
    
    _socket?.dispose(); // Clean up existing if any
    
    _socket = IO.io('http://127.0.0.1:3000', 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .build()
    );

    _socket?.onConnect((_) {
      print('Connected to socket');
      notifyListeners();
    });

    _socket?.onDisconnect((_) {
      print('Disconnected from socket');
      notifyListeners();
    });

    _socket?.on('new_message', (data) {
      print('New message received: $data');
      try {
        Map<String, dynamic> jsonData;
        if (data is String) {
          jsonData = jsonDecode(data);
        } else {
          // Robust way to convert JS object to Dart Map on web
          try {
            jsonData = jsonDecode(jsonEncode(data));
          } catch (_) {
            jsonData = Map<String, dynamic>.from(data as dynamic);
          }
        }
        final message = MessageModel.fromJson(jsonData);
        _addMessage(message);
      } catch (e) {
        print('Error parsing message: $e');
      }
    });
    
    _socket?.on('new_favorite', (data) {
      print('New favorite received: $data');
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
        
        final from = jsonData['from'];
        if (from != null) {
          final userName = from['firstName'] ?? 'Someone';
          final profileImageUrl = from['profileImageUrl'];
          
          if (navigatorKey.currentContext != null) {
            NotificationOverlay.show(
              context: navigatorKey.currentContext!,
              title: 'New Favorite! ⭐',
              message: '$userName just added you to their favorites!',
              imageUrl: profileImageUrl,
              onTap: () {
                // Navigate to discovery or who liked you if needed
                // For now, it just shows who it is
              },
            );
          }
        }
      } catch (e) {
        print('Error parsing favorite notification: $e');
      }
    });

    _socket?.on('typing_status', (data) {
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
        
        final chatId = jsonData['chatId'];
        final isTyping = jsonData['isTyping'] ?? false;
        
        if (chatId != null) {
          _typingStates[chatId] = isTyping;
          notifyListeners();
        }
      } catch (e) {
        print('Error parsing typing status: $e');
      }
    });

    _socket?.on('new_connection_request', (data) {
      print('New connection request received: $data');
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
        
        final requester = jsonData['requester'];
        final message = jsonData['message'] ?? 'Someone sent you a connection request';
        
        if (requester != null && navigatorKey.currentContext != null) {
          final profileImageUrl = requester['profileImageUrl'];
          
          NotificationOverlay.show(
            context: navigatorKey.currentContext!,
            title: 'Connection Request! 🤝',
            message: message,
            imageUrl: profileImageUrl,
            onTap: () {
              // Navigation can be handled here if needed
            },
          );
        }
      } catch (e) {
        print('Error parsing connection notification: $e');
      }
    });

    _socket?.connect();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    notifyListeners();
  }

  bool get isConnected => _socket?.connected ?? false;

  void _addMessage(MessageModel message) {
    if (_messages[message.chatId] == null) {
      _messages[message.chatId] = [];
    }
    
    // Avoid duplicates
    if (_messages[message.chatId]!.any((m) => m.id == message.id)) return;
    
    _messages[message.chatId]!.add(message);
    
    // Update last message in the chat list for continuity
    final chatIndex = _chats.indexWhere((c) => c.id == message.chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      // Increment unread count if message is not from me
      // Robust isFromMe: if it doesn't match the other person in this 1:1 chat, it's from me
      final otherParticipant = chat.participants.firstWhere(
        (p) => p.id.trim().toLowerCase() != _apiService.currentUserId?.trim().toLowerCase(),
        orElse: () => chat.participants.first, // Fallback
      );
      
      final isFromMe = message.senderId.trim().toLowerCase() != otherParticipant.id.trim().toLowerCase();

      print('--- DEBUG UNREAD ---');
      print('Message Sender ID: "${message.senderId}"');
      print('Other Participant ID: "${otherParticipant.id}"');
      print('Current User ID (ApiService): "${_apiService.currentUserId}"');
      print('Is From Me: $isFromMe');
      
      final updatedChat = chat.copyWith(
        lastMessage: message,
        unreadCount: !isFromMe ? chat.unreadCount + 1 : chat.unreadCount,
      );
      
      // Move to top (Stack approach)
      _chats.removeAt(chatIndex);
      _chats.insert(0, updatedChat);

      // Show notification if NOT from me and NOT active chat
      if (!isFromMe && message.chatId != _activeChatId) {
        _showNotification(message, otherParticipant);
      }

      notifyListeners();
    } else {
      // If chat not in list, refetch to be sure
      fetchChats();
    }
  }

  void _showNotification(MessageModel message, UserModel otherUser) {
    if (navigatorKey.currentContext == null) return;

    NotificationOverlay.show(
      context: navigatorKey.currentContext!,
      title: otherUser.fullName,
      message: message.content,
      imageUrl: otherUser.profileImageUrl,
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: message.chatId,
              otherUser: otherUser,
            ),
          ),
        );
      },
    );
  }

  Future<ChatModel> createChat(String recipientId) async {
    try {
      final response = await _apiService.client.post('/chats', data: {'recipientId': recipientId});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final chat = ChatModel.fromJson(response.data);
        // Check if chat already exists in our list
        final index = _chats.indexWhere((c) => c.id == chat.id);
        if (index == -1) {
          _chats.add(chat);
          notifyListeners();
        }
        return chat;
      }
      throw Exception('Failed to create chat');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchChats() async {
    try {
      final response = await _apiService.client.get('/chats');
      if (response.statusCode == 200) {
        _chats = (response.data as List)
            .map((c) => ChatModel.fromJson(c))
            .where((c) => c.lastMessage != null)
            .toList();
        
        // Sorting: Stack approach (latest message at the top)
        _chats.sort((a, b) {
          final timeA = a.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching chats: $e');
    }
  }

  Future<void> markAsRead(String chatId) async {
    try {
      final response = await _apiService.client.post('/chats/$chatId/read');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final index = _chats.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          _chats[index] = _chats[index].copyWith(unreadCount: 0);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  Future<void> fetchMessages(String chatId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.client.get(
        '/chats/$chatId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      
      if (response.statusCode == 200) {
        final List<MessageModel> newMessages = (response.data['messages'] as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        
        final meta = PaginationMeta.fromJson(response.data['meta']);
        _paginationMeta[chatId] = meta;
        
        if (page == 1) {
          _messages[chatId] = newMessages;
        } else {
          // Prepend older messages
          final currentMsgs = _messages[chatId] ?? [];
          _messages[chatId] = [...newMessages, ...currentMsgs];
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<void> fetchMoreMessages(String chatId) async {
    final meta = _paginationMeta[chatId];
    if (meta == null || !meta.hasMore || (_isLoadingMore[chatId] ?? false)) return;

    _isLoadingMore[chatId] = true;
    notifyListeners();

    try {
      await fetchMessages(chatId, page: meta.page + 1);
    } finally {
      _isLoadingMore[chatId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String recipientId,
    required String content,
  }) async {
    _socket?.emit('send_message', {
      'chatId': chatId,
      'recipientId': recipientId,
      'content': content,
      'type': 'TEXT',
    });
  }

  void setTypingStatus({
    required String chatId,
    required String recipientId,
    required bool isTyping,
  }) {
    _socket?.emit('typing_status', {
      'chatId': chatId,
      'recipientId': recipientId,
      'isTyping': isTyping,
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
