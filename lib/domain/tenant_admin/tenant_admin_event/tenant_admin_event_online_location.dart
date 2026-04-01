part of '../tenant_admin_event.dart';

class TenantAdminEventOnlineLocation {
  TenantAdminEventOnlineLocation({
    required this.urlValue,
    TenantAdminOptionalTextValue? platformValue,
    TenantAdminOptionalTextValue? labelValue,
  })  : platformValue = platformValue ?? TenantAdminOptionalTextValue(),
        labelValue = labelValue ?? TenantAdminOptionalTextValue();

  final TenantAdminRequiredTextValue urlValue;
  final TenantAdminOptionalTextValue platformValue;
  final TenantAdminOptionalTextValue labelValue;

  String get url => urlValue.value;
  String? get platform => platformValue.nullableValue;
  String? get label => labelValue.nullableValue;
}
