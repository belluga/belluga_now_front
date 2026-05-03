import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
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
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'profile runtime keeps release-visible contract and rehydrates persisted name after reopen',
    (tester) async {
      final profileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Alice Smith',
          bio: 'Bio inicial',
          phone: '+5527999991111',
          pendingInvitesCount: 3,
          confirmedEventsCount: 5,
        ),
      );

      final firstController = _buildController(
        selfProfileRepository: profileRepository,
      );
      await _pumpProfileScreen(tester, controller: firstController);
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsNothing);
      expect(find.text('Visibilidade'), findsNothing);
      expect(find.text('Alterar senha'), findsNothing);
      expect(find.text('Pessoas'), findsNothing);
      expect(find.text('Alterado'), findsNothing);
      expect(find.text('Telefone'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('profile-radius-expanded')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-radius-expanded')),
      );
      await tester.pumpAndSettle();

      expect(find.text('50 km'), findsOneWidget);
      expect(find.text('100 km'), findsNothing);
      await AutoRouter.of(
        tester.element(find.text('Salvar').last),
      ).maybePop();
      await tester.pumpAndSettle();

      final originTile = find.byKey(const Key('profileOriginPreferenceTile'));
      await tester.ensureVisible(originTile);
      await tester.tap(originTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fixa'));
      await tester.pumpAndSettle();

      expect(find.text('Selecionar no mapa'), findsOneWidget);
      expect(find.byKey(const Key('profileSaveOriginPreferenceButton')),
          findsOneWidget);
      await AutoRouter.of(
        tester.element(find.text('Salvar origem')),
      ).maybePop();
      await tester.pumpAndSettle();

      firstController.nameController.text = 'Alice Persistida';
      await firstController.saveProfile();
      firstController.bumpFormVersion();
      await tester.pumpAndSettle();

      expect(profileRepository.lastDisplayNameValue?.value, 'Alice Persistida');
      expect(find.text('Alice Persistida'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await GetIt.I.reset();

      profileRepository.fetchCompleter = Completer<SelfProfile>();
      final secondController = _buildController(
        selfProfileRepository: profileRepository,
      );
      await _pumpProfileScreen(tester, controller: secondController);
      await tester.pump();

      expect(find.text('Alice Persistida'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      profileRepository.fetchCompleter!.complete(profileRepository.current);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'profile runtime shows friendly save failures without raw backend text',
    (tester) async {
      final profileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Alice Smith',
          bio: 'Bio inicial',
          phone: '+5527999991111',
        ),
      )..updateError = StateError('HTTP 422 profile endpoint exploded');

      final controller = _buildController(
        selfProfileRepository: profileRepository,
      );
      await _pumpProfileScreen(tester, controller: controller);
      await tester.pumpAndSettle();

      controller.nameController.text = 'Alice Erro';
      await expectLater(
        controller.saveProfile(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Nao foi possivel salvar o perfil agora. Tente novamente.',
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'profile runtime keeps successful save when avatar cleanup fails locally',
    (tester) async {
      final avatarStorage = _FakeProfileAvatarStorage(throwOnClear: true);
      final profileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Alice Smith',
          bio: 'Bio inicial',
          phone: '+5527999991111',
        ),
      );

      final controller = _buildController(
        selfProfileRepository: profileRepository,
        avatarStorage: avatarStorage,
      );
      await _pumpProfileScreen(tester, controller: controller);
      await tester.pumpAndSettle();

      controller.nameController.text = 'Alice Persistida';
      await controller.saveProfile();
      await tester.pumpAndSettle();

      expect(profileRepository.lastDisplayNameValue?.value, 'Alice Persistida');
      expect(find.text('Alice Persistida'), findsWidgets);
    },
  );
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    UserContract? initialUser,
  }) {
    userStreamValue.addValue(initialUser);
  }

  @override
  final BackendContract backend = _FakeBackendContract();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'profile-device';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => userStreamValue.value != null;

  @override
  bool get isAuthorized => true;

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

class _FakeBackendContract extends Fake implements BackendContract {}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    ThemeMode? initialThemeMode,
    double initialMaxRadiusMeters = 5000,
  })  : _themeMode = initialThemeMode ?? ThemeMode.light,
        _maxRadiusMeters = initialMaxRadiusMeters,
        themeModeStreamValue =
            StreamValue<ThemeMode?>(defaultValue: initialThemeMode),
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
          defaultValue: DistanceInMetersValue.fromRaw(
            initialMaxRadiusMeters,
            defaultValue: initialMaxRadiusMeters,
          ),
        );

  ThemeMode _themeMode;
  double _maxRadiusMeters;
  final AppData _appData = _FakeAppData();

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  AppData get appData => _appData;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  DistanceInMetersValue get maxRadiusMeters => DistanceInMetersValue.fromRaw(
        _maxRadiusMeters,
        defaultValue: _maxRadiusMeters,
      );

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    _themeMode = mode.value;
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMeters = meters.value;
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeAppData extends Fake implements AppData {}

class _FakeProfileAvatarStorage implements ProfileAvatarStorageContract {
  _FakeProfileAvatarStorage({
    this.throwOnClear = false,
  });

  String? _path;
  bool throwOnClear;

  @override
  Future<ProfileAvatarPathValue?> readAvatarPath() async =>
      _path == null ? null : ProfileAvatarPathValue.fromRaw(_path);

  @override
  Future<void> writeAvatarPath(ProfileAvatarPathValue path) async {
    _path = path.value;
  }

  @override
  Future<void> clearAvatarPath() async {
    if (throwOnClear) {
      throw StateError('secure storage delete failed');
    }
    _path = null;
  }
}

