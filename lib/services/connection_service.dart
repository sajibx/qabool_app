import 'package:flutter/material.dart';
import '../models/connection_model.dart';
import 'api_service.dart';

class ConnectionService extends ChangeNotifier {
  final ApiService _apiService;
  List<ConnectionModel> _connections = [];
  bool _isLoading = false;

  ConnectionService(this._apiService);

  List<ConnectionModel> get connections => _connections;
  bool get isLoading => _isLoading;

  List<ConnectionModel> get pendingRequests => 
      _connections.where((c) => c.status == ConnectionStatus.PENDING).toList();

  List<ConnectionModel> get acceptedConnections => 
      _connections.where((c) => c.status == ConnectionStatus.ACCEPTED).toList();

  Future<void> fetchConnections() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.client.get('/connections');
      if (response.statusCode == 200) {
        _connections = (response.data as List)
            .map((c) => ConnectionModel.fromJson(c))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching connections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendConnectionRequest(String recipientId) async {
    try {
      await _apiService.client.post('/connections', data: {'recipientId': recipientId});
      await fetchConnections();
    } catch (e) {
      debugPrint('Error sending connection request: $e');
      rethrow;
    }
  }

  Future<void> respondToRequest(String connectionId, ConnectionStatus status) async {
    try {
      await _apiService.client.put('/connections/$connectionId', data: {
        'status': status.name,
      });
      await fetchConnections();
    } catch (e) {
      debugPrint('Error responding to connection request: $e');
      rethrow;
    }
  }
}
