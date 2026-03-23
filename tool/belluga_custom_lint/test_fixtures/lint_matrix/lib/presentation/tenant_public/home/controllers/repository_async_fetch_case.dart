// ignore_for_file: unused_element

class _EventModel {
  const _EventModel();
}

abstract class _ScheduleRepositoryContract {
  Future<List<_EventModel>> fetchAgendaEvents();

  Future<void> refreshAgendaEvents();
}

class _FakeScheduleRepository implements _ScheduleRepositoryContract {
  @override
  Future<List<_EventModel>> fetchAgendaEvents() async => const <_EventModel>[];

  @override
  Future<void> refreshAgendaEvents() async {}
}

class _RepositoryAsyncFetchCaseController {
  final _scheduleRepository = _FakeScheduleRepository();

  Future<void> bad() async {
    // expect_lint: controller_repository_async_model_fetch_forbidden
    await _scheduleRepository.fetchAgendaEvents();
  }

  Future<void> good() async {
    await _scheduleRepository.refreshAgendaEvents();
  }
}
