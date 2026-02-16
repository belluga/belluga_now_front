import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminStaticAssetDetailRoute')
class TenantAdminStaticAssetDetailRoutePage extends StatelessWidget {
  const TenantAdminStaticAssetDetailRoutePage({
    super.key,
    required this.assetId,
    required this.asset,
  });

  final String assetId;
  final TenantAdminStaticAsset asset;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStaticAssetDetailScreen(asset: asset);
  }
}
