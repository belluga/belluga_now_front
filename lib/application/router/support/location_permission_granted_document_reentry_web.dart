import 'package:web/web.dart' as web;

bool performLocationPermissionGrantedDocumentReentry(String redirectPath) {
  final normalized = redirectPath.trim();
  final target = normalized.isEmpty ? '/' : normalized;
  final uri = Uri.tryParse(target);
  if (uri == null) {
    return false;
  }
  if (uri.hasScheme || uri.host.isNotEmpty) {
    return false;
  }
  final resolvedPath = uri.toString();
  if (resolvedPath.isEmpty) {
    return false;
  }
  web.window.location.replace(resolvedPath);
  return true;
}
