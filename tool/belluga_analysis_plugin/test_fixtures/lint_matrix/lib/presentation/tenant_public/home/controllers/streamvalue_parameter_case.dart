// ignore_for_file: unused_element

class StreamValue<T> {
  void addValue(T value) {}
}

class _StreamValueParameterCaseController {
  final StreamValue<int> _counterStreamValue = StreamValue<int>();

  // expect_lint: controller_streamvalue_parameter_forbidden
  void _setValue<T>(StreamValue<T> stream, T value) {
    stream.addValue(value);
  }

  void hydrate() {
    _counterStreamValue.addValue(1);
  }
}
