import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
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
      repository
          .isOccurrenceConfirmed(
            userEventsRepoString('occ-2', defaultValue: '', isRequired: true),
          )
          .value,
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

  test('fetchMyEvents skips confirmed query when identity is anonymous',
      () async {
    final scheduleRepository = _FakeScheduleRepository();
    final repository = UserEventsRepository(
      scheduleRepository: scheduleRepository,
      backend: _FakeUserEventsBackend(response: const {}),
      authRepository: _FakeAuthRepository(authorized: false),
    );

    final events = await repository.fetchMyEvents();

    expect(events, isEmpty);
    expect(scheduleRepository.loadConfirmedEventsCallCount, 0);
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
    implements ScheduleRepositoryContract {
  int loadConfirmedEventsCallCount = 0;

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async {
    loadConfirmedEventsCallCount += 1;
    return const <EventModel>[];
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({required bool authorized}) : _authorized = authorized;

  bool _authorized;

  @override
  Object get backend => throw UnimplementedError();

  @override
  String get userToken => _authorized ? 'token' : '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => _authorized ? 'user-1' : null;

  @override
  bool get isUserLoggedIn => _authorized;

  @override
  bool get isAuthorized => _authorized;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {
    _authorized = false;
    userStreamValue.addValue(null);
  }

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}
