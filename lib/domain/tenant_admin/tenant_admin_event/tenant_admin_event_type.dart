part of '../tenant_admin_event.dart';

class TenantAdminEventType {
  TenantAdminEventType({
    required TenantAdminRequiredTextValue nameValue,
    required TenantAdminRequiredTextValue slugValue,
    TenantAdminOptionalTextValue? idValue,
    TenantAdminOptionalTextValue? descriptionValue,
    TenantAdminOptionalTextValue? iconValue,
    TenantAdminOptionalTextValue? colorValue,
    TenantAdminPoiVisual? visual,
  }) : this.withAllowedTaxonomies(
          nameValue: nameValue,
          slugValue: slugValue,
          idValue: idValue,
          descriptionValue: descriptionValue,
          iconValue: iconValue,
          colorValue: colorValue,
          allowedTaxonomiesValue: TenantAdminTrimmedStringListValue(),
          visual: visual,
        );

  TenantAdminEventType.withAllowedTaxonomies({
    required this.nameValue,
    required this.slugValue,
    TenantAdminOptionalTextValue? idValue,
    TenantAdminOptionalTextValue? descriptionValue,
    TenantAdminOptionalTextValue? iconValue,
    TenantAdminOptionalTextValue? colorValue,
    required this.allowedTaxonomiesValue,
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
  final TenantAdminTrimmedStringListValue allowedTaxonomiesValue;
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
  TenantAdminTrimmedStringListValue get allowedTaxonomies =>
      allowedTaxonomiesValue;
}
