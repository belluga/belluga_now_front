part of '../tenant_admin_event.dart';

class TenantAdminEventPlaceRef {
  TenantAdminEventPlaceRef({
    required this.typeValue,
    required this.idValue,
    TenantAdminDynamicMapValue? metadataValue,
  }) : metadataValue = metadataValue ?? TenantAdminDynamicMapValue();

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue idValue;
  final TenantAdminDynamicMapValue metadataValue;

  String get type => typeValue.value;
  String get id => idValue.value;
  Map<String, dynamic>? get metadata =>
      metadataValue.isEmpty ? null : metadataValue.value;
}
