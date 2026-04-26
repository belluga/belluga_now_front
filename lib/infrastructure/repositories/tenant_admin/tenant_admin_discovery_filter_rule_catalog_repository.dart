import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_discovery_filter_rule_catalog_builder.dart';
import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_taxonomy_terms_by_slug.dart';
import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_taxonomies_sequential_batch_terms_repository.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_discovery_filter_rule_catalog_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminDiscoveryFilterRuleCatalogRepository
    implements TenantAdminDiscoveryFilterRuleCatalogRepositoryContract {
  static const int _taxonomyBatchSize = 100;
  static const int _taxonomyGroupBudget = 20;
  static const int _termsPerTaxonomyBudget = 200;

  TenantAdminDiscoveryFilterRuleCatalogRepository({
    required TenantAdminAccountProfilesRepositoryContract
        accountProfilesRepository,
    required TenantAdminStaticAssetsRepositoryContract staticAssetsRepository,
    required TenantAdminTaxonomiesRepositoryContract taxonomiesRepository,
    TenantAdminTaxonomiesBatchTermsRepositoryContract? batchTermsRepository,
    required TenantAdminEventsRepositoryContract eventsRepository,
    TenantAdminDiscoveryFilterRuleCatalogBuilder catalogBuilder =
        const TenantAdminDiscoveryFilterRuleCatalogBuilder(),
  })  : _accountProfilesRepository = accountProfilesRepository,
        _staticAssetsRepository = staticAssetsRepository,
        _taxonomiesRepository = taxonomiesRepository,
        _batchTermsRepository = _resolveBatchTermsRepository(
          taxonomiesRepository: taxonomiesRepository,
          batchTermsRepository: batchTermsRepository,
        ),
        _eventsRepository = eventsRepository,
        _catalogBuilder = catalogBuilder;

  final TenantAdminAccountProfilesRepositoryContract _accountProfilesRepository;
  final TenantAdminStaticAssetsRepositoryContract _staticAssetsRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminTaxonomiesBatchTermsRepositoryContract _batchTermsRepository;
  final TenantAdminEventsRepositoryContract _eventsRepository;
  final TenantAdminDiscoveryFilterRuleCatalogBuilder _catalogBuilder;

  static TenantAdminTaxonomiesBatchTermsRepositoryContract
      _resolveBatchTermsRepository({
    required TenantAdminTaxonomiesRepositoryContract taxonomiesRepository,
    TenantAdminTaxonomiesBatchTermsRepositoryContract? batchTermsRepository,
  }) {
    if (batchTermsRepository != null) {
      return batchTermsRepository;
    }
    final Object batchRepository = taxonomiesRepository;
    if (batchRepository is TenantAdminTaxonomiesBatchTermsRepositoryContract) {
      return batchRepository;
    }

    return TenantAdminTaxonomiesSequentialBatchTermsRepository(
      taxonomiesRepository,
    );
  }

  @override
  Future<TenantAdminMapFilterRuleCatalog> fetchRuleCatalog() async {
    final eventTypesFuture = _eventsRepository.fetchEventTypes();
    await Future.wait<void>([
      _accountProfilesRepository.loadAllProfileTypes(),
      _staticAssetsRepository.loadAllStaticProfileTypes(),
      _taxonomiesRepository.loadAllTaxonomies(),
    ]);

    final accountTypes =
        _accountProfilesRepository.profileTypesStreamValue.value ??
            const <TenantAdminProfileTypeDefinition>[];
    final staticTypes =
        _staticAssetsRepository.staticProfileTypesStreamValue.value ??
            const <TenantAdminStaticProfileTypeDefinition>[];
    final eventTypes = await eventTypesFuture;
    final taxonomies = _taxonomiesRepository.taxonomiesStreamValue.value ??
        const <TenantAdminTaxonomyDefinition>[];
    final relevantTaxonomies = _relevantTaxonomies(
      taxonomies: taxonomies,
      accountTypes: accountTypes,
      staticTypes: staticTypes,
      eventTypes: eventTypes,
    );
    final termsByTaxonomySlug =
        await _loadTermsByTaxonomySlug(relevantTaxonomies);

    return _catalogBuilder.build(
      accountTypes: accountTypes,
      staticTypes: staticTypes,
      eventTypes: eventTypes,
      taxonomies: relevantTaxonomies,
      termsBySlug: termsByTaxonomySlug,
    );
  }

  List<TenantAdminTaxonomyDefinition> _relevantTaxonomies({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required List<TenantAdminProfileTypeDefinition> accountTypes,
    required List<TenantAdminStaticProfileTypeDefinition> staticTypes,
    required List<TenantAdminEventType> eventTypes,
  }) {
    final referencedSlugs = <String>{
      for (final type in accountTypes)
        ...type.allowedTaxonomies.value
            .map((slug) => slug.trim().toLowerCase()),
      for (final type in staticTypes)
        ...type.allowedTaxonomies.value
            .map((slug) => slug.trim().toLowerCase()),
      for (final type in eventTypes)
        ...type.allowedTaxonomies.value
            .map((slug) => slug.trim().toLowerCase()),
    }..remove('');

    if (referencedSlugs.isEmpty) {
      return const <TenantAdminTaxonomyDefinition>[];
    }

    final relevant = taxonomies
        .where((taxonomy) =>
            referencedSlugs.contains(taxonomy.slug.trim().toLowerCase()) &&
            taxonomy.id.trim().isNotEmpty)
        .toList(growable: false);
    relevant.sort(
      (left, right) => left.slug.toLowerCase().compareTo(
            right.slug.toLowerCase(),
          ),
    );

    return relevant.take(_taxonomyGroupBudget).toList(growable: false);
  }

  Future<TenantAdminTaxonomyTermsBySlug> _loadTermsByTaxonomySlug(
    List<TenantAdminTaxonomyDefinition> taxonomies,
  ) async {
    final requestedTaxonomies = taxonomies
        .where((taxonomy) =>
            taxonomy.id.trim().isNotEmpty && taxonomy.slug.trim().isNotEmpty)
        .toList(growable: false);
    final fetchedEntries = <TenantAdminTaxonomyTermsForTaxonomyId>[];
    final requestedIds = requestedTaxonomies
        .map(
          (taxonomy) => TenantAdminTaxRepoString.fromRaw(
            taxonomy.id,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .toList(growable: false);
    for (var offset = 0;
        offset < requestedIds.length;
        offset += _taxonomyBatchSize) {
      final chunk = requestedIds
          .skip(offset)
          .take(_taxonomyBatchSize)
          .toList(growable: false);
      final batch = await _batchTermsRepository.fetchTermsByTaxonomyIds(
        taxonomyIds: chunk,
        termLimit: tenantAdminTaxRepoInt(
          _termsPerTaxonomyBudget,
          defaultValue: _termsPerTaxonomyBudget,
        ),
      );
      for (final taxonomyId in chunk) {
        fetchedEntries.add(
          TenantAdminTaxonomyTermsForTaxonomyId(
            taxonomyIdValue: tenantAdminRequiredText(taxonomyId.value),
            terms: batch.termsForId(tenantAdminRequiredText(taxonomyId.value)),
          ),
        );
      }
    }
    final fetchedById = TenantAdminTaxonomyTermsByTaxonomyId(
      entries: fetchedEntries,
    );
    return _catalogBuilder.termsBySlug(
      taxonomies: requestedTaxonomies,
      termsByTaxonomyId: fetchedById,
    );
  }
}
