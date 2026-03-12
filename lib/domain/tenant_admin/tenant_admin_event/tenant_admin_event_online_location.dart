part of '../tenant_admin_event.dart';

class TenantAdminEventOnlineLocation {
  const TenantAdminEventOnlineLocation({
    required this.url,
    this.platform,
    this.label,
  });

  final String url;
  final String? platform;
  final String? label;
}
