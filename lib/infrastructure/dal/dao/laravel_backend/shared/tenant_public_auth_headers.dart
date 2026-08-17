import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/observability/invite_flow_debug_logger.dart';
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
    String? debugContext,
  }) async {
    if (debugContext != null && debugContext.isNotEmpty) {
      InviteFlowDebugLogger.log(
        'tenant_public_auth.build.start',
        traceId: debugContext,
        fields: <String, Object?>{
          'include_json_accept': includeJsonAccept,
          'bootstrap_if_empty': bootstrapIfEmpty,
        },
      );
    }

    final headers = <String, String>{};
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }

    final token = await resolveToken(
      bootstrapIfEmpty: bootstrapIfEmpty,
      debugContext: debugContext,
    );
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (debugContext != null && debugContext.isNotEmpty) {
      InviteFlowDebugLogger.log(
        'tenant_public_auth.build.ready',
        traceId: debugContext,
        fields: <String, Object?>{
          'include_json_accept': includeJsonAccept,
          'bootstrap_if_empty': bootstrapIfEmpty,
          'auth_present': token.isNotEmpty,
        },
      );
    }

    return headers;
  }

  static Future<String> resolveToken({
    bool bootstrapIfEmpty = true,
    String? debugContext,
  }) async {
    final authRepository = _authRepository();
    if (debugContext != null && debugContext.isNotEmpty) {
      InviteFlowDebugLogger.log(
        'tenant_public_auth.resolve_token.start',
        traceId: debugContext,
        fields: <String, Object?>{
          'bootstrap_if_empty': bootstrapIfEmpty,
          'is_authorized': authRepository.isAuthorized,
          'has_user_token': authRepository.userToken.trim().isNotEmpty,
        },
      );
    }

    if (bootstrapIfEmpty) {
      await authRepository.ensureTenantPublicIdentityReady();
    }
    final token = authRepository.userToken.trim();
    if (token.isEmpty) {
      throw _missingBearerToken();
    }

    if (debugContext != null && debugContext.isNotEmpty) {
      InviteFlowDebugLogger.log(
        'tenant_public_auth.resolve_token.ready',
        traceId: debugContext,
        fields: <String, Object?>{
          'bootstrap_if_empty': bootstrapIfEmpty,
          'is_authorized': authRepository.isAuthorized,
          'has_user_token': token.isNotEmpty,
        },
      );
    }

    return token;
  }

  static Future<T> retryOnceOnUnauthorized<T>({
    required Future<T> Function(Map<String, String> headers) action,
    bool includeJsonAccept = false,
    bool bootstrapIfEmpty = true,
    String? debugContext,
  }) async {
    try {
      return await action(
        await build(
          includeJsonAccept: includeJsonAccept,
          bootstrapIfEmpty: bootstrapIfEmpty,
          debugContext: debugContext,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        rethrow;
      }

      if (debugContext != null && debugContext.isNotEmpty) {
        InviteFlowDebugLogger.log(
          'tenant_public_auth.retry_on_unauthorized',
          traceId: debugContext,
          fields: <String, Object?>{'status_code': error.response?.statusCode},
        );
      }

      await _authRepository()
          .recoverTenantPublicIdentityAfterUnauthorizedPublicRequest();

      if (debugContext != null && debugContext.isNotEmpty) {
        InviteFlowDebugLogger.log(
          'tenant_public_auth.retry_recovered',
          traceId: debugContext,
          fields: const <String, Object?>{'bootstrap_if_empty': false},
        );
      }

      return action(
        await build(
          includeJsonAccept: includeJsonAccept,
          bootstrapIfEmpty: false,
          debugContext: debugContext,
        ),
      );
    }
  }
}
