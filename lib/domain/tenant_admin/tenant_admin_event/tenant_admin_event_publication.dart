part of '../tenant_admin_event.dart';

class TenantAdminEventPublication {
  const TenantAdminEventPublication({
    required this.status,
    this.publishAt,
  });

  final String status;
  final DateTime? publishAt;
}
