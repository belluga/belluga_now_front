import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_discovery_filter_rule_catalog_builder.dart';
import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_taxonomy_terms_by_slug.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = TenantAdminDiscoveryFilterRuleCatalogBuilder();

  test('build hydrates event type options beside account types', () {
    final catalog = builder.build(
      accountTypes: [_accountType(type: 'restaurant', label: 'Restaurantes')],
      eventTypes: [
        _eventType(name: 'Workshop', slug: 'workshop'),
        _eventType(name: 'Show', slug: 'show'),
      ],
      taxonomies: const [],
      termsBySlug: TenantAdminTaxonomyTermsBySlug.fromMap(const {}),
    );

    expect(
      catalog
          .typesForSource(TenantAdminMapFilterSource.accountProfile)
          .map((option) => option.slug),
      <String>['restaurant'],
    );
    expect(
      catalog
          .typesForSource(TenantAdminMapFilterSource.event)
          .map((option) => option.slug),
      <String>['show', 'workshop'],
    );
    expect(
      catalog
          .typesForSource(TenantAdminMapFilterSource.event)
          .map((option) => option.label),
      <String>['Show', 'Workshop'],
    );
  });

  test('build keeps event type options empty when registry is empty', () {
    final catalog = builder.build(
      accountTypes: [_accountType(type: 'restaurant', label: 'Restaurantes')],
      eventTypes: const [],
      taxonomies: const [],
      termsBySlug: TenantAdminTaxonomyTermsBySlug.fromMap(const {}),
    );

    expect(catalog.typesForSource(TenantAdminMapFilterSource.event), isEmpty);
    expect(
      catalog.typesForSource(TenantAdminMapFilterSource.accountProfile),
      isNotEmpty,
    );
  });

  test(
    'build exposes only poi enabled account profile types for map filters',
    () {
      final catalog = builder.build(
        accountTypes: [
          _accountType(
            type: 'restaurant',
            label: 'Restaurantes',
            isMapPoiEnabled: true,
          ),
          _accountType(
            type: 'sponsor',
            label: 'Patrocinadores',
            isMapPoiEnabled: false,
          ),
        ],
        eventTypes: const [],
        taxonomies: const [],
        termsBySlug: TenantAdminTaxonomyTermsBySlug.fromMap(const {}),
      );

      expect(
        catalog
            .typesForSource(TenantAdminMapFilterSource.accountProfile)
            .map((option) => option.slug),
        <String>['restaurant'],
      );
    },
  );
}

TenantAdminEventType _eventType({required String name, required String slug}) {
  return TenantAdminEventType(
    nameValue: _requiredText(name),
    slugValue: _requiredText(slug),
  );
}

TenantAdminProfileTypeDefinition _accountType({
  required String type,
  required String label,
  bool isMapPoiEnabled = true,
}) {
  return TenantAdminProfileTypeDefinition(
    typeValue: _requiredText(type),
    labelValue: _requiredText(label),
    allowedTaxonomiesValue: TenantAdminTrimmedStringListValue(),
    capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
      <String, TenantAdminProfileTypeCapabilityValue>{
        'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: true,
        ),
        'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: isMapPoiEnabled ? 'required' : 'disabled',
        ),
        'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: (TenantAdminFlagValue(isMapPoiEnabled)).value,
        ),
        'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
        'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
        'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
        'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
        'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
      },
    ),
    capabilityRevisionValue: TenantAdminCountValue(),
  );
}

TenantAdminRequiredTextValue _requiredText(String raw) {
  return TenantAdminRequiredTextValue()..parse(raw);
}
