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
    return TenantAdminErrorState(
      userMessage:
          'Você não tem permissão para esta ação no tenant selecionado.',
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
