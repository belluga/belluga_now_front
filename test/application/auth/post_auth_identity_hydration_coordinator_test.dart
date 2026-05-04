import 'dart:async';

import 'package:belluga_now/application/auth/post_auth_identity_hydration_coordinator.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/user/value_objects/user_identity_state_value.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  test('hydrates identity-owned streams only after registered auth', () async {
    final authRepository = _FakeAuthRepository();
    final favoriteRepository = _FakeFavoriteRepository();
    final accountProfilesRepository = _FakeAccountProfilesRepository();
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final coordinator = PostAuthIdentityHydrationCoordinator(
      authRepository: authRepository,
      favoriteRepository: favoriteRepository,
      accountProfilesRepository: accountProfilesRepository,
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
    );

    coordinator.bind();
    authRepository.emit(_user(_anonymousUserId, 'anonymous'));
    await pumpEventQueue();

    expect(favoriteRepository.refreshFavoriteResumesCalls, 0);
    expect(accountProfilesRepository.refreshFavoriteAccountProfileIdsCalls, 0);
    expect(userEventsRepository.refreshConfirmedOccurrenceIdsCalls, 0);
    expect(invitesRepository.refreshPendingInvitesCalls, 0);

    authRepository.emit(_user(_registeredUserId, 'registered'));
    await pumpEventQueue();

    expect(favoriteRepository.refreshFavoriteResumesCalls, 1);
    expect(accountProfilesRepository.refreshFavoriteAccountProfileIdsCalls, 1);
    expect(userEventsRepository.refreshConfirmedOccurrenceIdsCalls, 1);
    expect(invitesRepository.refreshPendingInvitesCalls, 1);

    authRepository.emit(_user(_registeredUserId, 'registered'));
    await pumpEventQueue();

    expect(
      favoriteRepository.refreshFavoriteResumesCalls,
      1,
      reason: 'The same registered identity must not refetch in a loop.',
    );
    expect(accountProfilesRepository.refreshFavoriteAccountProfileIdsCalls, 1);
    expect(userEventsRepository.refreshConfirmedOccurrenceIdsCalls, 1);
    expect(invitesRepository.refreshPendingInvitesCalls, 1);

    coordinator.dispose();
  });

  test('rehydrates same user after anonymous reset during in-flight hydration',
      () async {
    final authRepository = _FakeAuthRepository();
    final refreshGate = Completer<void>();
    final accountProfilesRepository = _FakeAccountProfilesRepository(
      firstRefreshGate: refreshGate,
    );
    final coordinator = PostAuthIdentityHydrationCoordinator(
      authRepository: authRepository,
      accountProfilesRepository: accountProfilesRepository,
    );

    coordinator.bind();
    authRepository.emit(_user(_registeredUserId, 'registered'));
    await pumpEventQueue();

    expect(accountProfilesRepository.refreshFavoriteAccountProfileIdsCalls, 1);

    authRepository.emit(null);
    await pumpEventQueue();
    refreshGate.complete();
    await pumpEventQueue();

    authRepository.emit(_user(_registeredUserId, 'registered'));
    await pumpEventQueue();

    expect(
      accountProfilesRepository.refreshFavoriteAccountProfileIdsCalls,
      2,
      reason: 'Logout/anonymous reset must clear the per-user hydration guard.',
    );

    coordinator.dispose();
  });
}

const _anonymousUserId = '507f1f77bcf86cd799439011';
const _registeredUserId = '507f1f77bcf86cd799439012';

UserBelluga _user(String id, String identityState) {
  return UserBelluga(
    uuidValue: MongoIDValue(defaultValue: id)..parse(id),
    profile: UserProfileContract(),
    customData: UserCustomData(
      identityStateValue: UserIdentityStateValue.fromRaw(identityState),
    ),
  );
}

class _FakeAuthRepository extends AuthRepositoryContract<UserBelluga> {
  @override
  Object get backend => Object();

  @override
  String get userToken => 'token';

  @override
  bool get isUserLoggedIn => userStreamValue.value != null;

  @override
  bool get isAuthorized =>
      userStreamValue.value != null &&
      !(userStreamValue.value?.customData?.isAnonymous ?? false);

  void emit(UserBelluga? user) {
    userStreamValue.addValue(user);
  }

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => userStreamValue.value?.uuidValue.value;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<AuthPhoneOtpChallenge> requestPhoneOtpChallenge(
    AuthRepositoryContractParamString phone, {
    AuthRepositoryContractParamString? deliveryChannel,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  void setUserToken(AuthRepositoryContractTextValue? token) {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}

  @override
  Future<void> verifyPhoneOtpChallenge({
    required AuthRepositoryContractParamString challengeId,
    required AuthRepositoryContractParamString phone,
    required AuthRepositoryContractParamString code,
  }) async {}
}

class _FakeFavoriteRepository extends FavoriteRepositoryContract {
  int refreshFavoriteResumesCalls = 0;

  @override
  Future<List<Favorite>> fetchFavorites() async => const <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async =>
      const <FavoriteResume>[];

  @override
  Future<void> refreshFavoriteResumes() async {
    refreshFavoriteResumesCalls += 1;
    await super.refreshFavoriteResumes();
  }
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({Completer<void>? firstRefreshGate})
      : _firstRefreshGate = firstRefreshGate;

  Completer<void>? _firstRefreshGate;
  int refreshFavoriteAccountProfileIdsCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> refreshFavoriteAccountProfileIds() async {
    refreshFavoriteAccountProfileIdsCalls += 1;
    final refreshGate = _firstRefreshGate;
    if (refreshGate != null) {
      _firstRefreshGate = null;
      await refreshGate.future;
    }
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) {
    throw UnimplementedError();
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() =>
      const <AccountProfileModel>[];

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async =>
      null;

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) =>
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  int refreshConfirmedOccurrenceIdsCalls = 0;

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {
    refreshConfirmedOccurrenceIdsCalls += 1;
  }

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async =>
      const <VenueEventResume>[];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async =>
      const <VenueEventResume>[];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString occurrenceId,
  ) =>
      userEventsRepoBool(false);

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int refreshPendingInvitesCalls = 0;

  @override
  Future<void> refreshPendingInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    refreshPendingInvitesCalls += 1;
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      const <InviteModel>[];

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async =>
      const <InviteContactMatch>[];

  @override
  Future<InviteRuntimeSettings> fetchSettings() {
    throw UnimplementedError();
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async =>
      const <SentInviteStatus>[];

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}
}
