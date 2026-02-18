import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_terms_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminTaxonomyTermsRoute')
class TenantAdminTaxonomyTermsRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyTermsRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
    required this.taxonomyName,
  });

  final String taxonomyId;
  final String taxonomyName;

  @override
  Widget build(BuildContext context) {
    return TenantAdminTaxonomyTermsScreen(
      taxonomyId: taxonomyId,
      taxonomyName: taxonomyName,
    );
  }
}
