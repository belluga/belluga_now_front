// ignore_for_file: unused_element

class StreamValue<T> {
  void addValue(T value) {}
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

class _DelegatedStreamValueWriteCaseController {
  final _ScheduleRepositoryContract _scheduleRepository = _ScheduleRepository();
  final StreamValue<int> _localCounterStreamValue = StreamValue<int>();

  StreamValue<List<_EventModel>> get liveNowEventsStreamValue =>
      _scheduleRepository.liveNowEventsStreamValue;

  void hydrate() {
    _localCounterStreamValue.addValue(1);

    // expect_lint: controller_delegated_streamvalue_write_forbidden
    liveNowEventsStreamValue.addValue(const <_EventModel>[]);

    // expect_lint: controller_delegated_streamvalue_write_forbidden
    _scheduleRepository.liveNowEventsStreamValue.addValue(
      const <_EventModel>[],
    );
  }
}

class _DelegatedStreamValueWithFallbackController {
  final _ScheduleRepositoryContract _scheduleRepository = _ScheduleRepository();

  _ScheduleRepositoryContract? _resolveScheduleRepository() {
    return _scheduleRepository;
  }

  StreamValue<List<_EventModel>> get liveNowEventsStreamValue =>
      _resolveScheduleRepository()?.liveNowEventsStreamValue ??
      StreamValue<List<_EventModel>>();

  void hydrate() {
    // expect_lint: controller_delegated_streamvalue_write_forbidden
    liveNowEventsStreamValue.addValue(const <_EventModel>[]);
  }
}
