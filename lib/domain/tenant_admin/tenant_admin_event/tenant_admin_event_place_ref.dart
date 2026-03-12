part of '../tenant_admin_event.dart';

class TenantAdminEventPlaceRef {
  const TenantAdminEventPlaceRef({
    required this.type,
    required this.id,
    this.metadata,
  });

  final String type;
  final String id;
  final Map<String, dynamic>? metadata;
}
