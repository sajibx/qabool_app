import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  UserModel? _currentUser;
  bool _isLoading = false;

  AuthService(this._apiService);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['access_token'];
        await _apiService.saveToken(token);
        _currentUser = UserModel.fromJson(response.data['user']);
        _apiService.currentUserId = _currentUser?.id;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });

      if (response.statusCode == 201) {
        final token = response.data['access_token'];
        await _apiService.saveToken(token);
        _currentUser = UserModel.fromJson(response.data['user']);
        _apiService.currentUserId = _currentUser?.id;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _apiService.deleteToken();
    _currentUser = null;
    _apiService.currentUserId = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final response = await _apiService.client.get('/profiles/me');
        if (response.statusCode == 200) {
          _currentUser = UserModel.fromJson(response.data);
          _apiService.currentUserId = _currentUser?.id;
          notifyListeners();
        }
      }
    } catch (e) {
      // Token might be expired or invalid
      await logout();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
