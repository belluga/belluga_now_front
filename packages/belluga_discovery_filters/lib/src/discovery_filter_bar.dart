import 'package:flutter/material.dart';

import 'discovery_filter_catalog.dart';
import 'discovery_filter_policy.dart';
import 'discovery_filter_selection.dart';
import 'discovery_filter_taxonomy_scope.dart';

typedef DiscoveryFilterIconBuilder = Widget Function(
  BuildContext context,
  DiscoveryFilterCatalogItem item,
  bool isActive,
  Color foregroundColor,
);

class DiscoveryFilterBar extends StatelessWidget {
  const DiscoveryFilterBar({
    super.key,
    required this.catalog,
    required this.selection,
    required this.policy,
    required this.onSelectionChanged,
    this.isLoading = false,
    this.iconBuilder,
  });

  final DiscoveryFilterCatalog catalog;
  final DiscoveryFilterSelection selection;
  final DiscoveryFilterPolicy policy;
  final ValueChanged<DiscoveryFilterSelection> onSelectionChanged;
  final bool isLoading;
  final DiscoveryFilterIconBuilder? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final filters = catalog.filters.where((item) => item.isValid).toList(
          growable: false,
        );
    final taxonomyGroups = _resolveTaxonomyGroups(filters);
    final taxonomyAreaKey = ValueKey<String>(
      'discoveryFilterTaxonomyArea_${_taxonomySelectionKey()}',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimaryRow(context, filters),
        if (taxonomyGroups.isNotEmpty) ...[
          KeyedSubtree(
            key: taxonomyAreaKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Divider(
                  key: const ValueKey<String>('discoveryFilterTaxonomyDivider'),
                  height: 1,
                  thickness: 0.6,
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.38),
                ),
                const SizedBox(height: 10),
                for (final group in taxonomyGroups) ...[
                  _TaxonomyGroupBlock(
                    group: group,
                    selection: selection,
                    fallbackPolicy: policy,
                    isLoading: isLoading,
                    onToggle: _toggleTaxonomyTerm,
                  ),
                  if (group != taxonomyGroups.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryRow(
    BuildContext context,
    List<DiscoveryFilterCatalogItem> filters,
  ) {
    final chips = filters
        .map(
          (item) => _PrimaryFilterChip(
            item: item,
            isActive: selection.primaryKeys.contains(item.key),
            isLoading: isLoading && selection.primaryKeys.contains(item.key),
            iconBuilder: iconBuilder,
            onToggle: _togglePrimary,
          ),
        )
        .toList(growable: false);

    if (policy.primaryLayoutMode == DiscoveryFilterLayoutMode.wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final chip in chips) ...[
            chip,
            if (chip != chips.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  void _togglePrimary(DiscoveryFilterCatalogItem item) {
    if (isLoading) {
      return;
    }
    onSelectionChanged(
      selection.togglePrimary(item.key, mode: policy.primarySelectionMode),
    );
  }

  void _toggleTaxonomyTerm(
    _ResolvedTaxonomyGroup group,
    DiscoveryFilterTaxonomyTermOption term,
  ) {
    if (isLoading) {
      return;
    }
    onSelectionChanged(
      selection.toggleTaxonomyTerm(
        group.option.key,
        term.value,
        mode: group.config.selectionMode,
      ),
    );
  }

  List<_ResolvedTaxonomyGroup> _resolveTaxonomyGroups(
    List<DiscoveryFilterCatalogItem> filters,
  ) {
    final selectedFilters = filters
        .where((item) => selection.primaryKeys.contains(item.key))
        .toList(growable: false);

    final orderedKeys = <String>[];
    final configs = <String, DiscoveryFilterTaxonomyConfig>{};
    if (selectedFilters.isEmpty) {
      orderedKeys.addAll(catalog.taxonomyOptionsByKey.keys);
    }
    for (final item in selectedFilters) {
      for (final entry in item.taxonomyConfigs.entries) {
        configs[entry.key] = entry.value;
      }
      for (final taxonomyKey in resolveDiscoveryFilterAllowedTaxonomyKeys(
        catalog: catalog,
        selection: DiscoveryFilterSelection(primaryKeys: <String>{item.key}),
      )) {
        if (!orderedKeys.contains(taxonomyKey)) {
          orderedKeys.add(taxonomyKey);
        }
      }
    }

    final groups = <_ResolvedTaxonomyGroup>[];
    for (final taxonomyKey in orderedKeys) {
      final option = catalog.taxonomyOptionsByKey[taxonomyKey];
      if (option == null || option.terms.isEmpty) {
        continue;
      }
      groups.add(
        _ResolvedTaxonomyGroup(
          option: option,
          config: configs[taxonomyKey] ??
              DiscoveryFilterTaxonomyConfig(
                taxonomyKey: taxonomyKey,
                selectionMode: policy.taxonomySelectionMode,
              ),
          layoutMode: policy.taxonomyLayoutMode,
        ),
      );
    }

    return groups;
  }

  String _taxonomySelectionKey() {
    final primary = selection.primaryKeys.toList(growable: false)..sort();
    final taxonomy = selection.taxonomyTermKeys.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final taxonomySegments = taxonomy
        .map((entry) {
          final values = entry.value.toList(growable: false)..sort();
          return '${entry.key}:${values.join(",")}';
        })
        .join('|');
    return '${primary.join(",")}__$taxonomySegments';
  }
}

class _PrimaryFilterChip extends StatelessWidget {
  const _PrimaryFilterChip({
    required this.item,
    required this.isActive,
    required this.isLoading,
    required this.iconBuilder,
    required this.onToggle,
  });

  final DiscoveryFilterCatalogItem item;
  final bool isActive;
  final bool isLoading;
  final DiscoveryFilterIconBuilder? iconBuilder;
  final ValueChanged<DiscoveryFilterCatalogItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = _ChipPalette.resolve(context, item.colorHex, isActive);

    if (!isActive) {
      return Semantics(
        key: ValueKey<String>('discoveryFilterPrimarySemantics_${item.key}'),
        container: true,
        button: true,
        focusable: true,
        label: item.label,
        onTap: isLoading ? null : () => onToggle(item),
        child: ExcludeSemantics(
          child: Tooltip(
            message: item.label,
            child: Material(
              key: ValueKey<String>('discoveryFilterPrimary_${item.key}'),
              color: palette.backgroundColor,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isLoading ? null : () => onToggle(item),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: iconBuilder?.call(
                          context,
                          item,
                          false,
                          palette.foregroundColor,
                        ) ??
                        Icon(
                          Icons.filter_alt_rounded,
                          size: 20,
                          color: palette.foregroundColor,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      key: ValueKey<String>(
        'discoveryFilterSelectedPrimarySemantics_${item.key}',
      ),
      container: true,
      button: true,
      focusable: true,
      label: item.label,
      selected: true,
      toggled: true,
      onTap: isLoading ? null : () => onToggle(item),
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey<String>('discoveryFilterSelectedPrimary_${item.key}'),
          decoration: BoxDecoration(
            color: palette.backgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBuilder?.call(
                      context,
                      item,
                      true,
                      palette.foregroundColor,
                    ) ??
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: palette.foregroundColor,
                    ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                if (isLoading)
                  SizedBox(
                    key: ValueKey<String>(
                      'discoveryFilterPrimaryLoading_${item.key}',
                    ),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.foregroundColor,
                      ),
                    ),
                  )
                else
                  _ChipClearButton(
                    key: ValueKey<String>(
                      'discoveryFilterPrimaryClear_${item.key}',
                    ),
                    palette: palette,
                    tooltip: 'Remover filtro',
                    onTap: () => onToggle(item),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxonomyGroupBlock extends StatelessWidget {
  const _TaxonomyGroupBlock({
    required this.group,
    required this.selection,
    required this.fallbackPolicy,
    required this.isLoading,
    required this.onToggle,
  });

  final _ResolvedTaxonomyGroup group;
  final DiscoveryFilterSelection selection;
  final DiscoveryFilterPolicy fallbackPolicy;
  final bool isLoading;
  final void Function(
    _ResolvedTaxonomyGroup group,
    DiscoveryFilterTaxonomyTermOption term,
  ) onToggle;

  @override
  Widget build(BuildContext context) {
    final children = group.option.terms
        .map(
          (term) => _TaxonomyTermChip(
            group: group,
            term: term,
            isSelected: selection.taxonomyTermKeys[group.option.key]?.contains(
                  term.value,
                ) ??
                false,
            isLoading: isLoading,
            onToggle: onToggle,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.config.showLabel) ...[
          Text(
            key: ValueKey<String>(
              'discoveryFilterTaxonomyTitle_${group.option.key}',
            ),
            group.config.labelOverride?.trim().isNotEmpty ?? false
                ? group.config.labelOverride!.trim()
                : group.option.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (group.layoutMode == DiscoveryFilterLayoutMode.wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final child in children) ...[
                  child,
                  if (child != children.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TaxonomyTermChip extends StatelessWidget {
  const _TaxonomyTermChip({
    required this.group,
    required this.term,
    required this.isSelected,
    required this.isLoading,
    required this.onToggle,
  });

  final _ResolvedTaxonomyGroup group;
  final DiscoveryFilterTaxonomyTermOption term;
  final bool isSelected;
  final bool isLoading;
  final void Function(
    _ResolvedTaxonomyGroup group,
    DiscoveryFilterTaxonomyTermOption term,
  ) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _ChipPalette(
      backgroundColor:
          isSelected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      foregroundColor:
          isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      controlBackgroundColor: isSelected
          ? scheme.onPrimaryContainer.withValues(alpha: 0.12)
          : scheme.onSurfaceVariant.withValues(alpha: 0.08),
    );
    final keyPrefix = isSelected
        ? 'discoveryFilterSelectedTaxonomy'
        : 'discoveryFilterTaxonomyChip';

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: term.label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey<String>(
            '${keyPrefix}_${group.option.key}_${term.value}',
          ),
          decoration: BoxDecoration(
            color: palette.backgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : () => onToggle(group, term),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      term.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: palette.foregroundColor,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      if (isLoading)
                        SizedBox(
                          key: ValueKey<String>(
                            'discoveryFilterTaxonomyLoading_${group.option.key}_${term.value}',
                          ),
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.foregroundColor,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: palette.foregroundColor,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedTaxonomyGroup {
  const _ResolvedTaxonomyGroup({
    required this.option,
    required this.config,
    required this.layoutMode,
  });

  final DiscoveryFilterTaxonomyGroupOption option;
  final DiscoveryFilterTaxonomyConfig config;
  final DiscoveryFilterLayoutMode layoutMode;
}

class _ChipClearButton extends StatelessWidget {
  const _ChipClearButton({
    super.key,
    required this.palette,
    required this.tooltip,
    required this.onTap,
  });

  final _ChipPalette palette;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.controlBackgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: palette.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPalette {
  const _ChipPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.controlBackgroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color controlBackgroundColor;

  factory _ChipPalette.resolve(
    BuildContext context,
    String? colorHex,
    bool isActive,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = _ChipPalette(
      backgroundColor:
          isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      foregroundColor:
          isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      controlBackgroundColor: isActive
          ? scheme.onPrimaryContainer.withValues(alpha: 0.12)
          : scheme.onSurfaceVariant.withValues(alpha: 0.08),
    );

    if (!isActive) {
      return fallback;
    }

    final parsed = _tryParseColor(colorHex);
    if (parsed == null) {
      return fallback;
    }

    return _ChipPalette(
      backgroundColor: parsed,
      foregroundColor: _foregroundFor(parsed),
      controlBackgroundColor: _foregroundFor(parsed).withValues(alpha: 0.16),
    );
  }
}

Color? _tryParseColor(String? raw) {
  final normalized = raw?.trim().replaceFirst('#', '');
  if (normalized == null || normalized.length != 6) {
    return null;
  }
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
