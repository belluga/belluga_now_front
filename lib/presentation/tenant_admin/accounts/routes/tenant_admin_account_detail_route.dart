import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

@RoutePage(name: 'TenantAdminAccountDetailRoute')
class TenantAdminAccountDetailRoutePage extends StatelessWidget {
  const TenantAdminAccountDetailRoutePage({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountDetailScreen(
      accountSlug: accountSlug,
      profilesController: GetIt.I.get<TenantAdminAccountProfilesController>(),
      locationPickerController:
          GetIt.I.get<TenantAdminLocationPickerController>(),
    );
  }
}
