import 'dart:async';

class PushPresentationGate {
  final Completer<void> _ready = Completer<void>();

  bool get isReady => _ready.isCompleted;

  Future<void> waitUntilReady() => _ready.future;

  void markReady() {
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }
}
