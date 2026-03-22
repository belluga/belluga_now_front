import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminTaxonomyDetailRouteResolver
    implements RouteModelResolver<TenantAdminTaxonomyDefinition> {
  TenantAdminTaxonomyDetailRouteResolver({
    @visibleForTesting
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
  }) : _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>();

  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;

  @override
  Future<TenantAdminTaxonomyDefinition> resolve(
    RouteResolverParams params,
  ) async {
    final taxonomyId = params['taxonomyId'] as String?;
    if (taxonomyId == null || taxonomyId.trim().isEmpty) {
      throw ArgumentError.value(
        taxonomyId,
        'taxonomyId',
        'Taxonomy id must be provided',
      );
    }

    return _taxonomiesRepository.fetchTaxonomy(taxonomyId.trim());
  }
}
