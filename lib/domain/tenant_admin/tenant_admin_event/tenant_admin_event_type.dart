part of '../tenant_admin_event.dart';

class TenantAdminEventType {
  TenantAdminEventType({
    required this.nameValue,
    required this.slugValue,
    TenantAdminOptionalTextValue? idValue,
    TenantAdminOptionalTextValue? descriptionValue,
    TenantAdminOptionalTextValue? iconValue,
    TenantAdminOptionalTextValue? colorValue,
    this.visual,
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
  final TenantAdminPoiVisual? visual;

  String get name => nameValue.value;
  String get slug => slugValue.value;
  String? get id => idValue.nullableValue;
  String? get description => descriptionValue.nullableValue;
  String? get icon =>
      iconValue.nullableValue ?? (visual?.mode == TenantAdminPoiVisualMode.icon
          ? visual?.icon
          : null);
  String? get color =>
      colorValue.nullableValue ?? (visual?.mode == TenantAdminPoiVisualMode.icon
          ? visual?.color
          : null);
}
