// ignore_for_file: unused_element

class _EventModel {
  const _EventModel();
}

class StreamValue<T> {
  StreamValue({T? defaultValue});
}

// expect_lint: repository_model_stream_lifecycle_methods_required
class _RepositoryModelStreamValueNullableCase {
  final eventsStreamValue =
      // expect_lint: repository_model_streamvalue_nullable_required
      StreamValue<List<_EventModel>>(defaultValue: const []);

  final eventsNullableStreamValue =
      StreamValue<List<_EventModel>?>(defaultValue: null);
}

class _RepositoryModelStreamLifecycleGoodCase {
  final eventsStreamValue = StreamValue<List<_EventModel>?>(defaultValue: null);

  Future<void> initializeEvents() async {}

  Future<void> refreshEvents() async {}
}
