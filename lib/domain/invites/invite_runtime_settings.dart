class InviteRuntimeSettings {
  const InviteRuntimeSettings({
    required this.tenantId,
    required this.limits,
    required this.cooldowns,
    required this.overQuotaMessage,
  });

  final String? tenantId;
  final Map<String, int> limits;
  final Map<String, int> cooldowns;
  final String? overQuotaMessage;
}
