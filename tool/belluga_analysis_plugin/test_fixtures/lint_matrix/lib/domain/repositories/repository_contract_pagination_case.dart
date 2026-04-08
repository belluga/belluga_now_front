// ignore_for_file: unused_element

abstract class _ScheduleRepositoryContract {
  Future<void> refreshAgenda();

  // expect_lint: repository_contract_pagination_controls_forbidden
  Future<void> loadNextAgendaPage();

  // expect_lint: repository_contract_pagination_controls_forbidden
  bool hasMoreAgenda();

  Future<void> bad({
    // expect_lint: repository_contract_pagination_controls_forbidden
    required int page,
    // expect_lint: repository_contract_pagination_controls_forbidden
    required int pageSize,
  });

  Future<void> badCursor({
    // expect_lint: repository_contract_pagination_controls_forbidden
    required String cursor,
  });
}
