part of '../tenant_admin_event.dart';

class TenantAdminEventLocation {
  TenantAdminEventLocation({
    required this.modeValue,
    TenantAdminOptionalDoubleValue? latitudeValue,
    TenantAdminOptionalDoubleValue? longitudeValue,
    this.online,
  })  : latitudeValue = latitudeValue ?? const TenantAdminOptionalDoubleValue(null),
        longitudeValue =
            longitudeValue ?? const TenantAdminOptionalDoubleValue(null);

  final TenantAdminRequiredTextValue modeValue;
  final TenantAdminOptionalDoubleValue latitudeValue;
  final TenantAdminOptionalDoubleValue longitudeValue;
  final TenantAdminEventOnlineLocation? online;

  String get mode => modeValue.value;
  double? get latitude => latitudeValue.value;
  double? get longitude => longitudeValue.value;
}
