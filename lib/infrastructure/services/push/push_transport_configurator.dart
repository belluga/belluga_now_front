import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:push_handler/push_handler.dart';

class PushTransportConfigurator {
  const PushTransportConfigurator._();

  static PushTransportConfig build({
    required AuthRepositoryContract authRepository,
  }) {
    return PushTransportConfig(
      baseUrl: BellugaConstants.api.baseUrl,
      tokenProvider: () async {
        final token = authRepository.userToken;
        return token.isEmpty ? null : token;
      },
      deviceIdProvider: authRepository.getDeviceId,
      enableDebugLogs: kDebugMode,
    );
  }
}
