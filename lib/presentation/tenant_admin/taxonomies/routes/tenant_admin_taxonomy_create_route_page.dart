import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminTaxonomyCreateRoute')
class TenantAdminTaxonomyCreateRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyCreateRoutePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const TenantAdminTaxonomyFormScreen();
  }
}
