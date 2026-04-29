import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LaravelAuthBackend extends AuthBackendContract {
  LaravelAuthBackend({
    BackendContext? context,
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _context = context,
        _dio = dio,
        _storage = storage ?? FlutterSecureStorage();

  final BackendContext? _context;
  Dio? _dio;
  final FlutterSecureStorage _storage;
  static const String _userTokenStorageKey = 'user_token';
  static const String _deviceIdStorageKey = 'device_id';

  Dio _resolveAdminDio() {
    if (_dio != null) {
      return _dio!;
    }
    final resolvedContext = _context ??
        (GetIt.I.isRegistered<BackendContract>()
            ? GetIt.I.get<BackendContract>().context
            : null);
    if (resolvedContext == null) {
      throw StateError(
        'BackendContext is not available via BackendContract for LaravelAuthBackend.',
      );
    }
    _dio = resolvedContext.dio;
    return _dio!;
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    final payload = {
      'email': email,
      'password': password,
      'device_name': await _resolveDeviceName(),
    };
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.post(
        '/v1/auth/login$tenantQuery',
        data: payload,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token']?.toString() ?? '';
          final user = data['user'];
          if (user is Map<String, dynamic>) {
            return (_userDtoFromUserResource(user), token);
          }
        }
      }
      throw Exception(
        'Unexpected login response shape for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to login '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<void> logout() async {
    final token = await _storage.read(key: _userTokenStorageKey);
    if (token == null || token.isEmpty) {
      return;
    }
    final deviceName = await _resolveDeviceName();
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      await dio.post(
        '/v1/auth/logout$tenantQuery',
        data: {'device': deviceName},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to logout '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<UserDto> loginCheck() async {
    final token = await _storage.read(key: _userTokenStorageKey);
    if (token == null || token.isEmpty) {
      throw Exception('Auth token missing for login check.');
    }
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.get(
        '/v1/auth/token_validate$tenantQuery',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final user = data['user'];
          if (user is Map<String, dynamic>) {
            return _userDtoFromTokenValidation(user);
          }
        }
        throw Exception(
          'Unexpected token validation response shape '
          'for ${response.requestOptions.uri}.',
        );
      }
      throw Exception(
        'Unexpected token validation response shape '
        'for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to validate auth token '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      if (anonymousUserIds != null && anonymousUserIds.isNotEmpty)
        'anonymous_user_ids': anonymousUserIds,
    };
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.post(
        '/v1/auth/register/password$tenantQuery',
        data: payload,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token']?.toString() ?? '';
          if (token.isNotEmpty) {
            return AuthRegistrationResponse(
              token: token,
              userId: data['user_id']?.toString(),
              identityState: data['identity_state']?.toString(),
              expiresAt: data['expires_at']?.toString(),
            );
          }
        }
        throw Exception(
          'Registration token missing for ${response.requestOptions.uri}.',
        );
      }
      throw Exception(
        'Unexpected registration response shape '
        'for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to register '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<PhoneOtpChallengeResponse> requestPhoneOtpChallenge({
    required String phone,
    String? deliveryChannel,
  }) async {
    final payload = <String, dynamic>{
      'phone': phone,
      'device_name': await _resolveDeviceName(),
      if (deliveryChannel != null && deliveryChannel.trim().isNotEmpty)
        'delivery_channel': deliveryChannel.trim(),
    };
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.post(
        '/v1/auth/otp/challenge$tenantQuery',
        data: payload,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          return PhoneOtpChallengeResponse.fromJson(data);
        }
      }
      throw Exception(
        'Unexpected OTP challenge response shape '
        'for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to request OTP '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<PhoneOtpVerificationResponse> verifyPhoneOtpChallenge({
    required String challengeId,
    required String phone,
    required String code,
    List<String>? anonymousUserIds,
  }) async {
    final payload = <String, dynamic>{
      'challenge_id': challengeId,
      'phone': phone,
      'code': code,
      'device_name': await _resolveDeviceName(),
      if (anonymousUserIds != null && anonymousUserIds.isNotEmpty)
        'anonymous_user_ids': anonymousUserIds,
    };
    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.post(
        '/v1/auth/otp/verify$tenantQuery',
        data: payload,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token']?.toString() ?? '';
          if (token.isEmpty) {
            throw Exception(
              'OTP verification token missing for ${response.requestOptions.uri}.',
            );
          }
          return PhoneOtpVerificationResponse(
            user: _userDtoFromOtpVerifyData(data),
            token: token,
            userId: data['user_id']?.toString(),
            identityState: data['identity_state']?.toString(),
          );
        }
      }
      throw Exception(
        'Unexpected OTP verification response shape '
        'for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to verify OTP '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      'device_name': deviceName,
      'fingerprint': {
        'hash': fingerprintHash,
        if (userAgent != null) 'user_agent': userAgent,
        if (locale != null) 'locale': locale,
      },
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };

    try {
      final dio = _resolveAdminDio();
      final tenantQuery = await _tenantQuerySuffix();
      final response = await dio.post(
        '/v1/anonymous/identities$tenantQuery',
        data: payload,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token']?.toString() ?? '';
          if (token.isNotEmpty) {
            return AnonymousIdentityResponse(
              token: token,
              userId: data['user_id']?.toString(),
              identityState: data['identity_state']?.toString(),
              expiresAt: data['expires_at']?.toString(),
            );
          }
        }
        throw Exception(
          'Anonymous identity token missing for ${response.requestOptions.uri}.',
        );
      }
      throw Exception(
        'Unexpected anonymous identity response shape '
        'for ${response.requestOptions.uri}.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to issue anonymous identity '
        '[${_responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    }
  }

  Future<String> _resolveDeviceName() async {
    final deviceId = await _storage.read(key: _deviceIdStorageKey);
    if (deviceId == null || deviceId.isEmpty) {
      return 'device';
    }
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

  Future<String> _tenantQuerySuffix() async {
    final appDomain = await _resolveAppDomain();
    if (appDomain == null || appDomain.isEmpty) {
      return '';
    }
    return '?app_domain=${Uri.encodeQueryComponent(appDomain)}';
  }

  Future<String?> _resolveAppDomain() async {
    if (kIsWeb) {
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final appDomain = packageInfo.packageName.trim();
    if (appDomain.isEmpty) {
      return null;
    }
    return appDomain;
  }
}

UserDto _userDtoFromTokenValidation(Map<String, dynamic> user) {
  final id = user['id']?.toString();
  if (id == null || id.isEmpty) {
    throw Exception('Token validation user id missing.');
  }
  return UserDto(
    id: id,
    profile: UserProfileDto(
      name: user['name']?.toString(),
      email: _extractEmail(user['emails']),
      pictureUrl: null,
      birthday: null,
    ),
    customData: _extractCustomData(user),
  );
}

UserDto _userDtoFromUserResource(Map<String, dynamic> user) {
  final id = user['id']?.toString();
  if (id == null || id.isEmpty) {
    throw Exception('Login user id missing.');
  }
  return UserDto(
    id: id,
    profile: UserProfileDto(
      name: user['name']?.toString(),
      email: _extractEmail(user['emails']),
      pictureUrl: null,
      birthday: null,
    ),
    customData: _extractCustomData(user),
  );
}

UserDto _userDtoFromOtpVerifyData(Map<String, dynamic> data) {
  final me = data['me'];
  final meMap = me is Map ? Map<String, dynamic>.from(me) : <String, dynamic>{};
  final profile = meMap['data'];
  final profileMap =
      profile is Map ? Map<String, dynamic>.from(profile) : <String, dynamic>{};
  final id = data['user_id']?.toString() ?? profileMap['user_id']?.toString();
  if (id == null || id.isEmpty) {
    throw Exception('OTP verification user id missing.');
  }

  final customData = <String, dynamic>{};
  final identityState = data['identity_state']?.toString().trim();
  if (identityState != null && identityState.isNotEmpty) {
    customData['identity_state'] = identityState;
  }

  return UserDto(
    id: id,
    profile: UserProfileDto(
      name: profileMap['display_name']?.toString(),
      email: null,
      pictureUrl: profileMap['avatar_url']?.toString(),
      birthday: null,
    ),
    customData: customData,
  );
}

Map<String, dynamic>? _extractCustomData(Map<String, dynamic> user) {
  final customData = <String, dynamic>{};

  final rawCustomData = user['custom_data'];
  if (rawCustomData is Map) {
    customData.addAll(Map<String, dynamic>.from(rawCustomData));
  }

  final identityState = user['identity_state']?.toString().trim();
  if (identityState != null && identityState.isNotEmpty) {
    customData['identity_state'] = identityState;
  }

  if (customData.isEmpty) {
    return null;
  }

  return customData;
}

String? _extractEmail(dynamic emails) {
  if (emails is List && emails.isNotEmpty) {
    final first = emails.first;
    if (first is String) return first;
    if (first is Map && first['email'] != null) {
      return first['email']?.toString();
    }
  }
  return null;
}

String _responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}
