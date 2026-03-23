// ignore_for_file: unused_element

class _EventModel {
  const _EventModel();
}

class _StreamValue<T> {}

_StreamValue<T> StreamValue<T>({T? defaultValue}) => _StreamValue<T>();

class _ControllerModelStreamOwnershipCase {
  final displayedEventsStreamValue =
      // expect_lint: controller_streamvalue_model_ownership_forbidden
      StreamValue<List<_EventModel>?>(defaultValue: null);
}

class _ControllerModelStreamLateInitCase {
  late _StreamValue<List<_EventModel>> displayedEventsStreamValue;

  void init() {
    displayedEventsStreamValue =
        // expect_lint: controller_streamvalue_model_ownership_forbidden
        StreamValue<List<_EventModel>>(defaultValue: const []);
  }
}

class HomeController {
  const HomeController();

  void onScroll(Object payload) {}
}
