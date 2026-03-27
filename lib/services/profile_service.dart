import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService extends ChangeNotifier {
  final ApiService _apiService;

  ProfileService(this._apiService);

  Future<void> skipUser(UserModel user) async {
    try {
      await _apiService.client.post('/profiles/${user.id}/skip');
      notifyListeners();
    } catch (e) {
      debugPrint('Error skipping user: $e');
      rethrow;
    }
  }

  Future<void> unskipUser(String userId) async {
    try {
      await _apiService.client.delete('/profiles/$userId/skip');
      notifyListeners();
    } catch (e) {
      debugPrint('Error unskipping user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getSkippedUsers() async {
    try {
      final response = await _apiService.client.get('/profiles/skipped');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching skipped users: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getHomeProfiles() async {
    try {
      final response = await _apiService.client.get('/profiles/home');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching home profiles: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getExploreProfiles(bool includeConnected, bool includeSkipped) async {
    try {
      final response = await _apiService.client.get('/profiles/explore/$includeConnected/$includeSkipped');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching explore profiles: $e');
      rethrow;
    }
  }

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

  Future<List<UserModel>> getDiscoverUsers() async {
    try {
      final response = await _apiService.client.get('/profiles/discover');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data, {XFile? image}) async {
    try {
      // Create a copy and filter out nulls/empty strings to avoid 400 errors on the backend
      final filteredData = Map<String, dynamic>.from(data);
      filteredData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

      final formData = FormData.fromMap(filteredData);
      if (image != null) {
        if (kIsWeb) {
          formData.files.add(MapEntry(
            'profileImage',
            MultipartFile.fromBytes(
              await image.readAsBytes(),
              filename: image.name,
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'profileImage',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ));
        }
      }

      final response = await _apiService.client.put('/profiles/me', data: formData);
      debugPrint('PUT /profiles/me response: ${response.data}');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to update profile');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getProfile(String id) async {
    try {
      final response = await _apiService.client.get('/profiles/$id');
      debugPrint('GET /profiles/$id response: ${response.data}');
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

  // Blocking
  Future<void> blockUser(String id) async {
    try {
      await _apiService.client.post('/blocks/$id');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unblockUser(String id) async {
    try {
      await _apiService.client.delete('/blocks/$id');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getBlockedUsers() async {
    try {
      final response = await _apiService.client.get('/blocks');
      if (response.statusCode == 200) {
        return (response.data as List).map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  void clearData() {
    notifyListeners();
  }
}
