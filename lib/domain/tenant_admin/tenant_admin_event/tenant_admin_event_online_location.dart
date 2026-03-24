part of '../tenant_admin_event.dart';

class TenantAdminEventOnlineLocation {
  TenantAdminEventOnlineLocation({
    required Object url,
    Object? platform,
    Object? label,
  })  : urlValue = tenantAdminRequiredText(url),
        platformValue = tenantAdminOptionalText(platform),
        labelValue = tenantAdminOptionalText(label);

  final TenantAdminRequiredTextValue urlValue;
  final TenantAdminOptionalTextValue platformValue;
  final TenantAdminOptionalTextValue labelValue;

  String get url => urlValue.value;
  String? get platform => platformValue.nullableValue;
  String? get label => labelValue.nullableValue;
}
