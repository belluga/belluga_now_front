import 'dart:async';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_challenge_id_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_delivery_channel_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
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
  AuthRepository({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage() {
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
    await _getUserTokenFromLocalStorage();
    await _getUserIdFromLocalStorage();
    await autoLogin();
    await _ensureIdentityToken();
    if (isAuthorized) {
      await _syncProximityPreferencesIfAvailable();
    }
  }

  @override
  Future<void> autoLogin() async {
    String? token;
    try {
      token = await _storage.read(key: _userTokenStorageKey);
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'autoLogin.readUserToken',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (token == null) {
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

    return Future.value();
  }

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractTextValue email,
    AuthRepositoryContractTextValue password,
  ) async {
    final previousUserId = await getUserId();
    var (UserDto _user, String _token) =
        await backend.auth.loginWithEmailPassword(
      email.value,
      password.value,
    );

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

    return Future.value();
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
      final loginResult = await backend.auth
          .loginWithEmailPassword(email.value, password.value);
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
    await _storage.write(
      key: _userTokenStorageKey,
      value: token,
    );
  }

  Future<void> _getUserTokenFromLocalStorage() async {
    try {
      final token = await _storage.read(key: _userTokenStorageKey);
      _userTokenStreamValue.addValue(token);
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'getUserTokenFromLocalStorage',
        error: error,
        stackTrace: stackTrace,
      );
      _userTokenStreamValue.addValue(null);
    }
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
    try {
      final stored = await _storage.read(key: _userIdStorageKey);
      if (stored != null && stored.isNotEmpty) {
        _userIdStreamValue.addValue(stored);
        return;
      }
    } catch (error, stackTrace) {
      _logStorageFailure(
        operation: 'getUserIdFromLocalStorage',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _userIdStreamValue.addValue(null);
  }

  Future<void> _setUserId(String? userId) async {
    _userIdStreamValue.addValue(userId);
    try {
      if (userId == null || userId.isEmpty) {
        await _storage.delete(key: _userIdStorageKey);
        return;
      }
      await _storage.write(
        key: _userIdStorageKey,
        value: userId,
      );
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
  }

  Future<void> _ensureIdentityToken() async {
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

    return GetIt.I.get<AdminModeRepositoryContract>().isLandlordMode;
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
    debugPrint(
      'AuthRepository.$operation failed: $error\n$stackTrace',
    );
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
