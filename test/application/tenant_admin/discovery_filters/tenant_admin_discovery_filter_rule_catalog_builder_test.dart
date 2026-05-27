import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_discovery_filter_rule_catalog_builder.dart';
import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_taxonomy_terms_by_slug.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = TenantAdminDiscoveryFilterRuleCatalogBuilder();

  test('build hydrates event type options beside account and static types', () {
    final catalog = builder.build(
      accountTypes: [
        _accountType(type: 'restaurant', label: 'Restaurantes'),
      ],
      staticTypes: [
        _staticType(type: 'beach', label: 'Praias'),
      ],
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
          .typesForSource(TenantAdminMapFilterSource.staticAsset)
          .map((option) => option.slug),
      <String>['beach'],
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
      accountTypes: [
        _accountType(type: 'restaurant', label: 'Restaurantes'),
      ],
      staticTypes: [
        _staticType(type: 'beach', label: 'Praias'),
      ],
      eventTypes: const [],
      taxonomies: const [],
      termsBySlug: TenantAdminTaxonomyTermsBySlug.fromMap(const {}),
    );

    expect(
      catalog.typesForSource(TenantAdminMapFilterSource.event),
      isEmpty,
    );
    expect(
      catalog.typesForSource(TenantAdminMapFilterSource.accountProfile),
      isNotEmpty,
    );
    expect(
      catalog.typesForSource(TenantAdminMapFilterSource.staticAsset),
      isNotEmpty,
    );
  });
}

TenantAdminEventType _eventType({
  required String name,
  required String slug,
}) {
  return TenantAdminEventType(
    nameValue: _requiredText(name),
    slugValue: _requiredText(slug),
  );
}

TenantAdminProfileTypeDefinition _accountType({
  required String type,
  required String label,
}) {
  return TenantAdminProfileTypeDefinition(
    typeValue: _requiredText(type),
    labelValue: _requiredText(label),
    allowedTaxonomiesValue: TenantAdminTrimmedStringListValue(),
    capabilities: TenantAdminProfileTypeCapabilities(
      isFavoritable: TenantAdminFlagValue(true),
      isPoiEnabled: TenantAdminFlagValue(true),
      hasBio: TenantAdminFlagValue(false),
      hasContent: TenantAdminFlagValue(false),
      hasTaxonomies: TenantAdminFlagValue(false),
      hasAvatar: TenantAdminFlagValue(false),
      hasCover: TenantAdminFlagValue(false),
      hasEvents: TenantAdminFlagValue(false),
    ),
  );
}

TenantAdminStaticProfileTypeDefinition _staticType({
  required String type,
  required String label,
}) {
  return TenantAdminStaticProfileTypeDefinition(
    typeValue: _requiredText(type),
    labelValue: _requiredText(label),
    allowedTaxonomiesValue: TenantAdminTrimmedStringListValue(),
    capabilities: TenantAdminStaticProfileTypeCapabilities(
      isPoiEnabled: TenantAdminFlagValue(true),
      hasBio: TenantAdminFlagValue(false),
      hasTaxonomies: TenantAdminFlagValue(false),
      hasAvatar: TenantAdminFlagValue(false),
      hasCover: TenantAdminFlagValue(false),
      hasContent: TenantAdminFlagValue(false),
    ),
  );
}

TenantAdminRequiredTextValue _requiredText(String raw) {
  return TenantAdminRequiredTextValue()..parse(raw);
}
