import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminProfileTypeDetailRoute')
class TenantAdminProfileTypeDetailRoutePage extends StatelessWidget {
  const TenantAdminProfileTypeDetailRoutePage({
    super.key,
    required this.profileType,
    required this.definition,
  });

  final String profileType;
  final TenantAdminProfileTypeDefinition definition;

  @override
  Widget build(BuildContext context) {
    return TenantAdminProfileTypeDetailScreen(definition: definition);
  }
}
