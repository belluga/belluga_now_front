import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_rule_catalog.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_taxonomy_term_option.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_string_list_value.dart';
import 'package:flutter/material.dart';

Future<TenantAdminMapFilterCatalogItem?> showTenantAdminMapFilterRuleSheet({
  required BuildContext context,
  required TenantAdminMapFilterCatalogItem filter,
  required TenantAdminMapFilterRuleCatalog catalog,
}) {
  return showModalBottomSheet<TenantAdminMapFilterCatalogItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return TenantAdminMapFilterRuleSheet(
        filter: filter,
        catalog: catalog,
      );
    },
  );
}

class TenantAdminMapFilterRuleSheet extends StatefulWidget {
  const TenantAdminMapFilterRuleSheet({
    super.key,
    required this.filter,
    required this.catalog,
  });

  final TenantAdminMapFilterCatalogItem filter;
  final TenantAdminMapFilterRuleCatalog catalog;

  @override
  State<TenantAdminMapFilterRuleSheet> createState() =>
      _TenantAdminMapFilterRuleSheetState();
}

class _TenantAdminMapFilterRuleSheetState
    extends State<TenantAdminMapFilterRuleSheet> {
  late TenantAdminMapFilterSource _source;
  late Set<String> _selectedTypes;
  late Set<String> _selectedTaxonomy;

  @override
  void initState() {
    super.initState();
    _source = widget.filter.query.source ?? TenantAdminMapFilterSource.event;
    _selectedTypes = Set<String>.from(widget.filter.query.types);
    _selectedTaxonomy = Set<String>.from(widget.filter.query.taxonomy);
    _sanitizeBySource();
  }

  void _sanitizeBySource() {
    final allowedTypes =
        widget.catalog.typesForSource(_source).map((item) => item.slug).toSet();
    _selectedTypes =
        _selectedTypes.where((entry) => allowedTypes.contains(entry)).toSet();
    final allowedTaxonomy = widget.catalog
        .taxonomyForSource(_source)
        .map((item) => item.token)
        .toSet();
    _selectedTaxonomy = _selectedTaxonomy
        .where((entry) => allowedTaxonomy.contains(entry))
        .toSet();
  }

  TenantAdminMapFilterCatalogItem _buildResult() {
    return widget.filter.copyWith(
      query: TenantAdminMapFilterQuery(
        source: _source,
        typeValues: TenantAdminLowercaseStringListValue(
            _selectedTypes.toList(growable: false)),
        taxonomyValues: TenantAdminLowercaseStringListValue(
          _selectedTaxonomy.toList(growable: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeOptions = widget.catalog.typesForSource(_source);
    final taxonomyOptions = widget.catalog.taxonomyForSource(_source);
    final groupedTaxonomy =
        <String, List<TenantAdminMapFilterTaxonomyTermOption>>{};
    for (final option in taxonomyOptions) {
      groupedTaxonomy
          .putIfAbsent(
            option.taxonomyLabel,
            () => <TenantAdminMapFilterTaxonomyTermOption>[],
          )
          .add(option);
    }

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
              DropdownButtonFormField<TenantAdminMapFilterSource>(
                initialValue: _source,
                decoration: const InputDecoration(
                  labelText: 'Origem',
                ),
                items: TenantAdminMapFilterSource.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _source = value;
                    _sanitizeBySource();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Tipos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (typeOptions.isEmpty)
                Text(
                  'Sem tipos para essa origem.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (typeOptions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: typeOptions.map((option) {
                    return FilterChip(
                      label: Text(option.label),
                      selected: _selectedTypes.contains(option.slug),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(option.slug);
                          } else {
                            _selectedTypes.remove(option.slug);
                          }
                        });
                      },
                    );
                  }).toList(growable: false),
                ),
              const SizedBox(height: 16),
              Text(
                'Taxonomias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (taxonomyOptions.isEmpty)
                Text(
                  'Sem taxonomias para essa origem.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...groupedTaxonomy.entries.map((entry) {
                final options = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((option) {
                          return FilterChip(
                            label: Text(option.label),
                            selected: _selectedTaxonomy.contains(option.token),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTaxonomy.add(option.token);
                                } else {
                                  _selectedTaxonomy.remove(option.token);
                                }
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
                    onPressed: () => context.router.pop(_buildResult()),
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
}
