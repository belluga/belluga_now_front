part of '../tenant_admin_event.dart';

class TenantAdminEventPlaceRef {
  TenantAdminEventPlaceRef({
    required this.typeValue,
    required this.idValue,
  });

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue idValue;

  String get type => typeValue.value;
  String get id => idValue.value;
}
