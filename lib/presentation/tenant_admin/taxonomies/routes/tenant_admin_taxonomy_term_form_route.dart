import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
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

@RoutePage(name: 'TenantAdminTaxonomyTermEditRoute')
class TenantAdminTaxonomyTermEditRoutePage extends StatelessWidget {
  const TenantAdminTaxonomyTermEditRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
    required this.taxonomyName,
    @PathParam('termId') required this.termId,
    required this.term,
  });

  final String taxonomyId;
  final String taxonomyName;
  final String termId;
  final TenantAdminTaxonomyTermDefinition term;

  @override
  Widget build(BuildContext context) {
    return TenantAdminTaxonomyTermFormScreen(
      taxonomyId: taxonomyId,
      taxonomyName: taxonomyName,
      term: term,
    );
  }
}
