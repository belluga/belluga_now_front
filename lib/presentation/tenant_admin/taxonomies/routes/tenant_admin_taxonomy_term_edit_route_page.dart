import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_taxonomy_term_route_model.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_term_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminTaxonomyTermEditRoute')
class TenantAdminTaxonomyTermEditRoutePage extends ResolverRoute<
    TenantAdminTaxonomyTermRouteModel, TenantAdminModule> {
  const TenantAdminTaxonomyTermEditRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
    @PathParam('termId') required this.termId,
  });

  final String taxonomyId;
  final String termId;

  @override
  RouteResolverParams get resolverParams => {
        'taxonomyId': taxonomyId,
        'termId': termId,
      };

  @override
  Widget buildScreen(
    BuildContext context,
    TenantAdminTaxonomyTermRouteModel model,
  ) =>
      TenantAdminTaxonomyTermFormScreen(
        taxonomyId: model.taxonomy.id,
        taxonomyName: model.taxonomy.name,
        term: model.term,
      );
}
