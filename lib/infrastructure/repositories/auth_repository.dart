import 'dart:async';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_challenge_id_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_delivery_channel_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'dart:convert';

import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';
import 'package:uuid/uuid.dart';

final class AuthRepository extends AuthRepositoryContract<UserBelluga> {
  AuthRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _userTokenStreamValue.stream.listen(_onUpdateUserTokenOnLocalStorage);
  }

  static const String _userTokenStorageKey = 'user_token';
  static const String _deviceIdStorageKey = 'device_id';
  static const String _userIdStorageKey = 'user_id';
  static const Uuid _uuid = Uuid();
  @visibleForTesting
  static const int anonymousIdentityMaxAttempts = 5;
  @visibleForTesting
  static const List<Duration> anonymousIdentityRetryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 2000),
  ];

  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();

  @override
  String get userToken => _userTokenStreamValue.value ?? '';

  final StreamValue<String?> _userTokenStreamValue = StreamValue<String?>();
  final StreamValue<String?> _userIdStreamValue = StreamValue<String?>();
  final FlutterSecureStorage _storage;
  Future<void>? _initInFlight;
  Future<void>? _tenantPublicIdentityReadyInFlight;
  Future<AccountDeletionDispatchOutcome>? _accountDeletionInFlight;
  bool _hasCompletedBootstrap = false;
  bool _hasCompletedTenantPublicIdentityReadiness = false;

  static FlutterSecureStorage get storage => const FlutterSecureStorage();

  @override
  void setUserToken(AuthRepositoryContractTextValue? token) =>
      _userTokenStreamValue.addValue(token?.value);

  void userTokenUpdate(String token) => setUserToken(authRepoString(token));
  void userTokenDelete() => setUserToken(null);

  @override
  bool get isUserLoggedIn {
    return userStreamValue.value != null;
  }

  @override
  bool get isAuthorized {
    final user = userStreamValue.value;
    if (user == null) {
      return false;
    }

    if (user.customData?.isAnonymous ?? false) {
      return false;
    }

    return true;
  }

  @override
  Future<void> init() async {
    if (_hasCompletedBootstrap) {
      return;
    }

    final inFlight = _initInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<void>();
    _initInFlight = completer.future;
    unawaited(() async {
      try {
        await ensureTenantPublicIdentityReady();
        if (isAuthorized) {
          await _syncProximityPreferencesIfAvailable();
        }
        _hasCompletedBootstrap = true;
        completer.complete();
      } catch (error, stackTrace) {
        _hasCompletedBootstrap = false;
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_initInFlight, completer.future)) {
          _initInFlight = null;
        }
      }
    }());

    return completer.future;
  }

  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    if (accountDeletionJourneyState.blocksAutomaticIdentityBootstrap) {
      return;
    }
    if (_hasCompletedTenantPublicIdentityReadiness) {
      return;
    }

    final inFlight = _tenantPublicIdentityReadyInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<void>();
    _tenantPublicIdentityReadyInFlight = completer.future;
    unawaited(() async {
      try {
        final tokenLoadedFromStorage = await _getUserTokenFromLocalStorage();
        await _getUserIdFromLocalStorage();
        await _autoLoginAfterInit(
          tokenLoadedFromStorage:
              tokenLoadedFromStorage || userToken.trim().isNotEmpty,
        );
        await _ensureIdentityToken();
        _hasCompletedTenantPublicIdentityReadiness = true;
        completer.complete();
      } catch (error, stackTrace) {
        _hasCompletedTenantPublicIdentityReadiness = false;
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_tenantPublicIdentityReadyInFlight, completer.future)) {
          _tenantPublicIdentityReadyInFlight = null;
        }
      }
    }());

    return completer.future;
  }

  @override
  Future<void>
  recoverTenantPublicIdentityAfterUnauthorizedPublicRequest() async {
    if (accountDeletionJourneyState.blocksAutomaticIdentityBootstrap) {
      return;
    }
    await _resetStaleIdentity(
      StateError('Tenant-public request returned unauthorized.'),
    );
    await ensureTenantPublicIdentityReady();
  }

  @override
  Future<void> autoLogin() async {
    if (accountDeletionJourneyState.blocksAutomaticIdentityBootstrap) {
      return;
    }
    final tokenLoadedFromStorage = await _getUserTokenFromLocalStorage();
    await _autoLoginAfterInit(tokenLoadedFromStorage: tokenLoadedFromStorage);
  }

  Future<void> _autoLoginAfterInit({
    required bool tokenLoadedFromStorage,
  }) async {
    if (accountDeletionJourneyState.blocksAutomaticIdentityBootstrap) {
      return;
    }
    if (!tokenLoadedFromStorage) {
      return;
    }

    String? token;
    token = _userTokenStreamValue.value?.trim();

    if (token == null || token.isEmpty) {
      return;
    }

    userTokenUpdate(token);

    try {
      final user = await backend.auth.loginCheck();
      final loggedUser = user.toDomain();
      userStreamValue.addValue(loggedUser);
      await _setUserId(loggedUser.uuidValue.value);
    } catch (error) {
      await _resetStaleIdentity(error);
    }

    return;
  }

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractTextValue email,
    AuthRepositoryContractTextValue password,
  ) async {
    final previousUserId = await getUserId();
    var (UserDto _user, String _token) = await backend.auth
        .loginWithEmailPassword(email.value, password.value);

    await _finalizeAuthenticatedUser(
      _user,
      _token,
      previousUserId: previousUserId,
    );
  }

  @override
  Future<AuthPhoneOtpChallenge> requestPhoneOtpChallenge(
    AuthRepositoryContractTextValue phone, {
    AuthRepositoryContractTextValue? deliveryChannel,
  }) async {
    final response = await backend.auth.requestPhoneOtpChallenge(
      phone: phone.value,
      deliveryChannel: deliveryChannel?.value,
    );

    return AuthPhoneOtpChallenge(
      challengeIdValue: AuthPhoneOtpChallengeIdValue()
        ..parse(response.challengeId),
      phoneValue: AuthPhoneOtpPhoneValue()..parse(response.phone),
      deliveryChannelValue: AuthPhoneOtpDeliveryChannelValue()
        ..parse(response.deliveryChannel),
      expiresAtValue: DomainOptionalDateTimeValue()
        ..set(_parseNullableDateTime(response.expiresAt)),
      resendAvailableAtValue: DomainOptionalDateTimeValue()
        ..set(_parseNullableDateTime(response.resendAvailableAt)),
    );
  }

  @override
  Future<void> verifyPhoneOtpChallenge({
    required AuthRepositoryContractTextValue challengeId,
    required AuthRepositoryContractTextValue phone,
    required AuthRepositoryContractTextValue code,
  }) async {
    final previousUserId = await getUserId();
    final anonymousIds = (previousUserId != null && previousUserId.isNotEmpty)
        ? [previousUserId]
        : null;
    final response = await backend.auth.verifyPhoneOtpChallenge(
      challengeId: challengeId.value,
      phone: phone.value,
      code: code.value,
      anonymousUserIds: anonymousIds,
    );

    if (response.token.isNotEmpty) {
      await _saveUserTokenOnLocalStorage(response.token);
      _userTokenStreamValue.addValue(response.token);
    }

    await _finalizeAuthenticatedUser(
      response.user,
      response.token,
      previousUserId: previousUserId,
      overrideUserId: response.userId,
    );
  }

  @override
  Future<void> logout() async {
    await backend.auth.logout();

    userStreamValue.addValue(null);
    _userTokenStreamValue.addValue(null);
    await _setUserId(null);
    _hasCompletedBootstrap = false;
    _hasCompletedTenantPublicIdentityReadiness = false;

    return Future.value();
  }

  @override
  Future<AccountDeletionDispatchOutcome> deleteCurrentAccount() {
    final inFlight = _accountDeletionInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    if (accountDeletionJourneyState.phase != AccountDeletionJourneyPhase.idle) {
      return Future.value(AccountDeletionDispatchOutcome.preEraseRejected);
    }

    _setAccountDeletionJourney(AccountDeletionJourneyPhase.deleting);
    final dispatch = _deleteCurrentAccountOnce().whenComplete(() {
      _accountDeletionInFlight = null;
    });
    _accountDeletionInFlight = dispatch;
    return dispatch;
  }

  Future<AccountDeletionDispatchOutcome> _deleteCurrentAccountOnce() async {
    final result = await backend.auth.deleteCurrentAccount();
    if (result is CurrentAccountDeletionSucceeded) {
      var outcome = AccountDeletionDispatchOutcome.confirmed;
      try {
        await _clearDeletedIdentityLocalState();
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.confirmed);
      } catch (_) {
        // A server-side deletion is not a client-visible confirmation until all
        // local identity state has also been erased. Keep this process on the
        // non-bootstrapping uncertainty boundary so it cannot claim removal or
        // create an anonymous replacement over retained local state.
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.unknown);
        outcome = AccountDeletionDispatchOutcome.unknown;
      }
      return outcome;
    }
    if (result is CurrentAccountDeletionPreEraseRejected) {
      _setAccountDeletionJourney(AccountDeletionJourneyPhase.preEraseRejected);
      _setAccountDeletionJourney(AccountDeletionJourneyPhase.idle);
      return AccountDeletionDispatchOutcome.preEraseRejected;
    }

    _setAccountDeletionJourney(AccountDeletionJourneyPhase.unknown);
    return AccountDeletionDispatchOutcome.unknown;
  }

  @override
  Future<void> reconcileUnknownAccountDeletion() async {
    if (accountDeletionJourneyState.phase !=
        AccountDeletionJourneyPhase.unknown) {
      return;
    }

    final result = await backend.auth
        .validateCurrentIdentityForDeletionResolution();
    if (result is CurrentIdentityValidationTerminalAbsent) {
      try {
        await _clearDeletedIdentityLocalState();
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.confirmed);
      } catch (_) {
        // Retain unknown until a later reconciliation can finish the required
        // local teardown. In particular, never enable anonymous continuation.
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.unknown);
      }
    }
  }

  @override
  Future<AccountDeletionContinuationOutcome>
  continueAnonymouslyAfterConfirmedAccountDeletion() async {
    if (!accountDeletionJourneyState.mayContinueAnonymously) {
      return AccountDeletionContinuationOutcome.unavailable;
    }

    _setAccountDeletionJourney(AccountDeletionJourneyPhase.continuing);
    var outcome = AccountDeletionContinuationOutcome.continued;
    try {
      await _rotateDeviceIdentity();
      await _ensureIdentityToken(allowDeletionContinuation: true);
      if (userToken.trim().isEmpty) {
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.confirmed);
        outcome = AccountDeletionContinuationOutcome.failed;
      } else {
        _setAccountDeletionJourney(AccountDeletionJourneyPhase.idle);
      }
    } catch (_) {
      _setAccountDeletionJourney(AccountDeletionJourneyPhase.confirmed);
      outcome = AccountDeletionContinuationOutcome.failed;
    }
    return outcome;
  }

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractTextValue name,
    AuthRepositoryContractTextValue email,
    AuthRepositoryContractTextValue password,
  ) async {
    final previousUserId = await getUserId();
    final anonymousIds = (previousUserId != null && previousUserId.isNotEmpty)
        ? [previousUserId]
        : null;
    final response = await backend.auth.registerWithEmailPassword(
      name: name.value,
      email: email.value,
      password: password.value,
      anonymousUserIds: anonymousIds,
    );
    if (response.token.isNotEmpty) {
      await _saveUserTokenOnLocalStorage(response.token);
      _userTokenStreamValue.addValue(response.token);
    }

    UserDto? userDto;
    String resolvedToken = response.token;
    try {
      userDto = await backend.auth.loginCheck();
    } catch (_) {
      userDto = null;
    }

    if (userDto != null) {
      await _finalizeAuthenticatedUser(
        userDto,
        resolvedToken,
        previousUserId: previousUserId,
        overrideUserId: response.userId,
      );
      return;
    }

    try {
      final loginResult = await backend.auth.loginWithEmailPassword(
        email.value,
        password.value,
      );
      userDto = loginResult.$1;
      resolvedToken = loginResult.$2;
    } catch (_) {
      userDto = null;
    }

    if (userDto != null) {
      await _finalizeAuthenticatedUser(
        userDto,
        resolvedToken,
        previousUserId: previousUserId,
        overrideUserId: response.userId,
      );
      return;
    }

    if (response.userId != null && response.userId!.isNotEmpty) {
      await _setUserId(response.userId);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(AuthRepositoryContractTextValue email) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(UserCustomData data) {
    throw UnimplementedError();
  }

  Future<void> _onUpdateUserTokenOnLocalStorage(String? token) async {
    try {
      if (token == null) {
        await _deleteUserTokenOnLocalStorage();
        return;
      }

      await _saveUserTokenOnLocalStorage(token);
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'onUpdateUserToken',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _deleteUserTokenOnLocalStorage() async {
    await _storage.delete(key: _userTokenStorageKey);
  }

  Future<void> _saveUserTokenOnLocalStorage(String token) async {
    await _storage.write(key: _userTokenStorageKey, value: token);
  }

  Future<bool> _getUserTokenFromLocalStorage() async {
    final currentToken = _userTokenStreamValue.value?.trim();
    try {
      final token = await _storage.read(key: _userTokenStorageKey);
      final normalizedToken = token?.trim();
      if (normalizedToken != null && normalizedToken.isNotEmpty) {
        if (normalizedToken != currentToken) {
          _userTokenStreamValue.addValue(normalizedToken);
        }
        return true;
      }
      if (currentToken != null && currentToken.isNotEmpty) {
        return false;
      }
      _userTokenStreamValue.addValue(null);
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'getUserTokenFromLocalStorage',
        error: error,
        stackTrace: stackTrace,
      );
      if (currentToken == null || currentToken.isEmpty) {
        _userTokenStreamValue.addValue(null);
      }
    }
    return false;
  }

  @override
  Future<String?> getUserId() async {
    final current = _userIdStreamValue.value;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    try {
      final stored = await _storage.read(key: _userIdStorageKey);
      if (stored != null && stored.isNotEmpty) {
        _userIdStreamValue.addValue(stored);
        return stored;
      }
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'getUserId',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Future<void> _getUserIdFromLocalStorage() async {
    final currentUserId = _userIdStreamValue.value?.trim();
    try {
      final stored = await _storage.read(key: _userIdStorageKey);
      if (stored != null && stored.isNotEmpty) {
        if (stored != currentUserId) {
          _userIdStreamValue.addValue(stored);
        }
        return;
      }
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'getUserIdFromLocalStorage',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (currentUserId == null || currentUserId.isEmpty) {
      _userIdStreamValue.addValue(null);
    }
  }

  Future<void> _setUserId(String? userId) async {
    _userIdStreamValue.addValue(userId);
    try {
      if (userId == null || userId.isEmpty) {
        await _storage.delete(key: _userIdStorageKey);
        return;
      }
      await _storage.write(key: _userIdStorageKey, value: userId);
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'setUserId',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _resetStaleIdentity(Object error) async {
    userStreamValue.addValue(null);
    await _setUserId(null);
    userTokenDelete();
    _hasCompletedBootstrap = false;
    _hasCompletedTenantPublicIdentityReadiness = false;
  }

  Future<void> _ensureIdentityToken({
    bool allowDeletionContinuation = false,
  }) async {
    if (!allowDeletionContinuation &&
        accountDeletionJourneyState.blocksAutomaticIdentityBootstrap) {
      return;
    }
    if (userToken.isNotEmpty) {
      return;
    }
    if (_isLandlordScope() || _isLandlordAdminModeActive()) {
      return;
    }
    final deviceId = await getDeviceId();
    final fingerprintHash = _hashFingerprint(deviceId);
    final deviceName = _buildDeviceName(deviceId);
    final response = await _issueAnonymousIdentityWithRetry(
      deviceName: deviceName,
      fingerprintHash: fingerprintHash,
    );
    if (response.token.isNotEmpty) {
      userTokenUpdate(response.token);
    }
    if (response.userId != null && response.userId!.isNotEmpty) {
      await _setUserId(response.userId);
    }
  }

  void _setAccountDeletionJourney(AccountDeletionJourneyPhase phase) {
    accountDeletionJourneyStreamValue.addValue(
      AccountDeletionJourneyState(phase),
    );
  }

  Future<void> _clearDeletedIdentityLocalState() async {
    await Future.wait<void>([
      _deleteUserTokenOnLocalStorage(),
      _deleteUserIdOnLocalStorage(),
      _runRequiredCurrentIdentityCleanup<SelfProfileRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
      _runRequiredCurrentIdentityCleanup<ProfileAvatarStorageContract>(
        (storage) => storage.clearAvatarPath(),
      ),
      _runRequiredCurrentIdentityCleanup<FavoriteRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
      _runRequiredCurrentIdentityCleanup<AccountProfilesRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
      _runRequiredCurrentIdentityCleanup<UserEventsRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
      _runRequiredCurrentIdentityCleanup<InvitesRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
      _runRequiredCurrentIdentityCleanup<
        ProximityPreferencesRepositoryContract
      >((repository) => repository.clearCurrentIdentityState()),
      _runRequiredCurrentIdentityCleanup<ContactsRepositoryContract>(
        (repository) => repository.clearCurrentIdentityState(),
      ),
    ]);

    userStreamValue.addValue(null);
    _userTokenStreamValue.addValue(null);
    _userIdStreamValue.addValue(null);
    _hasCompletedBootstrap = false;
    _hasCompletedTenantPublicIdentityReadiness = false;
  }

  Future<void> _deleteUserIdOnLocalStorage() =>
      _storage.delete(key: _userIdStorageKey);

  Future<void> _runRequiredCurrentIdentityCleanup<T extends Object>(
    FutureOr<void> Function(T dependency) action,
  ) async {
    if (!GetIt.I.isRegistered<T>()) {
      return;
    }
    await action(GetIt.I.get<T>());
  }

  Future<void> _rotateDeviceIdentity() async {
    await _storage.delete(key: _deviceIdStorageKey);
  }

  Future<void> _finalizeAuthenticatedUser(
    UserDto userDto,
    String token, {
    String? previousUserId,
    String? overrideUserId,
  }) async {
    if (token.isNotEmpty) {
      _userTokenStreamValue.addValue(token);
    }
    final user = userDto.toDomain();
    userStreamValue.addValue(user);
    await _mergeTelemetryIdentity(previousUserId);
    await _setUserId(overrideUserId ?? user.uuidValue.value);
    await _syncProximityPreferencesIfAvailable();
  }

  DateTime? _parseNullableDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> _syncProximityPreferencesIfAvailable() async {
    if (_isLandlordAdminModeActive()) {
      return;
    }
    if (!GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()) {
      return;
    }

    final repository = GetIt.I.get<ProximityPreferencesRepositoryContract>();
    unawaited(_runBestEffortProximityPreferencesSync(repository));
  }

  Future<void> _runBestEffortProximityPreferencesSync(
    ProximityPreferencesRepositoryContract repository,
  ) async {
    try {
      await repository.syncAfterIdentityReady();
    } catch (error, stackTrace) {
      debugPrint(
        'AuthRepository._syncProximityPreferencesIfAvailable failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _mergeTelemetryIdentity(String? previousUserId) async {
    if (previousUserId == null || previousUserId.isEmpty) {
      return;
    }
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    await telemetry.mergeIdentity(
      previousUserId: telemetryRepoString(previousUserId),
    );
  }

  Future<AnonymousIdentityResponse> _issueAnonymousIdentityWithRetry({
    required String deviceName,
    required String fingerprintHash,
  }) async {
    for (var attempt = 0; attempt < anonymousIdentityMaxAttempts; attempt++) {
      try {
        return await backend.auth.issueAnonymousIdentity(
          deviceName: deviceName,
          fingerprintHash: fingerprintHash,
        );
      } catch (_) {
        if (attempt >= anonymousIdentityMaxAttempts - 1) rethrow;
        if (anonymousIdentityRetryDelays.isNotEmpty) {
          final delay = attempt < anonymousIdentityRetryDelays.length
              ? anonymousIdentityRetryDelays[attempt]
              : anonymousIdentityRetryDelays.last;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
        }
      }
    }
    throw Exception('Anonymous identity bootstrap failed.');
  }

  bool _isLandlordScope() {
    final appData = _tryGetAppData();
    if (appData != null) {
      return appData.typeValue.value == EnvironmentType.landlord;
    }

    final landlordHost = _resolveHost(BellugaConstants.landlordDomain);
    if (landlordHost == null || landlordHost.isEmpty) {
      return false;
    }

    final requestHost = _resolveHost(backend.context?.baseUrl ?? '');
    if (requestHost == null || requestHost.isEmpty) {
      return false;
    }

    return requestHost == landlordHost;
  }

  bool _isLandlordAdminModeActive() {
    if (!GetIt.I.isRegistered<AdminModeRepositoryContract>()) {
      return false;
    }

    final adminModeRepository = GetIt.I.get<AdminModeRepositoryContract>();
    if (!adminModeRepository.isLandlordMode) {
      return false;
    }

    if (!GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      return false;
    }

    return GetIt.I.get<LandlordAuthRepositoryContract>().hasValidSession;
  }

  AppData? _tryGetAppData() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>();
  }

  String? _resolveHost(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }
    if (uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return value;
  }

  String _hashFingerprint(String deviceId) {
    final platformLabel = _resolvePlatformLabel();
    final bytes = utf8.encode('$deviceId:$platformLabel');
    return sha256.convert(bytes).toString();
  }

  String _buildDeviceName(String deviceId) {
    final platformLabel = _resolvePlatformLabel();
    final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;
    return 'boora-$platformLabel-$shortId';
  }

  String _resolvePlatformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
    }
  }

  @override
  Future<String> getDeviceId() async => _ensureDeviceIdWithStorage(_storage);

  static Future<String> _ensureDeviceIdWithStorage(
    FlutterSecureStorage storage,
  ) async {
    try {
      final stored = await storage.read(key: _deviceIdStorageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }
    } catch (_) {
      // Fall back to an ephemeral device id for the current runtime.
    }

    final generated = _uuid.v4();
    try {
      await storage.write(key: _deviceIdStorageKey, value: generated);
    } catch (_) {
      // Startup must not fail because secure storage is temporarily unavailable.
    }
    return generated;
  }

  void _logStorageFailure({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint('AuthRepository.$operation failed: $error\n$stackTrace');
  }

  static Future<String> _ensureDeviceId() async =>
      _ensureDeviceIdWithStorage(storage);

  static Future<String> ensureDeviceId() async => _ensureDeviceId();

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractTextValue email,
    AuthRepositoryContractTextValue codigoEnviado,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractTextValue newPassword,
    AuthRepositoryContractTextValue confirmPassword,
  ) {
    throw UnimplementedError();
  }
}
