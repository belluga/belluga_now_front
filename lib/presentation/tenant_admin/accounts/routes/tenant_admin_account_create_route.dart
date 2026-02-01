import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

@RoutePage(name: 'TenantAdminAccountCreateRoute')
class TenantAdminAccountCreateRoutePage extends StatelessWidget {
  const TenantAdminAccountCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountCreateScreen(
      controller: GetIt.I.get<TenantAdminAccountsController>(),
      locationPickerController:
          GetIt.I.get<TenantAdminLocationPickerController>(),
    );
  }
}
