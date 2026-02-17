import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
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

@RoutePage(name: 'TenantAdminTaxonomyEditRoute')
class TenantAdminTaxonomyEditRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyEditRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
    required this.taxonomy,
  });

  final String taxonomyId;
  final TenantAdminTaxonomyDefinition taxonomy;

  @override
  Widget build(BuildContext context) {
    return TenantAdminTaxonomyFormScreen(taxonomy: taxonomy);
  }
}
