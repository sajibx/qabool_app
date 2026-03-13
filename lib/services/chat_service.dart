import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService extends ChangeNotifier {
  final ApiService _apiService;
  IO.Socket? _socket;
  
  List<ChatModel> _chats = [];
  Map<String, List<MessageModel>> _messages = {}; // chatId -> messages

  ChatService(this._apiService);

  List<ChatModel> get chats => _chats;
  int get totalUnreadCount => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  List<MessageModel> getMessages(String chatId) => _messages[chatId] ?? [];

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
      notifyListeners();
    } else {
      // If chat not in list, refetch to be sure
      fetchChats();
    }
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

  Future<void> fetchMessages(String chatId) async {
    try {
      final response = await _apiService.client.get('/chats/$chatId/messages');
      if (response.statusCode == 200) {
        _messages[chatId] = (response.data as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
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

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
