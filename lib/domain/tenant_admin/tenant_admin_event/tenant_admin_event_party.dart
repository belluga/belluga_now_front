part of '../tenant_admin_event.dart';

class TenantAdminEventParty {
  const TenantAdminEventParty({
    required this.partyType,
    required this.partyRefId,
    required this.canEdit,
    this.metadata,
  });

  final String partyType;
  final String partyRefId;
  final bool canEdit;
  final Map<String, dynamic>? metadata;
}
