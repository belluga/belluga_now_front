import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/profile_screen.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_confirmed_events_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/self_profile_pending_invites_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class _FakeBackendContract extends Fake implements BackendContract {}

class _FakeAppData extends Fake implements AppData {}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.backend,
    this.authorized = false,
    UserContract? initialUser,
  }) {
    userStreamValue.addValue(initialUser);
  }

  @override
  final BackendContract backend;

  final bool authorized;

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => userStreamValue.value != null;

  @override
  bool get isAuthorized => authorized;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    ThemeMode? initialThemeMode,
    double initialMaxRadiusMeters = 5000,
  })  : _themeMode = initialThemeMode ?? ThemeMode.light,
        _maxRadiusMeters = initialMaxRadiusMeters,
        themeModeStreamValue =
            StreamValue<ThemeMode?>(defaultValue: initialThemeMode),
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
            defaultValue: DistanceInMetersValue.fromRaw(initialMaxRadiusMeters,
                defaultValue: initialMaxRadiusMeters));

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;
  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;
  final AppData _appData = _FakeAppData();
  ThemeMode _themeMode;
  double _maxRadiusMeters;

  @override
  AppData get appData => _appData;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(_maxRadiusMeters,
          defaultValue: _maxRadiusMeters);

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

class _FakeProximityPreferencesRepository
    extends ProximityPreferencesRepositoryContract {}

class _FakeSelfProfileRepository extends SelfProfileRepositoryContract {
  _FakeSelfProfileRepository({
    required SelfProfile initialProfile,
    this.seedStream = true,
  }) : _profile = initialProfile {
    if (seedStream) {
      currentProfileStreamValue.addValue(initialProfile);
    }
  }

  SelfProfile _profile;
  final bool seedStream;
  UserDisplayNameValue? lastDisplayNameValue;
  DescriptionValue? lastBioValue;
  Object? updateError;

  Completer<SelfProfile>? fetchCompleter;

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

class _FakeInvitesRepository extends InvitesRepositoryContract {
  List<InviteableRecipient> inviteableRecipients = const [];
  Completer<List<InviteableRecipient>>? inviteableRecipientsCompleter;

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    if (inviteableRecipientsCompleter != null) {
      return inviteableRecipientsCompleter!.future;
    }
    return inviteableRecipients;
  }

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      const <InviteModel>[];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    throw UnimplementedError();
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
      InviteContacts contacts) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async =>
      const <SentInviteStatus>[];
}

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
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastRoutes;

  @override
  RootStackRouter get root => _FakeRootStackRouter('/profile');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCallCount += 1;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastRoutes = routes;
  }
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

