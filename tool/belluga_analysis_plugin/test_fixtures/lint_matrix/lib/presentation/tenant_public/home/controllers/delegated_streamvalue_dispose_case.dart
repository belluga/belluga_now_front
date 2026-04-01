// ignore_for_file: unused_element

class StreamValue<T> {
  void dispose() {}
}

class _EventModel {
  const _EventModel();
}

abstract class _ScheduleRepositoryContract {
  StreamValue<List<_EventModel>> get liveNowEventsStreamValue;
}

class _ScheduleRepository implements _ScheduleRepositoryContract {
  @override
  final StreamValue<List<_EventModel>> liveNowEventsStreamValue =
      StreamValue<List<_EventModel>>();
}

class _DelegatedStreamValueDisposeCaseController {
  final _ScheduleRepositoryContract _scheduleRepository = _ScheduleRepository();
  final StreamValue<int> _localStreamValue = StreamValue<int>();
  final StreamValue<List<_EventModel>> _delegatedAliasStreamValue =
      _ScheduleRepository().liveNowEventsStreamValue;

  StreamValue<List<_EventModel>> get liveNowEventsStreamValue =>
      _scheduleRepository.liveNowEventsStreamValue;

  void onDispose() {
    _localStreamValue.dispose();

    // expect_lint: controller_delegated_streamvalue_dispose_forbidden
    liveNowEventsStreamValue.dispose();

    // expect_lint: controller_delegated_streamvalue_dispose_forbidden
    _scheduleRepository.liveNowEventsStreamValue.dispose();

    _delegatedAliasStreamValue.dispose();
  }
}
