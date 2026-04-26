import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminTaxonomiesSequentialBatchTermsRepository
    implements TenantAdminTaxonomiesBatchTermsRepositoryContract {
  const TenantAdminTaxonomiesSequentialBatchTermsRepository(
    this._taxonomiesRepository,
  );

  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;

  @override
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxRepoString> taxonomyIds,
    TenantAdminTaxRepoInt? termLimit,
  }) async {
    final entries = <TenantAdminTaxonomyTermsForTaxonomyId>[];
    final seen = <String>{};

    for (final taxonomyId in taxonomyIds) {
      final normalizedId = taxonomyId.value.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      final terms = await _taxonomiesRepository.fetchTerms(
        taxonomyId: TenantAdminTaxRepoString.fromRaw(
          normalizedId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      entries.add(
        TenantAdminTaxonomyTermsForTaxonomyId(
          taxonomyIdValue: tenantAdminRequiredText(normalizedId),
          terms: termLimit == null
              ? terms
              : terms.take(termLimit.value).toList(growable: false),
        ),
      );
    }

    return TenantAdminTaxonomyTermsByTaxonomyId(entries: entries);
  }
}
