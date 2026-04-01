part of '../tenant_admin_event.dart';

class TenantAdminEventParty {
  TenantAdminEventParty({
    required this.partyTypeValue,
    required this.partyRefIdValue,
    required this.canEditValue,
  });

  final TenantAdminRequiredTextValue partyTypeValue;
  final TenantAdminRequiredTextValue partyRefIdValue;
  final TenantAdminFlagValue canEditValue;

  String get partyType => partyTypeValue.value;
  String get partyRefId => partyRefIdValue.value;
  bool get canEdit => canEditValue.value;
}
