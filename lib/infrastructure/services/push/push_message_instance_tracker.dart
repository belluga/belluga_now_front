import 'package:push_handler/push_handler.dart';

class PushMessageInstanceTracker {
  String? _currentId;

  void update(PushEvent event) {
    final id = event.messageInstanceId?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }
    _currentId = id;
  }

  String? get currentId => _currentId;
}
