import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

@RoutePage(name: 'TenantAdminProfileTypeCreateRoute')
class TenantAdminProfileTypeCreateRoutePage extends StatelessWidget {
  const TenantAdminProfileTypeCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantAdminProfileTypeFormScreen(
      controller: GetIt.I.get<TenantAdminProfileTypesController>(),
    );
  }
}
