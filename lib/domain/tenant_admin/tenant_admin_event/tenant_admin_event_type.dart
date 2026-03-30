part of '../tenant_admin_event.dart';

class TenantAdminEventType {
  TenantAdminEventType({
    required this.nameValue,
    required this.slugValue,
    TenantAdminOptionalTextValue? idValue,
    TenantAdminOptionalTextValue? descriptionValue,
    TenantAdminOptionalTextValue? iconValue,
    TenantAdminOptionalTextValue? colorValue,
  })  : idValue = idValue ?? TenantAdminOptionalTextValue(),
        descriptionValue = descriptionValue ?? TenantAdminOptionalTextValue(),
        iconValue = iconValue ?? TenantAdminOptionalTextValue(),
        colorValue = colorValue ?? TenantAdminOptionalTextValue();

  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminOptionalTextValue idValue;
  final TenantAdminOptionalTextValue descriptionValue;
  final TenantAdminOptionalTextValue iconValue;
  final TenantAdminOptionalTextValue colorValue;

  String get name => nameValue.value;
  String get slug => slugValue.value;
  String? get id => idValue.nullableValue;
  String? get description => descriptionValue.nullableValue;
  String? get icon => iconValue.nullableValue;
  String? get color => colorValue.nullableValue;
}
