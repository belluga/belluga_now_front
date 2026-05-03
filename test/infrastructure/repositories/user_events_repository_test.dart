import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/services/user_events_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshConfirmedOccurrenceIds stores canonical occurrence ids',
      () async {
    final backend = _FakeUserEventsBackend(
      response: const {
        'confirmed_occurrence_ids': ['occ-1', '', 'occ-2'],
      },
    );
    final repository = UserEventsRepository(
      scheduleRepository: _FakeScheduleRepository(),
      backend: backend,
    );

    await repository.refreshConfirmedOccurrenceIds();

    final confirmed = repository.confirmedOccurrenceIdsStream.value
        .map((entry) => entry.value)
        .toSet();
    expect(confirmed, {'occ-1', 'occ-2'});
    expect(
      repository.isOccurrenceConfirmed(
        userEventsRepoString('occ-2', defaultValue: '', isRequired: true),
      ).value,
      isTrue,
    );
  });

  test('refreshConfirmedOccurrenceIds fails loudly on stale response shape',
      () async {
    final backend = _FakeUserEventsBackend(
      response: const {
        'confirmed_occurrence_ids': ['occ-1'],
      },
    );
    final repository = UserEventsRepository(
      scheduleRepository: _FakeScheduleRepository(),
      backend: backend,
    );

    await repository.refreshConfirmedOccurrenceIds();
    backend.response = const {
      'event_ids': ['legacy-event-id'],
    };

    expect(
      repository.refreshConfirmedOccurrenceIds(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('confirmed_occurrence_ids'),
        ),
      ),
    );
    expect(
      repository.confirmedOccurrenceIdsStream.value
          .map((entry) => entry.value)
          .toSet(),
      {'occ-1'},
    );
  });
}

class _FakeUserEventsBackend implements UserEventsBackendContract {
  _FakeUserEventsBackend({required this.response});

  Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> fetchConfirmedOccurrenceIds() async => response;

  @override
  Future<Map<String, dynamic>> confirmAttendance({
    required String eventId,
    required String occurrenceId,
  }) async =>
      response;

  @override
  Future<Map<String, dynamic>> unconfirmAttendance({
    required String eventId,
    required String occurrenceId,
  }) async =>
      response;
}

class _FakeScheduleRepository extends Fake
    implements ScheduleRepositoryContract {}
