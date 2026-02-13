import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/screens/tenant_admin_static_profile_types_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticProfileTypesListRoute')
class TenantAdminStaticProfileTypesListRoutePage extends StatelessWidget {
  const TenantAdminStaticProfileTypesListRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminStaticProfileTypesListScreen();
  }
}
