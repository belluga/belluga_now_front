import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/awaiting_module_scope.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/tenant_admin_shell_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminShellRoute')
class TenantAdminShellRoutePage extends StatelessWidget {
  const TenantAdminShellRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AwaitingModuleScope<TenantAdminModule>(
      child: const TenantAdminShellScreen(),
    );
  }
}
