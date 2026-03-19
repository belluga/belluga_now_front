import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_term_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminTaxonomyTermCreateRoute')
class TenantAdminTaxonomyTermCreateRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyTermCreateRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
    required this.taxonomyName,
  });

  final String taxonomyId;
  final String taxonomyName;

  @override
  Widget build(BuildContext context) {
    return TenantAdminTaxonomyTermFormScreen(
      taxonomyId: taxonomyId,
      taxonomyName: taxonomyName,
    );
  }
}
