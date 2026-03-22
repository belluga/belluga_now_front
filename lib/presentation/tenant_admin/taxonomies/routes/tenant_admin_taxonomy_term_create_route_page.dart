import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/screens/tenant_admin_taxonomy_term_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminTaxonomyTermCreateRoute')
class TenantAdminTaxonomyTermCreateRoutePage
    extends ResolverRoute<TenantAdminTaxonomyDefinition, TenantAdminModule> {
  const TenantAdminTaxonomyTermCreateRoutePage({
    super.key,
    @PathParam('taxonomyId') required this.taxonomyId,
  });

  final String taxonomyId;

  @override
  RouteResolverParams get resolverParams => {'taxonomyId': taxonomyId};

  @override
  Widget buildScreen(
          BuildContext context, TenantAdminTaxonomyDefinition model) =>
      TenantAdminTaxonomyTermFormScreen(
        taxonomyId: model.id,
        taxonomyName: model.name,
      );
}
