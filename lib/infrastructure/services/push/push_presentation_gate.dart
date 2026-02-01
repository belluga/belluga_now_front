import 'dart:async';

import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';

class PushPresentationGate implements PushPresentationGateContract {
  final Completer<void> _ready = Completer<void>();

  @override
  bool get isReady => _ready.isCompleted;

  @override
  Future<void> waitUntilReady() => _ready.future;

  @override
  void markReady() {
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }
}
