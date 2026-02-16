import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_term_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminTaxonomyTermDetailRoute')
class TenantAdminTaxonomyTermDetailRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyTermDetailRoutePage({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
    required this.termId,
    required this.term,
  });

  final String taxonomyId;
  final String taxonomyName;
  final String termId;
  final TenantAdminTaxonomyTermDefinition term;

  @override
  Widget build(BuildContext context) {
    return TenantAdminTaxonomyTermDetailScreen(
      taxonomyId: taxonomyId,
      taxonomyName: taxonomyName,
      term: term,
    );
  }
}
