import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_error_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps rate-limited failures with retry_after hint', () {
    final state = resolveTenantAdminErrorState(
      'FormApiFailure(status=429, message=Too many requests. Retry later., '
      'code=rate_limited, retryAfterSeconds=17, correlationId=corr-1)',
      fallbackMessage: 'Falha ao carregar.',
    );

    expect(state.userMessage, contains('17s'));
  });

  test('maps origin_access_denied to security origin guidance', () {
    final state = resolveTenantAdminErrorState(
      'FormApiFailure(status=403, message=Direct origin access is not allowed., '
      'code=origin_access_denied)',
      fallbackMessage: 'Falha ao carregar.',
    );

    expect(state.userMessage, contains('origem'));
  });

  test('maps idempotency replay conflicts to duplicate-operation guidance', () {
    final state = resolveTenantAdminErrorState(
      'FormApiFailure(status=409, message=Request is already being processed., '
      'code=idempotency_replayed)',
      fallbackMessage: 'Falha ao carregar.',
    );

    expect(state.userMessage, contains('já foi recebida'));
  });
}
