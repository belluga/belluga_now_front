import 'package:push_handler/push_handler.dart';

class PushMessageInstanceTracker {
  String? _currentId;

  bool update(PushEvent event) {
    final id = event.messageInstanceId?.trim() ?? '';
    if (id.isEmpty) {
      return false;
    }
    if (_currentId == id) {
      return false;
    }
    _currentId = id;
    return true;
  }

  String? get currentId => _currentId;
}
