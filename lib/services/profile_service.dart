import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ProfileService extends ChangeNotifier {
  final ApiService _apiService;

  ProfileService(this._apiService);

  Future<List<UserModel>> getDiscoveryList({String? religion, String? region, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (religion != null) queryParams['religion'] = religion;
      if (region != null) queryParams['region'] = region;
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.client.get('/profiles', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.client.put('/profiles/me', data: data);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getProfile(String id) async {
    try {
      final response = await _apiService.client.get('/profiles/$id');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to fetch profile');
    } catch (e) {
      rethrow;
    }
  }

  // Favorites
  Future<void> favoriteUser(String id) async {
    try {
      await _apiService.client.post('/favorites/$id');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unfavoriteUser(String id) async {
    try {
      await _apiService.client.delete('/favorites/$id');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getMyFavorites() async {
    try {
      final response = await _apiService.client.get('/favorites/my');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getUsersWhoFavoritedMe() async {
    try {
      final response = await _apiService.client.get('/favorites/by-whom');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
