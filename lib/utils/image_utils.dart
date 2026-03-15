/// Resolves a potentially relative image path to a full URL.
///
/// The backend stores image paths as relative paths (e.g. /uploads/abc.jpg).
/// This function transforms them into absolute URLs using the API base.
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return 'http://127.0.0.1:3000$path';
}
