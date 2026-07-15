import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_confirmed_events_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_pending_invites_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

import 'support/integration_test_bootstrap.dart';

/// Exercises the user-visible deletion entry point and the actual generated
/// resolution route. Backend results are deliberately fake here: endpoint
/// semantics have their own real-backend integration proof.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async => GetIt.I.reset());
  tearDown(() async => GetIt.I.reset());

  for (final scenario in <_JourneyScenario>[
    const _JourneyScenario(
      outcome: AccountDeletionDispatchOutcome.confirmed,
      expectedResolution: 'Conta removida',
    ),
    const _JourneyScenario(
      outcome: AccountDeletionDispatchOutcome.unknown,
      expectedResolution: 'Não foi possível confirmar a remoção',
    ),
  ]) {
    testWidgets(
      'Profile deletion confirmation replaces the stack with the ${scenario.outcome.name} resolution boundary',
      (tester) async {
        final authRepository = _JourneyAuthRepository(
          initialUser: _buildUser(),
          outcome: scenario.outcome,
        );
        final controller = ProfileScreenController(
          authRepository: authRepository,
          appDataRepository: _JourneyAppDataRepository(),
          avatarStorage: _JourneyAvatarStorage(),
          selfProfileRepository: _JourneySelfProfileRepository(
            initialProfile: _buildSelfProfile(),
          ),
          inviteablesRepository: _JourneyInviteablesRepository(),
        );
        GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
        GetIt.I.registerSingleton<ProfileScreenController>(controller);

        final router = RootStackRouter.build(
          routes: <AutoRoute>[
            NamedRouteDef(
              name: 'profile-deletion-journey-entry',
              path: '/',
              meta: canonicalRouteMeta(
                family: CanonicalRouteFamily.profileRoot,
              ),
              builder: (_, _) => const ProfileScreen(),
            ),
            AutoRoute(
              path: '/account-deletion-resolution',
              page: AccountDeletionResolutionRoute.page,
              meta: canonicalRouteMeta(
                family: CanonicalRouteFamily.accountDeletionResolution,
              ),
            ),
          ],
        )..ignorePopCompleters = true;

        await tester.pumpWidget(
          MaterialApp.router(
            routeInformationParser: router.defaultRouteParser(),
            routerDelegate: router.delegate(),
          ),
        );
        await tester.pumpAndSettle();

        final entry = find.byKey(const Key('profileDeleteAccountEntry'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('profileConfirmDeleteAccountButton')),
        );
        await tester.pumpAndSettle();

        expect(authRepository.deleteCallCount, 1);
        expect(find.text('Perfil'), findsNothing);
        expect(find.text(scenario.expectedResolution), findsOneWidget);
        expect(router.stack.length, 1);
        expect(router.topRoute.name, AccountDeletionResolutionRoute.name);
      },
    );
  }
}

class _JourneyScenario {
  const _JourneyScenario({
    required this.outcome,
    required this.expectedResolution,
  });

  final AccountDeletionDispatchOutcome outcome;
  final String expectedResolution;
}

class _JourneyAuthRepository extends AuthRepositoryContract<UserContract> {
  _JourneyAuthRepository({
    required UserContract initialUser,
    required this.outcome,
  }) {
    userStreamValue.addValue(initialUser);
  }

  final AccountDeletionDispatchOutcome outcome;
  int deleteCallCount = 0;

  @override
  final BackendContract backend = _JourneyBackendContract();

  @override
  String get userToken => 'journey-token';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'journey-device';

  @override
  Future<String?> getUserId() async =>
      userStreamValue.value?.uuidValue.value.toString();

  @override
  bool get isUserLoggedIn => userStreamValue.value != null;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<AccountDeletionDispatchOutcome> deleteCurrentAccount() async {
    deleteCallCount += 1;
    accountDeletionJourneyStreamValue.addValue(
      AccountDeletionJourneyState(
        outcome == AccountDeletionDispatchOutcome.confirmed
            ? AccountDeletionJourneyPhase.confirmed
            : AccountDeletionJourneyPhase.unknown,
      ),
    );
    return outcome;
  }

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
  Future<void> logout() async {}

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

class _JourneyBackendContract extends Fake implements BackendContract {}

class _JourneyAppDataRepository extends AppDataRepositoryContract {
  _JourneyAppDataRepository()
    : themeModeStreamValue = StreamValue<ThemeMode?>(
        defaultValue: ThemeMode.light,
      ),
      maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(5000, defaultValue: 5000),
      );

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  AppData get appData => _JourneyAppData();

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(5000, defaultValue: 5000);

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}
}

class _JourneyAppData extends Fake implements AppData {}

class _JourneyAvatarStorage implements ProfileAvatarStorageContract {
  @override
  Future<void> clearAvatarPath() async {}

  @override
  Future<ProfileAvatarPathValue?> readAvatarPath() async => null;

  @override
  Future<void> writeAvatarPath(ProfileAvatarPathValue path) async {}
}

class _JourneySelfProfileRepository extends SelfProfileRepositoryContract {
  _JourneySelfProfileRepository({required this.initialProfile}) {
    currentProfileStreamValue.addValue(initialProfile);
  }

  final SelfProfile initialProfile;

  @override
  Future<SelfProfile> fetchCurrentProfile() async => initialProfile;

  @override
  Future<SelfProfile> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  }) async => initialProfile;
}

class _JourneyInviteablesRepository extends InviteablesRepositoryContract {}

class _JourneyUser implements UserContract {
  _JourneyUser({required this.uuidValue, required this.profile});

  @override
  final MongoIDValue uuidValue;

  @override
  final UserProfileContract profile;

  @override
  UserCustomData? customData;

  @override
  Future<void> updateCustomData(UserCustomData newCustomData) async {
    customData = newCustomData;
  }
}

UserContract _buildUser() => _JourneyUser(
  uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
  profile: UserProfileContract(
    nameValue: FullNameValue()..parse('Journey User'),
    emailValue: EmailAddressValue()..parse('journey@example.test'),
  ),
);

SelfProfile _buildSelfProfile() {
  final accountProfileId = InviteAccountProfileIdValue(
    isRequired: false,
    minLenght: null,
  )..parse('journey-profile');
  return SelfProfile(
    userIdValue: UserIdValue()..parse('507f1f77bcf86cd799439011'),
    accountProfileIdValue: accountProfileId,
    displayNameValue: UserDisplayNameValue(isRequired: false, minLenght: null)
      ..parse('Journey User'),
    bioValue: DescriptionValue(defaultValue: '', minLenght: null)..parse(''),
    phoneValue: AuthPhoneOtpPhoneValue(isRequired: false, minLenght: null)
      ..parse('+5527999991111'),
    avatarValue: UserAvatarValue(),
    pendingInvitesCountValue: SelfProfilePendingInvitesCountValue()..set(0),
    confirmedEventsCountValue: SelfProfileConfirmedEventsCountValue()..set(0),
  );
}
