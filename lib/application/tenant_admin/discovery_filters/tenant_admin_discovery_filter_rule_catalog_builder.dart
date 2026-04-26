import 'package:belluga_now/application/tenant_admin/discovery_filters/tenant_admin_taxonomy_terms_by_slug.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_map_filter_rule_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminDiscoveryFilterRuleCatalogBuilder {
  const TenantAdminDiscoveryFilterRuleCatalogBuilder();

  TenantAdminTaxonomyTermsBySlug termsBySlug({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required TenantAdminTaxonomyTermsByTaxonomyId termsByTaxonomyId,
  }) {
    return TenantAdminTaxonomyTermsBySlug.fromTaxonomies(
      taxonomies: taxonomies,
      termsByTaxonomyId: termsByTaxonomyId,
    );
  }

  TenantAdminMapFilterRuleCatalog build({
    required List<TenantAdminProfileTypeDefinition> accountTypes,
    required List<TenantAdminStaticProfileTypeDefinition> staticTypes,
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required TenantAdminTaxonomyTermsBySlug termsBySlug,
    List<TenantAdminEventType> eventTypes = const <TenantAdminEventType>[],
  }) {
    final accountTypeOptions = accountTypes
        .where((item) => item.type.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slugValue: _tokenValue(item.type.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.label.trim().isEmpty ? item.type : item.label.trim(),
            ),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final staticTypeOptions = staticTypes
        .where((item) => item.type.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slugValue: _tokenValue(item.type.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.label.trim().isEmpty ? item.type : item.label.trim(),
            ),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final eventTypeOptions = eventTypes
        .where((item) => item.slug.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slugValue: _tokenValue(item.slug.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.name.trim().isEmpty ? item.slug : item.name.trim(),
            ),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final taxonomyBySource = <TenantAdminMapFilterSource,
        List<TenantAdminMapFilterTaxonomyTermOption>>{
      TenantAdminMapFilterSource.accountProfile:
          <TenantAdminMapFilterTaxonomyTermOption>[],
      TenantAdminMapFilterSource.staticAsset:
          <TenantAdminMapFilterTaxonomyTermOption>[],
      TenantAdminMapFilterSource.event:
          <TenantAdminMapFilterTaxonomyTermOption>[],
    };

    for (final taxonomy in taxonomies) {
      final taxonomySlug = taxonomy.slug.trim().toLowerCase();
      if (taxonomySlug.isEmpty) {
        continue;
      }
      final taxonomyLabel =
          taxonomy.name.trim().isEmpty ? taxonomySlug : taxonomy.name.trim();
      for (final term in termsBySlug.termsForSlug(taxonomy.slug)) {
        final termSlug = term.slug.trim().toLowerCase();
        if (termSlug.isEmpty) {
          continue;
        }
        final option = TenantAdminMapFilterTaxonomyTermOption(
          tokenValue: _tokenValue('$taxonomySlug:$termSlug'),
          labelValue: _requiredTextValue(
            term.name.trim().isEmpty ? term.slug : term.name.trim(),
          ),
          taxonomySlugValue: _tokenValue(taxonomySlug),
          taxonomyLabelValue: _requiredTextValue(taxonomyLabel),
        );
        if (taxonomy.appliesToAccountProfile()) {
          taxonomyBySource[TenantAdminMapFilterSource.accountProfile]!
              .add(option);
        }
        if (taxonomy.appliesToStaticAsset()) {
          taxonomyBySource[TenantAdminMapFilterSource.staticAsset]!.add(option);
        }
        if (taxonomy.appliesToEvent()) {
          taxonomyBySource[TenantAdminMapFilterSource.event]!.add(option);
        }
      }
    }

    for (final source in taxonomyBySource.keys) {
      taxonomyBySource[source] =
          List<TenantAdminMapFilterTaxonomyTermOption>.from(
        taxonomyBySource[source]!,
      )..sort((left, right) {
              final group = left.taxonomyLabel.compareTo(right.taxonomyLabel);
              if (group != 0) {
                return group;
              }
              return left.label.compareTo(right.label);
            });
    }

    return TenantAdminMapFilterRuleCatalog(
      typesBySource: TenantAdminMapFilterTypeOptionsBySourceValue({
        TenantAdminMapFilterSource.accountProfile:
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          accountTypeOptions,
        ),
        TenantAdminMapFilterSource.staticAsset:
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          staticTypeOptions,
        ),
        TenantAdminMapFilterSource.event:
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          eventTypeOptions,
        ),
      }),
      taxonomyTermsBySource: TenantAdminMapFilterTaxonomyOptionsBySourceValue({
        for (final entry in taxonomyBySource.entries)
          entry.key: List<TenantAdminMapFilterTaxonomyTermOption>.unmodifiable(
            entry.value,
          ),
      }),
    );
  }

  TenantAdminLowercaseTokenValue _tokenValue(String raw) =>
      TenantAdminLowercaseTokenValue.fromRaw(raw);

  TenantAdminRequiredTextValue _requiredTextValue(String raw) =>
      TenantAdminRequiredTextValue()..parse(raw);
}
