import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/screens/tenant_admin_static_profile_type_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticProfileTypeDetailRoute')
class TenantAdminStaticProfileTypeDetailRoutePage extends StatelessWidget {
  const TenantAdminStaticProfileTypeDetailRoutePage({
    super.key,
    required this.profileType,
    required this.definition,
  });

  final String profileType;
  final TenantAdminStaticProfileTypeDefinition definition;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStaticProfileTypeDetailScreen(definition: definition);
  }
}
