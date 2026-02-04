import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomies_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminTaxonomiesListRoute')
class TenantAdminTaxonomiesListRoutePage extends StatelessWidget {
  const TenantAdminTaxonomiesListRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminTaxonomiesListScreen();
  }
}
