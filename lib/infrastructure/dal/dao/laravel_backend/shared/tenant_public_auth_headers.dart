import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final class TenantPublicAuthHeaders {
  const TenantPublicAuthHeaders._();

  static StateError _missingAuthRepository() => StateError(
    'Protected tenant-public requests require a registered '
    'AuthRepositoryContract.',
  );

  static StateError _missingBearerToken() => StateError(
    'Protected tenant-public requests require a resolved bearer token.',
  );

  static AuthRepositoryContract _authRepository() {
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      throw _missingAuthRepository();
    }

    return GetIt.I.get<AuthRepositoryContract>();
  }

  static Future<Map<String, String>> build({
    bool includeJsonAccept = false,
    bool bootstrapIfEmpty = true,
  }) async {
    final headers = <String, String>{};
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }

    final token = await resolveToken(bootstrapIfEmpty: bootstrapIfEmpty);
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<String> resolveToken({bool bootstrapIfEmpty = true}) async {
    final authRepository = _authRepository();
    if (bootstrapIfEmpty) {
      await authRepository.ensureTenantPublicIdentityReady();
    }
    final token = authRepository.userToken.trim();
    if (token.isEmpty) {
      throw _missingBearerToken();
    }
    return token;
  }

  static Future<T> retryOnceOnUnauthorized<T>({
    required Future<T> Function(Map<String, String> headers) action,
    bool includeJsonAccept = false,
    bool bootstrapIfEmpty = true,
  }) async {
    try {
      return await action(
        await build(
          includeJsonAccept: includeJsonAccept,
          bootstrapIfEmpty: bootstrapIfEmpty,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        rethrow;
      }

      await _authRepository()
          .recoverTenantPublicIdentityAfterUnauthorizedPublicRequest();
      return action(
        await build(
          includeJsonAccept: includeJsonAccept,
          bootstrapIfEmpty: false,
        ),
      );
    }
  }
}
