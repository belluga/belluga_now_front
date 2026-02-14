import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'dart:convert';

import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/user_dto_mapper.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';
import 'package:uuid/uuid.dart';

final class AuthRepository extends AuthRepositoryContract<UserBelluga>
    with UserDtoMapper {
  AuthRepository() {
    _userTokenStreamValue.stream.listen(_onUpdateUserTokenOnLocalStorage);
  }

  static const String _userTokenStorageKey = 'user_token';
  static const String _deviceIdStorageKey = 'device_id';
  static const String _userIdStorageKey = 'user_id';
  static const Uuid _uuid = Uuid();
  @visibleForTesting
  static const int anonymousIdentityMaxAttempts = 3;
  @visibleForTesting
  static const List<Duration> anonymousIdentityRetryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 800),
  ];

  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();

  @override
  String get userToken => _userTokenStreamValue.value ?? '';

  final StreamValue<String?> _userTokenStreamValue = StreamValue<String?>();
  final StreamValue<String?> _userIdStreamValue = StreamValue<String?>();

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  @override
  void setUserToken(String? token) => _userTokenStreamValue.addValue(token);

  void userTokenUpdate(String token) => setUserToken(token);
  void userTokenDelete() => setUserToken(null);

  @override
  bool get isUserLoggedIn {
    return userStreamValue.value != null;
  }

  @override
  bool get isAuthorized {
    return userStreamValue.value != null;
  }

  @override
  Future<void> init() async {
    await _getUserTokenFromLocalStorage();
    await _getUserIdFromLocalStorage();
    await autoLogin();
    await _ensureIdentityToken();
  }

  @override
  Future<void> autoLogin() async {
    final token = await storage.read(key: _userTokenStorageKey);

    if (token == null) {
      return;
    }

    userTokenUpdate(token);

    try {
      final user = await backend.auth.loginCheck();
      final loggedUser = mapUserDto(user);
      userStreamValue.addValue(loggedUser);
      await _setUserId(loggedUser.uuidValue.value);
    } catch (error) {
      await _resetStaleIdentity(error);
    }

    return Future.value();
  }

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    final previousUserId = await getUserId();
    var (UserDto _user, String _token) =
        await backend.auth.loginWithEmailPassword(
      email,
      password,
    );

    await _finalizeAuthenticatedUser(
      _user,
      _token,
      previousUserId: previousUserId,
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
    String name,
    String email,
    String password,
  ) async {
    final previousUserId = await getUserId();
    final anonymousIds = (previousUserId != null && previousUserId.isNotEmpty)
        ? [previousUserId]
        : null;
    final response = await backend.auth.registerWithEmailPassword(
      name: name,
      email: email,
      password: password,
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
      final loginResult =
          await backend.auth.loginWithEmailPassword(email, password);
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
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(Map<String, Object?> data) {
    throw UnimplementedError();
  }

  Future<void> _onUpdateUserTokenOnLocalStorage(String? token) async {
    if (token == null) {
      await _deleteUserTokenOnLocalStorage();
      return;
    }

    _saveUserTokenOnLocalStorage(token);
  }

  Future<void> _deleteUserTokenOnLocalStorage() async {
    await AuthRepository.storage.delete(key: _userTokenStorageKey);
  }

  Future<void> _saveUserTokenOnLocalStorage(String token) async {
    await AuthRepository.storage.write(
      key: _userTokenStorageKey,
      value: token,
    );
  }

  Future<void> _getUserTokenFromLocalStorage() async {
    final token = await AuthRepository.storage.read(key: _userTokenStorageKey);
    _userTokenStreamValue.addValue(token);
  }

  @override
  Future<String?> getUserId() async {
    final current = _userIdStreamValue.value;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    final stored = await AuthRepository.storage.read(key: _userIdStorageKey);
    if (stored != null && stored.isNotEmpty) {
      _userIdStreamValue.addValue(stored);
      return stored;
    }
    return null;
  }

  Future<void> _getUserIdFromLocalStorage() async {
    final stored = await AuthRepository.storage.read(key: _userIdStorageKey);
    if (stored != null && stored.isNotEmpty) {
      _userIdStreamValue.addValue(stored);
      return;
    }
    _userIdStreamValue.addValue(null);
  }

  Future<void> _setUserId(String? userId) async {
    _userIdStreamValue.addValue(userId);
    if (userId == null || userId.isEmpty) {
      await AuthRepository.storage.delete(key: _userIdStorageKey);
      return;
    }
    await AuthRepository.storage.write(
      key: _userIdStorageKey,
      value: userId,
    );
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
    if (_isLandlordScope()) {
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
    final user = mapUserDto(userDto);
    userStreamValue.addValue(user);
    await _mergeTelemetryIdentity(previousUserId);
    await _setUserId(overrideUserId ?? user.uuidValue.value);
  }

  Future<void> _mergeTelemetryIdentity(String? previousUserId) async {
    if (previousUserId == null || previousUserId.isEmpty) {
      return;
    }
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    await telemetry.mergeIdentity(previousUserId: previousUserId);
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
    if (appData != null &&
        appData.typeValue.value == EnvironmentType.landlord) {
      return true;
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
  Future<String> getDeviceId() async => _ensureDeviceId();

  static Future<String> _ensureDeviceId() async {
    final stored = await storage.read(key: _deviceIdStorageKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final generated = _uuid.v4();
    await storage.write(key: _deviceIdStorageKey, value: generated);
    return generated;
  }

  static Future<String> ensureDeviceId() async => _ensureDeviceId();

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createNewPassword(String newPassword, String confirmPassword) {
    throw UnimplementedError();
  }
}
