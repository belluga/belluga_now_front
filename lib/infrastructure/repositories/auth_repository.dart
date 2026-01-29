import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'dart:convert';

import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';
import 'package:uuid/uuid.dart';

final class AuthRepository extends AuthRepositoryContract<UserBelluga> {
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

    final user = await backend.auth.loginCheck();

    final loggedUser = UserBelluga.fromDto(user);
    userStreamValue.addValue(loggedUser);
    await _setUserId(loggedUser.uuidValue.value);

    return Future.value();
  }

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    var (UserDto _user, String _token) =
        await backend.auth.loginWithEmailPassword(
      email,
      password,
    );

    _userTokenStreamValue.addValue(_token);
    final user = UserBelluga.fromDto(_user);
    userStreamValue.addValue(user);
    await _setUserId(user.uuidValue.value);

    return Future.value();
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
  Future<void> signUpWithEmailPassword(String email, String password) {
    throw UnimplementedError();
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

  Future<void> _ensureIdentityToken() async {
    if (userToken.isNotEmpty) {
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
