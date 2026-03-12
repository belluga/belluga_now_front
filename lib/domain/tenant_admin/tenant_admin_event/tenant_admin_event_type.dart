part of '../tenant_admin_event.dart';

class TenantAdminEventType {
  const TenantAdminEventType({
    required this.name,
    required this.slug,
    this.id,
    this.description,
    this.icon,
    this.color,
  });

  final String name;
  final String slug;
  final String? id;
  final String? description;
  final String? icon;
  final String? color;
}
