import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_create_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticAssetCreateRoute')
class TenantAdminStaticAssetCreateRoutePage extends StatelessWidget {
  const TenantAdminStaticAssetCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminStaticAssetCreateScreen();
  }
}