void main() {
  late _RecordingStackRouter mockRouter;

  setUp(() async {
    await GetIt.I.reset();
    mockRouter = _RecordingStackRouter();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'ProfileScreenController resolves with only profile dependencies',
    () {
      final authRepository =
          _FakeAuthRepository(backend: _FakeBackendContract());
      final appDataRepository = _FakeAppDataRepository();
      final avatarStorage = _FakeProfileAvatarStorage();
      final selfProfileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
        ),
      );
      final invitesRepository = _FakeInvitesRepository();

      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
      GetIt.I.registerSingleton<ProfileAvatarStorageContract>(avatarStorage);
      GetIt.I.registerSingleton<SelfProfileRepositoryContract>(
        selfProfileRepository,
      );
      GetIt.I.registerSingleton<InvitesRepositoryContract>(invitesRepository);
      GetIt.I.registerSingleton<ProximityPreferencesRepositoryContract>(
        _FakeProximityPreferencesRepository(),
      );

      // Guardrail: profile must resolve from repositories, never from another feature controller.
      expect(
        () => ProfileScreenController(),
        returnsNormally,
      );
    },
  );

  testWidgets('Profile stays visible in user mode (no auto-redirect)',
      (tester) async {
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
    );
    await _pumpProfileScreen(tester,
        controller: controller, router: mockRouter);

    await tester.pump();
    await tester.pump();

    expect(mockRouter.replaceAllCalled, isFalse);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Alice Smith'), findsWidgets);
  });

  testWidgets(
    'Profile removes legacy fields, keeps phone read-only, and exposes profile actions',
    (tester) async {
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(),
      );
      await _pumpProfileScreen(
        tester,
        controller: controller,
        router: mockRouter,
      );
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

      final originPreferenceTile =
          find.byKey(const Key('profileOriginPreferenceTile'));
      await tester.ensureVisible(originPreferenceTile);
      await tester.tap(originPreferenceTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fixa'));
      await tester.pumpAndSettle();

      expect(find.text('Selecionar no mapa'), findsOneWidget);
      expect(find.byKey(const Key('profileSaveOriginPreferenceButton')),
          findsOneWidget);
    },
  );

  testWidgets(
    'Profile radius picker caps UI at 50 km',
    (tester) async {
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(),
      );
      await _pumpProfileScreen(
        tester,
        controller: controller,
        router: mockRouter,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-radius-expanded')),
      );
      await tester.pumpAndSettle();

      expect(find.text('50 km'), findsOneWidget);
      expect(find.text('100 km'), findsNothing);
    },
  );

  testWidgets('profile visible back falls back to home when no history exists',
      (tester) async {
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
    );
    mockRouter.canPopResult = false;
    await _pumpProfileScreen(tester,
        controller: controller, router: mockRouter);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(mockRouter.canPopCallCount, 1);
    expect(mockRouter.popCallCount, 0);
    expect(mockRouter.replaceAllCalled, isTrue);
    expect(mockRouter.lastRoutes?.single.routeName, TenantHomeRoute.name);
  });

  testWidgets('profile system back falls back to home when no history exists',
      (tester) async {
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
    );
    mockRouter.canPopResult = false;
    await _pumpProfileScreen(tester,
        controller: controller, router: mockRouter);
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(mockRouter.canPopCallCount, 1);
    expect(mockRouter.popCallCount, 0);
    expect(mockRouter.replaceAllCalled, isTrue);
    expect(mockRouter.lastRoutes?.single.routeName, TenantHomeRoute.name);
  });

  testWidgets('profile visible back pops when history exists', (tester) async {
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
    );
    mockRouter.canPopResult = true;
    await _pumpProfileScreen(tester,
        controller: controller, router: mockRouter);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(mockRouter.canPopCallCount, 1);
    expect(mockRouter.popCallCount, 1);
    expect(mockRouter.replaceAllCalled, isFalse);
  });

  testWidgets('Profile updates when user stream changes', (tester) async {
    final authRepository = _FakeAuthRepository(backend: _FakeBackendContract());
    final appDataRepository = _FakeAppDataRepository();
    final avatarStorage = _FakeProfileAvatarStorage();
    final selfProfileRepository = _FakeSelfProfileRepository(
      initialProfile: _buildSelfProfile(
        userId: '507f1f77bcf86cd799439011',
        accountProfileId: 'profile-self',
      ),
    );

    final controller = ProfileScreenController(
      authRepository: authRepository,
      appDataRepository: appDataRepository,
      avatarStorage: avatarStorage,
      selfProfileRepository: selfProfileRepository,
      invitesRepository: _FakeInvitesRepository(),
      proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
    );

    await _pumpProfileScreen(tester,
        controller: controller, router: mockRouter);
    await tester.pump();

    expect(find.text('Alice Smith'), findsNothing);

    final user = _FakeUser(
      uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
      profile: UserProfileContract(
        nameValue: FullNameValue()..parse('Alice Smith'),
        emailValue: EmailAddressValue()..parse('alice@example.com'),
      ),
    );
    authRepository.userStreamValue.addValue(user);
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice Smith'), findsWidgets);
  });

  testWidgets(
    'profile screen reuses cached repository profile immediately while refresh resolves silently',
    (tester) async {
      final selfProfileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: '507f1f77bcf86cd799439011',
          accountProfileId: 'profile-self',
          displayName: 'Alice Cache',
          bio: 'Bio cacheada',
          phone: '+5527999991111',
        ),
      )..fetchCompleter = Completer<SelfProfile>();
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(name: 'Alice Cache'),
        selfProfileRepository: selfProfileRepository,
      );

      await _pumpProfileScreen(
        tester,
        controller: controller,
        router: mockRouter,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Alice Cache'), findsWidgets);
      expect(find.text('Bio cacheada'), findsWidgets);
    },
  );

  testWidgets(
    'profile screen keeps loading when no cached repository profile exists yet',
    (tester) async {
      final selfProfileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: '507f1f77bcf86cd799439011',
          accountProfileId: 'profile-self',
          displayName: 'Alice Cache',
          bio: 'Bio cacheada',
          phone: '+5527999991111',
        ),
        seedStream: false,
      )..fetchCompleter = Completer<SelfProfile>();
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(name: 'Alice Cache'),
        selfProfileRepository: selfProfileRepository,
      );

      await _pumpProfileScreen(
        tester,
        controller: controller,
        router: mockRouter,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Alice Cache'), findsNothing);
    },
  );

  test('Profile controller persists editable fields and rehydrates values',
      () async {
    final selfProfileRepository = _FakeSelfProfileRepository(
      initialProfile: _buildSelfProfile(
        userId: 'user-1',
        accountProfileId: 'profile-1',
        displayName: 'Alice Smith',
        bio: 'Bio inicial',
        phone: '+5527999991111',
      ),
    );
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
      selfProfileRepository: selfProfileRepository,
    );

    await controller.refreshProfile();
    controller.nameController.text = 'Alice Persistida';
    controller.descriptionController.text = 'Bio persistida';

    await controller.saveProfile();

    expect(
        selfProfileRepository.lastDisplayNameValue?.value, 'Alice Persistida');
    expect(selfProfileRepository.lastBioValue?.value, 'Bio persistida');
    expect(controller.nameController.text, 'Alice Persistida');
    expect(controller.descriptionController.text, 'Bio persistida');
  });

  test(
    'Profile controller omits unchanged bio when only the name changes',
    () async {
      final selfProfileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Alice Smith',
          bio: '',
          phone: '+5527999991111',
        ),
      );
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(),
        selfProfileRepository: selfProfileRepository,
      );

      await controller.refreshProfile();
      controller.nameController.text = 'Alice Persistida';

      await controller.saveProfile();

      expect(
        selfProfileRepository.lastDisplayNameValue?.value,
        'Alice Persistida',
      );
      expect(selfProfileRepository.lastBioValue, isNull);
    },
  );

  test(
    'Profile controller treats avatar cleanup failure as non-fatal after backend save',
    () async {
      final avatarStorage = _FakeProfileAvatarStorage(throwOnClear: true);
      final selfProfileRepository = _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Alice Smith',
          bio: 'Bio inicial',
          phone: '+5527999991111',
        ),
      );
      final controller = _buildController(
        authorized: true,
        initialUser: _buildUser(),
        avatarStorage: avatarStorage,
        selfProfileRepository: selfProfileRepository,
      );

      await controller.refreshProfile();
      controller.nameController.text = 'Alice Persistida';

      await controller.saveProfile();

      expect(selfProfileRepository.lastDisplayNameValue?.value,
          'Alice Persistida');
      expect(controller.nameController.text, 'Alice Persistida');
      expect(controller.hasPendingChanges, isFalse);
      expect(controller.localAvatarPathStreamValue.value, isNull);
    },
  );

  test(
      'Profile controller hides phone placeholder names coming from profile payload',
      () async {
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
      selfProfileRepository: _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: '+55 27 99999-1111',
          bio: '',
          phone: '+55 27 99999-1111',
        ),
      ),
    );

    await controller.refreshProfile();

    expect(controller.nameController.text, isEmpty);
  });

  test(
      'Profile controller surfaces friendly save errors without raw exception text',
      () async {
    final selfProfileRepository = _FakeSelfProfileRepository(
      initialProfile: _buildSelfProfile(
        userId: 'user-1',
        accountProfileId: 'profile-1',
        displayName: 'Alice Smith',
        bio: 'Bio inicial',
        phone: '+5527999991111',
      ),
    )..updateError = StateError('HTTP 422 profile endpoint exploded');
    final controller = _buildController(
      authorized: true,
      initialUser: _buildUser(),
      selfProfileRepository: selfProfileRepository,
    );

    await controller.refreshProfile();
    controller.nameController.text = 'Alice Persistida';

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
  });
}

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required ProfileScreenController controller,
  required _RecordingStackRouter router,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  GetIt.I.registerSingleton<ProfileScreenController>(controller);
  await tester.pumpWidget(_buildRoutedTestApp(router: router));
}

