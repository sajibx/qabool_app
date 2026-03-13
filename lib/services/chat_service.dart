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
          jsonData = jsonDecode(jsonEncode(data));
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
      final updatedChat = _chats[chatIndex].copyWith(lastMessage: message);
      _chats[chatIndex] = updatedChat;
    }
    
    notifyListeners();
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
        _chats = (response.data as List).map((c) => ChatModel.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
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
