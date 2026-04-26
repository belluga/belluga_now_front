import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:flutter/material.dart';

Future<TenantAdminDiscoveryFilterCatalogItem?>
    showTenantAdminDiscoveryFilterRuleSheet({
  required BuildContext context,
  required TenantAdminDiscoveryFilterCatalogItem filter,
  required TenantAdminDiscoveryFilterSurfaceDefinition surface,
  required TenantAdminMapFilterRuleCatalog catalog,
}) {
  return showModalBottomSheet<TenantAdminDiscoveryFilterCatalogItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return TenantAdminDiscoveryFilterRuleSheet(
        filter: filter,
        surface: surface,
        catalog: catalog,
      );
    },
  );
}

class TenantAdminDiscoveryFilterRuleSheet extends StatefulWidget {
  const TenantAdminDiscoveryFilterRuleSheet({
    super.key,
    required this.filter,
    required this.surface,
    required this.catalog,
  });

  final TenantAdminDiscoveryFilterCatalogItem filter;
  final TenantAdminDiscoveryFilterSurfaceDefinition surface;
  final TenantAdminMapFilterRuleCatalog catalog;

  @override
  State<TenantAdminDiscoveryFilterRuleSheet> createState() =>
      _TenantAdminDiscoveryFilterRuleSheetState();
}

