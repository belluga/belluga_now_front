// ignore_for_file: unused_element

abstract class _UserEventsRepositoryContract {
  Future<void> confirmEventAttendance();

  Future<void> refreshConfirmedOccurrenceIds();
}

abstract class _InvitesRepositoryContract {
  Future<void> acceptInvite();

  Future<void> refreshPendingInvites();
}

class _FakeUserEventsRepository implements _UserEventsRepositoryContract {
  @override
  Future<void> confirmEventAttendance() async {}

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {}
}

class _FakeInvitesRepository implements _InvitesRepositoryContract {
  @override
  Future<void> acceptInvite() async {}

  @override
  Future<void> refreshPendingInvites() async {}
}

class _CanonicalStateRepairAfterMutationCaseController {
  final _userEventsRepository = _FakeUserEventsRepository();
  final _invitesRepository = _FakeInvitesRepository();

  Future<void> badDirectRepair() async {
    await _userEventsRepository.confirmEventAttendance();
    // expect_lint: controller_canonical_state_repair_after_mutation_forbidden
    await _invitesRepository.refreshPendingInvites();
  }

  Future<void> badHelperRepair() async {
    await _invitesRepository.acceptInvite();
    // expect_lint: controller_canonical_state_repair_after_mutation_forbidden
    await _refreshConfirmationState();
  }

  Future<void> _refreshConfirmationState() async {
    await _userEventsRepository.refreshConfirmedOccurrenceIds();
  }

  Future<void> good() async {
    await _userEventsRepository.confirmEventAttendance();
  }
}
