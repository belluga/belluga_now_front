import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminStaticAssetEditRoute')
class TenantAdminStaticAssetEditRoutePage
    extends ResolverRoute<TenantAdminStaticAsset, TenantAdminModule> {
  const TenantAdminStaticAssetEditRoutePage({
    super.key,
    @PathParam('assetId') required this.assetId,
  });

  final String assetId;

  @override
  RouteResolverParams get resolverParams => {'assetId': assetId};

  @override
  Widget buildScreen(BuildContext context, TenantAdminStaticAsset model) =>
      TenantAdminStaticAssetEditScreen(assetId: model.id);
}
