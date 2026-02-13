import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_assets_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticAssetsListRoute')
class TenantAdminStaticAssetsListRoutePage extends StatelessWidget {
  const TenantAdminStaticAssetsListRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminStaticAssetsListScreen();
  }
}
