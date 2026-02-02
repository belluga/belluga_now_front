import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_types_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminProfileTypesListRoute')
class TenantAdminProfileTypesListRoutePage extends StatelessWidget {
  const TenantAdminProfileTypesListRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminProfileTypesListScreen();
  }
}
