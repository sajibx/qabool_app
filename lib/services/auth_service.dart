import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  UserModel? _currentUser;
  bool _isLoading = false;
  VoidCallback? _onLogout;

  AuthService(this._apiService) {
    _apiService.onUnauthorized = logout;
  }

  set onLogout(VoidCallback callback) => _onLogout = callback;

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
        
        final user = UserModel.fromJson(response.data['user']);
        await _apiService.saveUserData(jsonEncode(user.toJson()));
        
        _currentUser = user;
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
    String? gender,
    String? dob,
    String? ethnicity,
    String? religion,
    double? height,
    double? weight,
    String? profession,
    String? education,
    String? bio,
    String? specialConsiderations,
    String? region,
    bool hasPastIssues = false,
    bool acceptsPastIssues = true,
    String? phoneNumber,
    String? maritalStatus,
    String? currentCity,
    double? monthlyIncome,
    int? siblings,
    int? familyMembers,
    String? lookingForAge,
    String? lookingForType,
    String? lookingForProfession,
    List<String>? interests,
    XFile? profileImage,
  }) async {
    try {
      _setLoading(true);
      
      final Map<String, dynamic> dataMap = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dob': dob,
        'ethnicity': ethnicity,
        'religion': religion,
        'height': height,
        'weight': weight,
        'profession': profession,
        'education': education,
        'bio': bio,
        'specialConsiderations': specialConsiderations,
        'region': region,
        'hasPastIssues': hasPastIssues,
        'acceptsPastIssues': acceptsPastIssues,
        'phoneNumber': phoneNumber,
        'maritalStatus': maritalStatus,
        'currentCity': currentCity,
        'monthlyIncome': monthlyIncome,
        'siblings': siblings,
        'familyMembers': familyMembers,
        'lookingForAge': lookingForAge,
        'lookingForType': lookingForType,
        'lookingForProfession': lookingForProfession,
        'interests': interests,
      };

      final formData = FormData.fromMap(dataMap);

      if (profileImage != null) {
        if (kIsWeb) {
          formData.files.add(MapEntry(
            'profileImage',
            MultipartFile.fromBytes(
              await profileImage.readAsBytes(),
              filename: profileImage.name,
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'profileImage',
            await MultipartFile.fromFile(profileImage.path, filename: profileImage.name),
          ));
        }
      }

      final response = await _apiService.client.post('/auth/register', data: formData);

      if (response.statusCode == 201) {
        // Registration successful, but we don't sign in automatically
        // as per the new requirement for admin approval.
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _onLogout?.call();
    await _apiService.deleteToken();
    await _apiService.deleteUserData();
    _currentUser = null;
    _apiService.currentUserId = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      // 1. Try to load from local cache first for instant UI
      final cachedUser = await _apiService.getUserData();
      if (cachedUser != null) {
        _currentUser = UserModel.fromJson(jsonDecode(cachedUser));
        _apiService.currentUserId = _currentUser?.id;
        notifyListeners();
      }

      // 2. Verify with server in the background
      final token = await _apiService.getToken();
      if (token != null) {
        final response = await _apiService.client.get('/profiles/me');
        if (response.statusCode == 200) {
          final user = UserModel.fromJson(response.data);
          _currentUser = user;
          _apiService.currentUserId = _currentUser?.id;
          // Update cache with fresh data
          await _apiService.saveUserData(jsonEncode(user.toJson()));
          notifyListeners();
        }
      }
    } catch (e) {
      // If server returns 401, ApiService will trigger onUnauthorized -> logout()
      // For any other error (offline, timeout), we KEEP the current user from cache
      print('CheckAuth error: $e');
    }
  }

  Future<void> updateCurrentUser(UserModel user) async {
    debugPrint('AuthService: updateCurrentUser. New image: ${user.profileImageUrl}');
    _currentUser = user;
    _apiService.currentUserId = user.id;
    await _apiService.saveUserData(jsonEncode(user.toJson()));
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
