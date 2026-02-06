class AuthRedirectStore {
  String? _pendingPath;

  bool get hasPendingPath =>
      _pendingPath != null && _pendingPath!.trim().isNotEmpty;

  String? consumePendingPath() {
    final path = _pendingPath;
    _pendingPath = null;
    return path;
  }

  void setPendingPath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return;
    }
    _pendingPath = path;
  }

  void clear() {
    _pendingPath = null;
  }
}
