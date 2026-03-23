import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

final class TenantPublicAuthHeaders {
  const TenantPublicAuthHeaders._();

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

  static Map<String, String> buildSync({
    bool includeJsonAccept = false,
  }) {
    final headers = <String, String>{};
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }

    final token = currentToken();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<String> resolveToken({
    bool bootstrapIfEmpty = true,
  }) async {
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      return '';
    }

    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    var token = authRepository.userToken.trim();
    if (token.isEmpty && bootstrapIfEmpty) {
      await authRepository.init();
      token = authRepository.userToken.trim();
    }
    return token;
  }

  static String currentToken() {
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      return '';
    }
    return GetIt.I.get<AuthRepositoryContract>().userToken.trim();
  }
}
