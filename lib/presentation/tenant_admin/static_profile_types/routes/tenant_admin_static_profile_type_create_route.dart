import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/screens/tenant_admin_static_profile_type_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticProfileTypeCreateRoute')
class TenantAdminStaticProfileTypeCreateRoutePage extends StatelessWidget {
  const TenantAdminStaticProfileTypeCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminStaticProfileTypeFormScreen();
  }
}
