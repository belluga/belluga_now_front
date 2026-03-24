part of '../tenant_admin_event.dart';

class TenantAdminEventType {
  TenantAdminEventType({
    required Object name,
    required Object slug,
    Object? id,
    Object? description,
    Object? icon,
    Object? color,
  })  : nameValue = tenantAdminRequiredText(name),
        slugValue = tenantAdminRequiredText(slug),
        idValue = tenantAdminOptionalText(id),
        descriptionValue = tenantAdminOptionalText(description),
        iconValue = tenantAdminOptionalText(icon),
        colorValue = tenantAdminOptionalText(color);

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
