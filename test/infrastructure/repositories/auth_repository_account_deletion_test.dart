import 'dart:async';

import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'user_token': 'registered-token',
      'user_id': 'registered-user',
      'device_id': 'old-device',
    });
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'confirmed deletion clears identity and blocks automatic bootstrap',
    () async {
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        identityValidationResult: const CurrentIdentityValidationUncertain(),
      );
      GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final outcome = await repository.deleteCurrentAccount();
      await Future<void>.delayed(Duration.zero);
      await repository.ensureTenantPublicIdentityReady();

      expect(outcome, AccountDeletionDispatchOutcome.confirmed);
      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.confirmed,
      );
      expect(repository.userToken, isEmpty);
      expect(await AuthRepository.storage.read(key: 'user_token'), isNull);
      expect(auth.issueAnonymousIdentityCount, 0);
    },
  );

  test(
    'deleting blocks anonymous bootstrap while the current token is cleared',
    () async {
      final deletionResponse = Completer<CurrentAccountDeletionBackendResult>();
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        deletionResponse: deletionResponse.future,
        identityValidationResult: const CurrentIdentityValidationUncertain(),
      );
      GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final deletion = repository.deleteCurrentAccount();
      repository.userTokenUpdate('');
      await repository.ensureTenantPublicIdentityReady();

      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.deleting,
      );
      expect(auth.issueAnonymousIdentityCount, 0);

      deletionResponse.complete(const CurrentAccountDeletionSucceeded());
      await deletion;

      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.confirmed,
      );
    },
  );

  test('pre-erase rejection preserves the active identity', () async {
    final auth = _FakeAuthBackend(
      deletionResult: const CurrentAccountDeletionPreEraseRejected(409),
      identityValidationResult: const CurrentIdentityValidationUncertain(),
    );
    GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
    final repository = AuthRepository();
    repository.userTokenUpdate('registered-token');

    final outcome = await repository.deleteCurrentAccount();

    expect(outcome, AccountDeletionDispatchOutcome.preEraseRejected);
    expect(repository.userToken, 'registered-token');
    expect(
      repository.accountDeletionJourneyState.phase,
      AccountDeletionJourneyPhase.idle,
    );
  });

  test(
    'unknown deletion outcome blocks bootstrap until terminal absence',
    () async {
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionUnknown(),
        identityValidationResult:
            const CurrentIdentityValidationTerminalAbsent(),
      );
      GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final outcome = await repository.deleteCurrentAccount();
      await repository.ensureTenantPublicIdentityReady();

      expect(outcome, AccountDeletionDispatchOutcome.unknown);
      expect(auth.issueAnonymousIdentityCount, 0);
      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.unknown,
      );

      await repository.reconcileUnknownAccountDeletion();

      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.confirmed,
      );
      expect(repository.userToken, isEmpty);
    },
  );

  test(
    'local teardown failure remains unknown and blocks anonymous continuation',
    () async {
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        identityValidationResult:
            const CurrentIdentityValidationTerminalAbsent(),
      );
      GetIt.I
        ..registerSingleton<BackendContract>(_FakeBackend(auth))
        ..registerSingleton<ProfileAvatarStorageContract>(
          _ThrowingProfileAvatarStorage(),
        );
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final outcome = await repository.deleteCurrentAccount();
      await repository.ensureTenantPublicIdentityReady();

      expect(outcome, AccountDeletionDispatchOutcome.unknown);
      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.unknown,
      );
      expect(auth.issueAnonymousIdentityCount, 0);
      expect(
        await repository.continueAnonymouslyAfterConfirmedAccountDeletion(),
        AccountDeletionContinuationOutcome.unavailable,
      );
    },
  );

  test('secure-storage teardown failure remains unknown', () async {
    final auth = _FakeAuthBackend(
      deletionResult: const CurrentAccountDeletionSucceeded(),
      identityValidationResult: const CurrentIdentityValidationTerminalAbsent(),
    );
    GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
    final repository = AuthRepository(storage: _ThrowingDeleteStorage());
    repository.userTokenUpdate('registered-token');

    final outcome = await repository.deleteCurrentAccount();
    await repository.ensureTenantPublicIdentityReady();

    expect(outcome, AccountDeletionDispatchOutcome.unknown);
    expect(
      repository.accountDeletionJourneyState.phase,
      AccountDeletionJourneyPhase.unknown,
    );
    expect(auth.issueAnonymousIdentityCount, 0);
  });

  test(
    'registered cleanup dependencies are awaited before confirmed',
    () async {
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        identityValidationResult:
            const CurrentIdentityValidationTerminalAbsent(),
      );
      final contactsCache = _FakeContactsLocalCache();
      GetIt.I
        ..registerSingleton<BackendContract>(_FakeBackend(auth))
        ..registerSingleton<ContactsRepositoryContract>(
          ContactsRepository(localCache: contactsCache),
        );
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final outcome = await repository.deleteCurrentAccount();

      expect(outcome, AccountDeletionDispatchOutcome.confirmed);
      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.confirmed,
      );
      expect(contactsCache.clearCount, 1);
    },
  );

  test(
    'non-terminal reconciliation results preserve unknown and block bootstrap',
    () async {
      final validUser = UserDto(
        id: 'registered-user',
        profile: UserProfileDto(
          name: 'Registered',
          email: 'registered@example.com',
          birthday: '',
          pictureUrl: null,
        ),
        customData: const <String, dynamic>{},
      );
      for (final identityValidationResult in <CurrentIdentityValidationResult>[
        CurrentIdentityValidationValid(validUser),
        const CurrentIdentityValidationUncertain(),
      ]) {
        final auth = _FakeAuthBackend(
          deletionResult: const CurrentAccountDeletionUnknown(),
          identityValidationResult: identityValidationResult,
        );
        await GetIt.I.reset();
        GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
        final repository = AuthRepository();
        repository.userTokenUpdate('registered-token');

        await repository.deleteCurrentAccount();
        await repository.reconcileUnknownAccountDeletion();
        await repository.ensureTenantPublicIdentityReady();

        expect(
          repository.accountDeletionJourneyState.phase,
          AccountDeletionJourneyPhase.unknown,
        );
        expect(auth.issueAnonymousIdentityCount, 0);
      }
    },
  );

  test(
    'deletion dispatch drops duplicate triggers while the request is in flight',
    () async {
      final deletionResponse = Completer<CurrentAccountDeletionBackendResult>();
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        deletionResponse: deletionResponse.future,
        identityValidationResult: const CurrentIdentityValidationUncertain(),
      );
      GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      final requests = List<Future<AccountDeletionDispatchOutcome>>.generate(
        20,
        (_) => repository.deleteCurrentAccount(),
      );

      expect(auth.deleteCurrentAccountCallCount, 1);
      deletionResponse.complete(const CurrentAccountDeletionSucceeded());
      expect(
        await Future.wait(requests),
        everyElement(AccountDeletionDispatchOutcome.confirmed),
      );
    },
  );

  test(
    'explicit continuation rotates device and starts a new anonymous identity',
    () async {
      final auth = _FakeAuthBackend(
        deletionResult: const CurrentAccountDeletionSucceeded(),
        identityValidationResult: const CurrentIdentityValidationUncertain(),
      );
      GetIt.I.registerSingleton<BackendContract>(_FakeBackend(auth));
      final repository = AuthRepository();
      repository.userTokenUpdate('registered-token');

      await repository.deleteCurrentAccount();
      final result = await repository
          .continueAnonymouslyAfterConfirmedAccountDeletion();

      expect(result, AccountDeletionContinuationOutcome.continued);
      expect(repository.userToken, 'anonymous-token');
      expect(
        await AuthRepository.storage.read(key: 'device_id'),
        isNot('old-device'),
      );
      expect(
        repository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.idle,
      );
    },
  );
}

