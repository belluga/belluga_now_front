import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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

  Dio _resolveDio() {
    if (_dio != null) {
      return _dio!;
    }
    final context = _context ??
        (GetIt.I.isRegistered<BackendContext>()
            ? GetIt.I.get<BackendContext>()
            : null);
    if (context == null) {
      throw StateError(
        'BackendContext is not registered for LaravelAuthBackend.',
      );
    }
    _dio = context.dio;
    return _dio!;
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError('Login is not wired for LaravelAuthBackend.');
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError('Logout is not wired for LaravelAuthBackend.');
  }

  @override
  Future<UserDto> loginCheck() async {
    final token = await _storage.read(key: _userTokenStorageKey);
    if (token == null || token.isEmpty) {
      throw Exception('Auth token missing for login check.');
    }
    try {
      final response = await _resolveDio().get(
        '/v1/auth/token_validate',
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
      final response = await _resolveDio().post(
        '/v1/anonymous/identities',
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
    customData: user['custom_data'] is Map<String, dynamic>
        ? user['custom_data'] as Map<String, dynamic>
        : null,
  );
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
