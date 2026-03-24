part of '../tenant_admin_event.dart';

class TenantAdminEventLocation {
  TenantAdminEventLocation({
    required Object mode,
    Object? latitude,
    Object? longitude,
    this.online,
  })  : modeValue = tenantAdminRequiredText(mode),
        latitudeValue = tenantAdminOptionalDouble(latitude),
        longitudeValue = tenantAdminOptionalDouble(longitude);

  final TenantAdminRequiredTextValue modeValue;
  final TenantAdminOptionalDoubleValue latitudeValue;
  final TenantAdminOptionalDoubleValue longitudeValue;
  final TenantAdminEventOnlineLocation? online;

  String get mode => modeValue.value;
  double? get latitude => latitudeValue.value;
  double? get longitude => longitudeValue.value;
}
