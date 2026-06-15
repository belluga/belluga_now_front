import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
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

  static Future<Map<String, String>> build({
    bool includeJsonAccept = false,
    bool bootstrapIfEmpty = true,
  }) async {
    final headers = <String, String>{};
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }

    final token = await resolveToken(
      bootstrapIfEmpty: bootstrapIfEmpty,
    );
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<String> resolveToken({
    bool bootstrapIfEmpty = true,
  }) async {
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      throw _missingAuthRepository();
    }

    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    if (bootstrapIfEmpty) {
      await authRepository.ensureTenantPublicIdentityReady();
    }
    final token = authRepository.userToken.trim();
    if (token.isEmpty) {
      throw _missingBearerToken();
    }
    return token;
  }
}
