import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_edit_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticAssetEditRoute')
class TenantAdminStaticAssetEditRoutePage extends StatelessWidget {
  const TenantAdminStaticAssetEditRoutePage({
    super.key,
    required this.assetId,
  });

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStaticAssetEditScreen(assetId: assetId);
  }
}
