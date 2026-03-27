import 'package:qabool_app/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Resolves a potentially relative image path to a full URL.
///
/// The backend stores image paths as relative paths (e.g. /uploads/abc.jpg).
/// This function transforms them into absolute URLs using the API base.
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) {
    debugPrint('resolveImageUrl: path is null or empty');
    return '';
  }
  if (path.startsWith('http')) return path;
  
  // Use the same origin as the API
  const baseUrl = ApiService.baseUrl;
  final uri = Uri.parse(baseUrl);
  final origin = '${uri.scheme}://${uri.host}:${uri.port}';
  
  // Remove leading slash if it exists to avoid double slash
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  final url = '$origin/$cleanPath';
  debugPrint('resolveImageUrl: $path -> $url');
  return url;
}
