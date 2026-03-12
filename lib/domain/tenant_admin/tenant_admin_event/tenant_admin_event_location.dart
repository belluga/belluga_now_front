part of '../tenant_admin_event.dart';

class TenantAdminEventLocation {
  const TenantAdminEventLocation({
    required this.mode,
    this.latitude,
    this.longitude,
    this.online,
  });

  final String mode;
  final double? latitude;
  final double? longitude;
  final TenantAdminEventOnlineLocation? online;
}
