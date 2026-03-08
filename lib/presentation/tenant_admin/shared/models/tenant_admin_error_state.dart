class TenantAdminErrorState {
  const TenantAdminErrorState({
    required this.userMessage,
    required this.technicalDetails,
  });

  final String userMessage;
  final String technicalDetails;
}

TenantAdminErrorState resolveTenantAdminErrorState(
  String rawError, {
  required String fallbackMessage,
}) {
  final normalized = rawError.trim().toLowerCase();
  if (normalized.isEmpty) {
    return TenantAdminErrorState(
      userMessage: fallbackMessage,
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('status=401') || normalized.contains('status=403')) {
    if (normalized.contains('origin_access_denied')) {
      return TenantAdminErrorState(
        userMessage:
            'A origem da solicitação foi bloqueada pela política de segurança. Tente novamente pelo tenant correto.',
        technicalDetails: rawError,
      );
    }

    return TenantAdminErrorState(
      userMessage:
          'Você não tem permissão para esta ação no tenant selecionado.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('status=429') ||
      normalized.contains('code=rate_limited') ||
      normalized.contains('rate_limited')) {
    final retryAfterSeconds = _parseRetryAfterSeconds(rawError);
    return TenantAdminErrorState(
      userMessage: retryAfterSeconds == null
          ? 'Muitas requisições em sequência. Aguarde alguns segundos e tente novamente.'
          : 'Muitas requisições em sequência. Aguarde ${retryAfterSeconds}s e tente novamente.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('idempotency_replayed') ||
      normalized.contains('status=409')) {
    return TenantAdminErrorState(
      userMessage:
          'A operação já foi recebida anteriormente. Aguarde e atualize a tela antes de tentar novamente.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('idempotency_missing') ||
      normalized.contains('idempotency_malformed')) {
    return TenantAdminErrorState(
      userMessage:
          'A operação foi bloqueada por proteção de segurança da API. Tente novamente a partir da tela atual.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('status=404')) {
    return TenantAdminErrorState(
      userMessage:
          'Recurso não encontrado para o tenant atual. Verifique o tenant selecionado.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('status=422')) {
    return TenantAdminErrorState(
      userMessage:
          'A solicitação foi rejeitada por dados inválidos. Revise e tente novamente.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('timeout') || normalized.contains('timed out')) {
    return TenantAdminErrorState(
      userMessage:
          'O servidor demorou para responder. Tente novamente em instantes.',
      technicalDetails: rawError,
    );
  }

  if (normalized.contains('socketexception') ||
      normalized.contains('network') ||
      normalized.contains('failed host lookup')) {
    return TenantAdminErrorState(
      userMessage:
          'Não foi possível conectar ao servidor do tenant. Confira a rede e tente novamente.',
      technicalDetails: rawError,
    );
  }

  return TenantAdminErrorState(
    userMessage: fallbackMessage,
    technicalDetails: rawError,
  );
}

int? _parseRetryAfterSeconds(String rawError) {
  final retryAfterPattern =
      RegExp(r'(retry_after|retryAfterSeconds)\s*[=:]\s*(\d+)');
  final match = retryAfterPattern.firstMatch(rawError);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(2) ?? '');
}
