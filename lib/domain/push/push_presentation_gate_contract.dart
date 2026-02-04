abstract class PushPresentationGateContract {
  bool get isReady;
  Future<void> waitUntilReady();
  void markReady();
}
