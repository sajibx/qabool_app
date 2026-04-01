import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? currentUserId;
  String? _accessToken; // In-memory token to prevent shared storage contamination
  Function? onUnauthorized;
  bool _initialized = false;

  ApiService() {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Priority: In-memory token. Fallback: Storage (only if not yet initialized)
          if (!_initialized) {
            _accessToken = await _storage.read(key: 'access_token');
            _initialized = true;
          }
          
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;

  Future<void> saveToken(String token) async {
    _accessToken = token;
    _initialized = true;
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> deleteToken() async {
    _accessToken = null;
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;
    _accessToken = await _storage.read(key: 'access_token');
    _initialized = true;
    return _accessToken;
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: 'user_data', value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: 'user_data');
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: 'user_data');
  }
}