class _TenantAdminDiscoveryFilterRuleSheetState
    extends State<TenantAdminDiscoveryFilterRuleSheet> {
  late Set<String> _selectedEntities;
  late Map<String, Set<String>> _selectedTypesByEntity;
  late Map<String, Set<String>> _selectedTaxonomyByGroup;

  @override
  void initState() {
    super.initState();
    _selectedEntities = widget.filter.query.entities.toSet();
    if (_selectedEntities.isEmpty &&
        widget.surface.allowedSources.length == 1) {
      _selectedEntities = {
        widget.surface.allowedSources.first.apiValue,
      };
    }
    _selectedTypesByEntity = {
      for (final entry in widget.filter.query.typeValuesByEntity.entries)
        entry.key: entry.value.map((token) => token.value).toSet(),
    };
    _selectedTaxonomyByGroup = {
      for (final entry in widget.filter.query.taxonomyValuesByGroup.entries)
        entry.key: entry.value.map((token) => token.value).toSet(),
    };
    _sanitizeSelection();
  }

  void _sanitizeSelection() {
    final allowedEntities =
        widget.surface.allowedSources.map((source) => source.apiValue).toSet();
    _selectedEntities =
        _selectedEntities.where(allowedEntities.contains).toSet();
    _selectedTypesByEntity.removeWhere(
      (entity, _) => !_selectedEntities.contains(entity),
    );

    for (final source in widget.surface.allowedSources) {
      final allowedTypes = widget.catalog
          .typesForSource(source)
          .map((option) => option.slug)
          .toSet();
      final selected = _selectedTypesByEntity[source.apiValue];
      if (selected != null) {
        _selectedTypesByEntity[source.apiValue] =
            selected.where(allowedTypes.contains).toSet();
      }
    }

    final allowedTaxonomyValues = <String, Set<String>>{};
    for (final source in widget.surface.allowedSources) {
      if (!_selectedEntities.contains(source.apiValue)) {
        continue;
      }
      for (final option in widget.catalog.taxonomyForSource(source)) {
        allowedTaxonomyValues
            .putIfAbsent(option.taxonomySlug, () => <String>{})
            .add(_termValue(option));
      }
    }
    _selectedTaxonomyByGroup.removeWhere(
      (group, values) {
        final allowed = allowedTaxonomyValues[group] ?? const <String>{};
        values.removeWhere((value) => !allowed.contains(value));
        return values.isEmpty;
      },
    );
  }

  TenantAdminDiscoveryFilterCatalogItem _buildResult() {
    return widget.filter.copyWith(
      query: TenantAdminDiscoveryFilterQuery(
        entityValues: _selectedEntities.map(_tokenValue),
        typeValuesByEntity: {
          for (final entry in _selectedTypesByEntity.entries)
            if (_selectedEntities.contains(entry.key) && entry.value.isNotEmpty)
              entry.key: entry.value.map(_tokenValue),
        },
        taxonomyValuesByGroup: {
          for (final entry in _selectedTaxonomyByGroup.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value.map(_tokenValue),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedTaxonomy = _groupTaxonomyOptions();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Regra do filtro',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Entidades',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.surface.allowedSources.map((source) {
                  return FilterChip(
                    label: Text(source.label),
                    selected: _selectedEntities.contains(source.apiValue),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEntities.add(source.apiValue);
                        } else {
                          _selectedEntities.remove(source.apiValue);
                        }
                        _sanitizeSelection();
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 16),
              ..._typeBlocks(context),
              const SizedBox(height: 8),
              Text(
                'Taxonomias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (groupedTaxonomy.isEmpty)
                Text(
                  'Sem taxonomias para as entidades selecionadas.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...groupedTaxonomy.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.options.map((option) {
                          final term = _termValue(option);
                          final selected =
                              _selectedTaxonomyByGroup[option.taxonomySlug]
                                      ?.contains(term) ==
                                  true;
                          return FilterChip(
                            label: Text(option.label),
                            selected: selected,
                            onSelected: (isSelected) {
                              setState(() {
                                final terms =
                                    _selectedTaxonomyByGroup.putIfAbsent(
                                        option.taxonomySlug, () => <String>{});
                                if (isSelected) {
                                  terms.add(term);
                                } else {
                                  terms.remove(term);
                                }
                                _sanitizeSelection();
                              });
                            },
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.router.maybePop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _selectedEntities.isEmpty
                        ? null
                        : () => context.router.pop(_buildResult()),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typeBlocks(BuildContext context) {
    final blocks = <Widget>[];
    for (final source in widget.surface.allowedSources) {
      if (!_selectedEntities.contains(source.apiValue)) {
        continue;
      }
      final typeOptions = widget.catalog.typesForSource(source);
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipos de ${source.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (typeOptions.isEmpty)
                Text(
                  'Sem tipos para esta entidade.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (typeOptions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: typeOptions.map((option) {
                    final selected = _selectedTypesByEntity[source.apiValue]
                            ?.contains(option.slug) ==
                        true;
                    return FilterChip(
                      label: Text(option.label),
                      selected: selected,
                      onSelected: (isSelected) {
                        setState(() {
                          final selectedTypes = _selectedTypesByEntity
                              .putIfAbsent(source.apiValue, () => <String>{});
                          if (isSelected) {
                            selectedTypes.add(option.slug);
                          } else {
                            selectedTypes.remove(option.slug);
                          }
                          _sanitizeSelection();
                        });
                      },
                    );
                  }).toList(growable: false),
                ),
            ],
          ),
        ),
      );
    }
    return blocks;
  }

  Map<String, _TaxonomyGroup> _groupTaxonomyOptions() {
    final grouped = <String, _TaxonomyGroup>{};
    final seenTokens = <String>{};
    for (final source in widget.surface.allowedSources) {
      if (!_selectedEntities.contains(source.apiValue)) {
        continue;
      }
      for (final option in widget.catalog.taxonomyForSource(source)) {
        final uniqueKey = '${option.taxonomySlug}:${_termValue(option)}';
        if (!seenTokens.add(uniqueKey)) {
          continue;
        }
        grouped
            .putIfAbsent(
              option.taxonomySlug,
              () => _TaxonomyGroup(
                label: option.taxonomyLabel,
                options: <TenantAdminMapFilterTaxonomyTermOption>[],
              ),
            )
            .options
            .add(option);
      }
    }
    return grouped;
  }

  String _termValue(TenantAdminMapFilterTaxonomyTermOption option) {
    final token = option.token;
    final separator = token.indexOf(':');
    return separator <= 0 ? token : token.substring(separator + 1);
  }

  TenantAdminLowercaseTokenValue _tokenValue(String raw) =>
      TenantAdminLowercaseTokenValue.fromRaw(raw);
}

class _TaxonomyGroup {
  _TaxonomyGroup({
    required this.label,
    required this.options,
  });

  final String label;
  final List<TenantAdminMapFilterTaxonomyTermOption> options;
}
