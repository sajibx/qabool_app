/// Resolves a potentially relative image path to a full URL.
///
/// The backend stores image paths as relative paths (e.g. /uploads/abc.jpg).
/// This function transforms them into absolute URLs using the API base.
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  
  // Remove leading slash if it exists to avoid double slash
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return 'http://localhost:3000/$cleanPath';
}
