import 'package:belluga_now/domain/repositories/tenant_admin_discovery_filter_rule_catalog_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/controllers/tenant_admin_discovery_filters_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late _SettingsRepository settingsRepository;
  late _RuleCatalogRepository ruleCatalogRepository;

  setUp(() {
    settingsRepository = _SettingsRepository();
    ruleCatalogRepository = _RuleCatalogRepository();
  });

  test(
    'new Map filter remains unsaveable until one entity is chosen',
    () async {
      final controller = _controller(settingsRepository, ruleCatalogRepository);

      controller.addFilterItem(TenantAdminDiscoveryFilterSurfaceDefinition.map);
      final filter = controller
          .filtersForSurface(TenantAdminDiscoveryFilterSurfaceDefinition.map)
          .single;

      expect(filter.query.entities, isEmpty);
      expect(
        controller.filterRuleError(
          TenantAdminDiscoveryFilterSurfaceDefinition.map,
          filter,
        ),
        isNotNull,
      );

      await controller.saveFilters(
        TenantAdminDiscoveryFilterSurfaceDefinition.map,
      );

      expect(settingsRepository.updateCallCount, 0);
      expect(controller.remoteErrorStreamValue.value, contains('exatamente'));
      await controller.onDispose();
    },
  );

  for (final invalidQuery in <String, Map<String, dynamic>>{
    'zero entities': <String, dynamic>{'entities': <String>[]},
    'multiple entities': <String, dynamic>{
      'entities': <String>['event', 'account_profile'],
    },
    'unknown entity': <String, dynamic>{
      'entities': <String>['ticketing'],
    },
    'foreign type-map key': <String, dynamic>{
      'entities': <String>['event'],
      'types_by_entity': <String, dynamic>{
        'account_profile': <String>['restaurant'],
      },
    },
  }.entries) {
    test('${invalidQuery.key} stays intact and blocks Map save', () async {
      settingsRepository.fetchValue = _settingsWithMapQuery(invalidQuery.value);
      final controller = _controller(settingsRepository, ruleCatalogRepository);
      await controller.loadSettings();

      final filter = controller
          .filtersForSurface(TenantAdminDiscoveryFilterSurfaceDefinition.map)
          .single;
      expect(
        filter.query.entities,
        invalidQuery.value['entities'],
        reason: 'Loading must not coerce a legacy invalid rule.',
      );
      expect(
        controller.filterRuleError(
          TenantAdminDiscoveryFilterSurfaceDefinition.map,
          filter,
        ),
        isNotNull,
      );

      await controller.saveFilters(
        TenantAdminDiscoveryFilterSurfaceDefinition.map,
      );
      expect(settingsRepository.updateCallCount, 0);
      await controller.onDispose();
    });
  }

  test('changing the Map entity clears prior types and taxonomy', () async {
    settingsRepository.fetchValue = _settingsWithMapQuery(<String, dynamic>{
      'entities': <String>['event'],
      'types_by_entity': <String, dynamic>{
        'event': <String>['show'],
      },
      'taxonomy': <String, dynamic>{
        'genre': <String>['rock'],
      },
    });
    final controller = _controller(settingsRepository, ruleCatalogRepository);
    await controller.loadSettings();

    controller.updateFilterRule(
      TenantAdminDiscoveryFilterSurfaceDefinition.map,
      0,
      _item(
        TenantAdminDiscoveryFilterQuery(
          entityValues: <TenantAdminLowercaseTokenValue>[
            _token('account_profile'),
          ],
          typeValuesByEntity: <String, List<TenantAdminLowercaseTokenValue>>{
            'account_profile': <TenantAdminLowercaseTokenValue>[
              _token('restaurant'),
            ],
          },
          taxonomyValuesByGroup: <String, List<TenantAdminLowercaseTokenValue>>{
            'genre': <TenantAdminLowercaseTokenValue>[_token('rock')],
          },
        ),
      ),
    );

    final query = controller
        .filtersForSurface(TenantAdminDiscoveryFilterSurfaceDefinition.map)
        .single
        .query;
    expect(query.entities, <String>['account_profile']);
    expect(query.typeValuesByEntity.keys, <String>['account_profile']);
    expect(query.taxonomyValuesByGroup, isEmpty);
    await controller.onDispose();
  });

  test('a non-Map surface keeps its multi-entity default behavior', () async {
    const surface = TenantAdminDiscoveryFilterSurfaceDefinition(
      key: 'test.multi',
      title: 'Teste',
      description: 'Controle negativo',
      target: 'test',
      primarySelectionMode: 'single',
      allowedSources: <TenantAdminMapFilterSource>[
        TenantAdminMapFilterSource.event,
        TenantAdminMapFilterSource.accountProfile,
      ],
      supportsMarkerOverride: false,
    );
    final controller = _controller(settingsRepository, ruleCatalogRepository);

    controller.addFilterItem(surface);

    expect(
      controller.filtersForSurface(surface).single.query.entities,
      <String>['event', 'account_profile'],
    );
    expect(
      controller.filterRuleError(
        surface,
        controller.filtersForSurface(surface).single,
      ),
      isNull,
    );
    await controller.onDispose();
  });
}

TenantAdminDiscoveryFiltersController _controller(
  TenantAdminSettingsRepositoryContract settingsRepository,
  TenantAdminDiscoveryFilterRuleCatalogRepositoryContract ruleCatalogRepository,
) {
  return TenantAdminDiscoveryFiltersController(
    settingsRepository: settingsRepository,
    ruleCatalogRepository: ruleCatalogRepository,
  );
}

TenantAdminDiscoveryFiltersSettingsValue _settingsWithMapQuery(
  Map<String, dynamic> query,
) {
  return TenantAdminDiscoveryFiltersSettingsValue(
    TenantAdminDynamicMapValue(<String, dynamic>{
      'surfaces': <String, dynamic>{
        'public_map.primary': <String, dynamic>{
          'target': 'map_poi',
          'filters': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'legacy',
              'label': 'Legado',
              'query': query,
            },
          ],
        },
      },
    }),
  );
}

TenantAdminDiscoveryFilterCatalogItem _item(
  TenantAdminDiscoveryFilterQuery query,
) {
  return TenantAdminDiscoveryFilterCatalogItem(
    keyValue: _token('legacy'),
    labelValue: TenantAdminRequiredTextValue()..parse('Legado'),
    query: query,
  );
}

TenantAdminLowercaseTokenValue _token(String raw) =>
    TenantAdminLowercaseTokenValue.fromRaw(raw);

class _SettingsRepository extends Mock
    implements TenantAdminSettingsRepositoryContract {
  TenantAdminDiscoveryFiltersSettingsValue fetchValue =
      TenantAdminDiscoveryFiltersSettingsValue();
  int updateCallCount = 0;

  @override
  Future<TenantAdminDiscoveryFiltersSettingsValue>
  fetchDiscoveryFiltersSettings() async => fetchValue;

  @override
  Future<TenantAdminDiscoveryFiltersSettingsValue>
  updateDiscoveryFiltersSettings({
    required TenantAdminDiscoveryFiltersSettingsValue settings,
  }) async {
    updateCallCount += 1;
    return settings;
  }
}

class _RuleCatalogRepository extends Mock
    implements TenantAdminDiscoveryFilterRuleCatalogRepositoryContract {}