ProfileScreenController _buildController({
  bool authorized = false,
  UserContract? initialUser,
  ProfileAvatarStorageContract? avatarStorage,
  SelfProfileRepositoryContract? selfProfileRepository,
  InvitesRepositoryContract? invitesRepository,
}) {
  final authRepository = _FakeAuthRepository(
    backend: _FakeBackendContract(),
    authorized: authorized,
    initialUser: initialUser,
  );
  final appDataRepository = _FakeAppDataRepository();
  final resolvedAvatarStorage = avatarStorage ?? _FakeProfileAvatarStorage();
  final profileRepository = selfProfileRepository ??
      _FakeSelfProfileRepository(
        initialProfile: _buildSelfProfile(
          userId: initialUser?.uuidValue.value.toString() ?? 'user-1',
          accountProfileId: 'profile-self',
          displayName: initialUser?.profile.nameValue?.value ?? 'Alice Smith',
          bio: 'Bio inicial',
          phone: '+5527999991111',
        ),
      );

  return ProfileScreenController(
    authRepository: authRepository,
    appDataRepository: appDataRepository,
    avatarStorage: resolvedAvatarStorage,
    selfProfileRepository: profileRepository,
    invitesRepository: invitesRepository ?? _FakeInvitesRepository(),
    proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
  );
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: ProfileRoute.name,
      fullPath: '/profile',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.profileRoot,
      ),
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: const ProfileScreen(),
      ),
    ),
  );
}

UserContract _buildUser({
  String name = 'Alice Smith',
}) {
  return _FakeUser(
    uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    profile: UserProfileContract(
      nameValue: FullNameValue()..parse(name),
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

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
  }) : pageRouteInfo = pageRouteInfo ?? const ProfileRoute();

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}
