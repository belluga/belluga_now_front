// ignore_for_file: unused_element

class StreamValue<T> {
  void dispose() {}
}

class _OwnedStreamValueDisposeRequiredBadCaseController {
  // expect_lint: controller_owned_streamvalue_dispose_required
  final StreamValue<int> counterStreamValue = StreamValue<int>();

  final StreamValue<bool> flagStreamValue = StreamValue<bool>();

  void onDispose() {
    flagStreamValue.dispose();
  }
}

class _OwnedStreamValueDisposeRequiredGoodCaseController {
  final StreamValue<int> counterStreamValue = StreamValue<int>();

  void onDispose() {
    counterStreamValue.dispose();
  }
}
