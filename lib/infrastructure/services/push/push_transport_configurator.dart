import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';

class PushTransportConfigurator {
  const PushTransportConfigurator._();

  static PushTransportConfig build({
    required AuthRepositoryContract authRepository,
  }) {
    return PushTransportConfig(
      baseUrl: _resolveBaseUrl(),
      apiPrefix: '/v1/',
      tokenProvider: () async {
        final token = authRepository.userToken;
        return token.isEmpty ? null : token;
      },
      deviceIdProvider: authRepository.getDeviceId,
      enableDebugLogs: kDebugMode,
    );
  }

  static String _resolveBaseUrl() {
    if (GetIt.I.isRegistered<BackendContract>()) {
      final context = GetIt.I.get<BackendContract>().context;
      if (context != null) {
        return context.baseUrl;
      }
    }
    throw StateError(
      'BackendContext is not available via BackendContract for PushTransportConfigurator.',
    );
  }
}
