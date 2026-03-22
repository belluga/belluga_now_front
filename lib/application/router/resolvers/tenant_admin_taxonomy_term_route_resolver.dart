import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_taxonomy_term_route_model.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminTaxonomyTermRouteResolver
    implements RouteModelResolver<TenantAdminTaxonomyTermRouteModel> {
  TenantAdminTaxonomyTermRouteResolver({
    @visibleForTesting
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
  }) : _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>();

  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;

  @override
  Future<TenantAdminTaxonomyTermRouteModel> resolve(
    RouteResolverParams params,
  ) async {
    final taxonomyId = params['taxonomyId'] as String?;
    final termId = params['termId'] as String?;
    if (taxonomyId == null || taxonomyId.trim().isEmpty) {
      throw ArgumentError.value(
        taxonomyId,
        'taxonomyId',
        'Taxonomy id must be provided',
      );
    }
    if (termId == null || termId.trim().isEmpty) {
      throw ArgumentError.value(
        termId,
        'termId',
        'Term id must be provided',
      );
    }

    final normalizedTaxonomyId = taxonomyId.trim();
    final normalizedTermId = termId.trim();
    final taxonomy = await _taxonomiesRepository.fetchTaxonomy(
      normalizedTaxonomyId,
    );
    final term = await _taxonomiesRepository.fetchTerm(
      taxonomyId: normalizedTaxonomyId,
      termId: normalizedTermId,
    );
    return TenantAdminTaxonomyTermRouteModel(
      taxonomy: taxonomy,
      term: term,
    );
  }
}
