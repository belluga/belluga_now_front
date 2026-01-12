import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:dio/dio.dart';

class LaravelAuthBackend extends AuthBackendContract {
  LaravelAuthBackend({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: BellugaConstants.api.baseUrl,
              ),
            );

  final Dio _dio;

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
    throw UnimplementedError('Login check is not wired for LaravelAuthBackend.');
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
      final response = await _dio.post(
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

String _responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}
