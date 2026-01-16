import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
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
      tokenProvider: () async {
        final token = authRepository.userToken;
        return token.isEmpty ? null : token;
      },
      deviceIdProvider: authRepository.getDeviceId,
      enableDebugLogs: kDebugMode,
    );
  }

  static String _resolveBaseUrl() {
    if (GetIt.I.isRegistered<BackendContext>()) {
      return GetIt.I.get<BackendContext>().baseUrl;
    }
    throw StateError(
      'BackendContext is not registered for PushTransportConfigurator.',
    );
  }
}