class _FakeAuthBackend extends AuthBackendContract {
  _FakeAuthBackend({
    required this.deletionResult,
    this.deletionResponse,
    required this.identityValidationResult,
  });

  final CurrentAccountDeletionBackendResult deletionResult;
  final Future<CurrentAccountDeletionBackendResult>? deletionResponse;
  final CurrentIdentityValidationResult identityValidationResult;
  int issueAnonymousIdentityCount = 0;
  int deleteCurrentAccountCallCount = 0;

  @override
  Future<CurrentAccountDeletionBackendResult> deleteCurrentAccount() =>
      (deleteCurrentAccountCallCount += 1) == 1
      ? deletionResponse ?? Future.value(deletionResult)
      : Future.error(StateError('Duplicate deletion dispatch'));

  @override
  Future<CurrentIdentityValidationResult>
  validateCurrentIdentityForDeletionResolution() async =>
      identityValidationResult;

  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) async {
    issueAnonymousIdentityCount += 1;
    return const AnonymousIdentityResponse(
      token: 'anonymous-token',
      userId: 'anonymous-user',
      identityState: 'anonymous',
    );
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<UserDto> loginCheck() async => UserDto(
    id: 'registered-user',
    profile: UserProfileDto(
      name: 'Registered',
      email: 'registered@example.com',
      birthday: '',
      pictureUrl: null,
    ),
    customData: const <String, dynamic>{},
  );

  @override
  Future<void> logout() async {}

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) => throw UnimplementedError();
}

class _ThrowingProfileAvatarStorage extends ProfileAvatarStorageContract {
  @override
  Future<void> clearAvatarPath() => Future<void>.error(StateError('disk full'));

  @override
  Future<ProfileAvatarPathValue?> readAvatarPath() =>
      throw UnimplementedError();

  @override
  Future<void> writeAvatarPath(ProfileAvatarPathValue path) =>
      throw UnimplementedError();
}

class _ThrowingDeleteStorage extends FlutterSecureStorage {
  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) => Future<void>.error(StateError('secure storage unavailable'));
}

class _FakeContactsLocalCache implements ContactsLocalCacheContract {
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
  }

  @override
  Future<List<ContactModel>?> read() async => null;

  @override
  Future<void> write(List<ContactModel> contacts) async {}
}

class _FakeBackend extends BackendContract {
  _FakeBackend(this.auth);

  @override
  final AuthBackendContract auth;

  @override
  BackendContext? get context => null;

  @override
  void setContext(BackendContext context) {}

  @override
  AppDataBackendContract get appData => throw UnimplementedError();

  @override
  TenantBackendContract get tenant => throw UnimplementedError();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      throw UnimplementedError();

  @override
  FavoriteBackendContract get favorites => throw UnimplementedError();

  @override
  VenueEventBackendContract get venueEvents => throw UnimplementedError();

  @override
  ScheduleBackendContract get schedule => throw UnimplementedError();
}
