// ignore_for_file: unused_element

class _EventModel {
  const _EventModel();
}

abstract class _ScheduleRepositoryContract {
  Future<List<_EventModel>> fetchAgendaEvents();

  Future<bool> hasMoreEvents();

  Future<List<_EventModel>> getEventsPage({
    required int page,
    required int pageSize,
  });

  Future<void> refreshEventsPage();

  Future<void> refreshAgendaEvents();

  Future<void> refreshEventsWindow({required int pageSize});

  Future<void> fetchNextEventsPage();
}

class _FakeScheduleRepository implements _ScheduleRepositoryContract {
  @override
  Future<List<_EventModel>> fetchAgendaEvents() async => const <_EventModel>[];

  @override
  Future<bool> hasMoreEvents() async => true;

  @override
  Future<List<_EventModel>> getEventsPage({
    required int page,
    required int pageSize,
  }) async =>
      const <_EventModel>[];

  @override
  Future<void> refreshEventsPage() async {}

  @override
  Future<void> refreshAgendaEvents() async {}

  @override
  Future<void> refreshEventsWindow({required int pageSize}) async {}

  @override
  Future<void> fetchNextEventsPage() async {}
}

class _RepositoryAsyncFetchCaseController {
  final _scheduleRepository = _FakeScheduleRepository();

  Future<void> bad() async {
    // expect_lint: controller_repository_async_model_fetch_forbidden
    await _scheduleRepository.fetchAgendaEvents();
  }

  Future<void> badPayload() async {
    await _scheduleRepository.hasMoreEvents();
  }

  Future<void> badPagination() async {
    // expect_lint: controller_repository_async_model_fetch_forbidden, controller_repository_pagination_arguments_forbidden
    await _scheduleRepository.getEventsPage(page: 1, pageSize: 20);
  }

  Future<void> badPaginationSizeOnly() async {
    // expect_lint: controller_repository_pagination_arguments_forbidden
    await _scheduleRepository.refreshEventsWindow(pageSize: 20);
  }

  Future<void> good() async {
    await _scheduleRepository.refreshAgendaEvents();
    await _scheduleRepository.fetchNextEventsPage();
  }
}
