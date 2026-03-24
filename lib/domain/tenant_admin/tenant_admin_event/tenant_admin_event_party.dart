part of '../tenant_admin_event.dart';

class TenantAdminEventParty {
  TenantAdminEventParty({
    required this.partyTypeValue,
    required this.partyRefIdValue,
    required this.canEditValue,
    TenantAdminDynamicMapValue? metadataValue,
  }) : metadataValue = metadataValue ?? TenantAdminDynamicMapValue();

  final TenantAdminRequiredTextValue partyTypeValue;
  final TenantAdminRequiredTextValue partyRefIdValue;
  final TenantAdminFlagValue canEditValue;
  final TenantAdminDynamicMapValue metadataValue;

  String get partyType => partyTypeValue.value;
  String get partyRefId => partyRefIdValue.value;
  bool get canEdit => canEditValue.value;
  Map<String, dynamic>? get metadata =>
      metadataValue.isEmpty ? null : metadataValue.value;
}