class _FakeSelfProfileRepository extends SelfProfileRepositoryContract {
  _FakeSelfProfileRepository({
    required SelfProfile initialProfile,
  }) : _profile = initialProfile {
    currentProfileStreamValue.addValue(initialProfile);
  }

  SelfProfile _profile;
  UserDisplayNameValue? lastDisplayNameValue;
  DescriptionValue? lastBioValue;
  Object? updateError;
  Completer<SelfProfile>? fetchCompleter;

  SelfProfile get current => _profile;

  @override
  Future<SelfProfile> fetchCurrentProfile() async {
    if (fetchCompleter != null) {
      final profile = await fetchCompleter!.future;
      _profile = profile;
      currentProfileStreamValue.addValue(profile);
      return profile;
    }
    currentProfileStreamValue.addValue(_profile);
    return _profile;
  }

  @override
  Future<SelfProfile> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  }) async {
    if (updateError != null) {
      throw updateError!;
    }

    lastDisplayNameValue = displayNameValue;
    lastBioValue = bioValue;
    _profile = _buildSelfProfile(
      userId: _profile.userId,
      accountProfileId: _profile.accountProfileId,
      displayName: displayNameValue?.value ?? _profile.displayName,
      bio: bioValue?.value ?? _profile.bio,
      phone: _profile.phone,
      avatarUrl: _profile.avatarUrl,
      pendingInvitesCount: _profile.pendingInvitesCount,
      confirmedEventsCount: _profile.confirmedEventsCount,
      timezone: timezoneValue?.value ?? _profile.timezone,
    );
    currentProfileStreamValue.addValue(_profile);
    return _profile;
  }
}

class _FakeProximityPreferencesRepository
    extends ProximityPreferencesRepositoryContract {}

class _FakeUser implements UserContract {
  _FakeUser({
    required this.uuidValue,
    required this.profile,
  });

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

class _RecordingStackRouter extends Mock implements StackRouter {
  @override
  RootStackRouter get root => _FakeRootStackRouter('/profile');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) =>
      false;

  @override
  void pop<T extends Object?>([T? result]) {}

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {}
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
  });

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => const ProfileRoute();
}

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required ProfileScreenController controller,
}) async {
  final router = _RecordingStackRouter();
  GetIt.I.registerSingleton<ProfileScreenController>(controller);

  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: ProfileRoute.name,
      fullPath: '/profile',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.profileRoot,
      ),
    ),
    router: router,
    stackKey: const ValueKey<String>('profile-stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );

  await tester.pumpWidget(
    StackRouterScope(
      controller: router,
      stateHash: 0,
      child: MaterialApp(
        home: RouteDataScope(
          routeData: routeData,
          child: const ProfileScreen(),
        ),
      ),
    ),
  );
}

ProfileScreenController _buildController({
  required _FakeSelfProfileRepository selfProfileRepository,
  ProfileAvatarStorageContract? avatarStorage,
}) {
  return ProfileScreenController(
    authRepository: _FakeAuthRepository(
      initialUser: _buildUser(),
    ),
    appDataRepository: _FakeAppDataRepository(),
    avatarStorage: avatarStorage ?? _FakeProfileAvatarStorage(),
    selfProfileRepository: selfProfileRepository,
    invitesRepository: _StubInvitesRepository(),
    proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
  );
}

UserContract _buildUser() {
  return _FakeUser(
    uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    profile: UserProfileContract(
      nameValue: FullNameValue()..parse('Alice Smith'),
      emailValue: EmailAddressValue()..parse('alice@example.com'),
    ),
  );
}

SelfProfile _buildSelfProfile({
  required String userId,
  required String accountProfileId,
  String displayName = 'Alice Smith',
  String bio = '',
  String phone = '',
  String? avatarUrl,
  int pendingInvitesCount = 0,
  int confirmedEventsCount = 0,
  String? timezone,
}) {
  final userIdValue = UserIdValue()..parse(userId);
  final accountProfileIdValue = InviteAccountProfileIdValue(
    isRequired: false,
    minLenght: null,
  );
  if (accountProfileId.isNotEmpty) {
    accountProfileIdValue.parse(accountProfileId);
  }
  final displayNameValue =
      UserDisplayNameValue(isRequired: false, minLenght: null)
        ..parse(displayName);
  final bioValue = DescriptionValue(defaultValue: '', minLenght: null)
    ..parse(bio);
  final phoneValue = AuthPhoneOtpPhoneValue(isRequired: false, minLenght: null)
    ..parse(phone);
  final avatarValue = UserAvatarValue();
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    avatarValue.parse(avatarUrl);
  }
  final pendingInvitesCountValue = SelfProfilePendingInvitesCountValue()
    ..set(pendingInvitesCount);
  final confirmedEventsCountValue = SelfProfileConfirmedEventsCountValue()
    ..set(confirmedEventsCount);
  final timezoneValue = UserTimezoneValue();
  if (timezone != null && timezone.isNotEmpty) {
    timezoneValue.parse(timezone);
  }
  return SelfProfile(
    userIdValue: userIdValue,
    accountProfileIdValue: accountProfileIdValue,
    displayNameValue: displayNameValue,
    bioValue: bioValue,
    phoneValue: phoneValue,
    avatarValue: avatarValue,
    pendingInvitesCountValue: pendingInvitesCountValue,
    confirmedEventsCountValue: confirmedEventsCountValue,
    timezoneValue: timezoneValue,
  );
}

class _StubInvitesRepository extends Fake
    implements InvitesRepositoryContract {}
