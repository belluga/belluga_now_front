import 'dart:async';

import 'package:flutter/foundation.dart';
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
    this.autoRevealSelectedChips = true,
  });

  final DiscoveryFilterCatalog catalog;
  final DiscoveryFilterSelection selection;
  final DiscoveryFilterPolicy policy;
  final ValueChanged<DiscoveryFilterSelection> onSelectionChanged;
  final bool isLoading;
  final DiscoveryFilterIconBuilder? iconBuilder;

  /// Measurement-only copies of the bar opt out of post-frame reveal work.
  final bool autoRevealSelectedChips;

  @override
  Widget build(BuildContext context) {
    final filters = catalog.filters.where((item) => item.isValid).toList(
          growable: false,
        );
    final taxonomyGroups = _resolveTaxonomyGroups(filters);
    const taxonomyAreaKey = ValueKey<String>('discoveryFilterTaxonomyArea');

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
                    key: ValueKey<String>(
                      'discoveryFilterTaxonomyGroup_${group.option.key}',
                    ),
                    group: group,
                    selection: selection,
                    fallbackPolicy: policy,
                    isLoading: isLoading,
                    autoRevealSelectedChips: autoRevealSelectedChips,
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
    if (policy.primaryLayoutMode == DiscoveryFilterLayoutMode.wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters
            .map(
              (item) => _PrimaryFilterChip(
                item: item,
                isActive: selection.primaryKeys.contains(item.key),
                isLoading:
                    isLoading && selection.primaryKeys.contains(item.key),
                iconBuilder: iconBuilder,
                onToggle: _togglePrimary,
              ),
            )
            .toList(growable: false),
      );
    }

    return SizedBox(
      height: 48,
      child: _HorizontalRevealRow(
        key: const ValueKey<String>('discoveryFilterPrimaryList'),
        anchorId:
            autoRevealSelectedChips ? _firstSelectedPrimaryKey(filters) : null,
        selectedItemIds: filters
            .where((item) => selection.primaryKeys.contains(item.key))
            .map((item) => item.key)
            .toList(growable: false),
        selectionMode: policy.primarySelectionMode,
        children: filters.map((item) {
          final isActive = selection.primaryKeys.contains(item.key);
          return _HorizontalRevealRowItem(
            identity: item.key,
            child: _PrimaryFilterChip(
              key: ValueKey<String>('discoveryFilterPrimaryItem_${item.key}'),
              item: item,
              isActive: isActive,
              isLoading: isLoading && isActive,
              iconBuilder: iconBuilder,
              onToggle: _togglePrimary,
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  void _togglePrimary(DiscoveryFilterCatalogItem item) {
    onSelectionChanged(
      selection.togglePrimary(item.key, mode: policy.primarySelectionMode),
    );
  }

  String? _firstSelectedPrimaryKey(List<DiscoveryFilterCatalogItem> filters) {
    for (final item in filters) {
      if (selection.primaryKeys.contains(item.key)) {
        return item.key;
      }
    }
    return null;
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
    if (selectedFilters.isEmpty) {
      return const <_ResolvedTaxonomyGroup>[];
    }

    final orderedKeys = <String>[];
    final configs = <String, DiscoveryFilterTaxonomyConfig>{};
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
}

class _PrimaryFilterChip extends StatelessWidget {
  const _PrimaryFilterChip({
    super.key,
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
    final semanticsKey = 'discoveryFilterPrimarySemantics_${item.key}';
    final chipKey = 'discoveryFilterPrimary_${item.key}';

    return Semantics(
      key: ValueKey<String>(semanticsKey),
      container: true,
      button: true,
      focusable: true,
      label: item.label,
      selected: isActive,
      toggled: isActive,
      onTap: isLoading ? null : () => _toggleFromRow(context),
      child: ExcludeSemantics(
        child: Tooltip(
          message: item.label,
          child: DecoratedBox(
            key: ValueKey<String>(chipKey),
            decoration: BoxDecoration(
              color: palette.backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : () => _toggleFromRow(context),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconBuilder?.call(
                            context,
                            item,
                            isActive,
                            palette.foregroundColor,
                          ) ??
                          Icon(
                            isActive
                                ? Icons.tune_rounded
                                : Icons.filter_alt_rounded,
                            size: 20,
                            color: palette.foregroundColor,
                          ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: palette.foregroundColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (isActive) ...[
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
                            onTap: () => _toggleFromRow(context),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFromRow(BuildContext context) {
    _RowInteractionScope.maybeOf(context)?.markUserInteraction(item.key);
    onToggle(item);
  }
}

class _HorizontalRevealRow extends StatefulWidget {
  const _HorizontalRevealRow({
    super.key,
    required this.anchorId,
    required this.selectedItemIds,
    required this.selectionMode,
    required this.children,
  });

  final String? anchorId;
  final List<String> selectedItemIds;
  final DiscoveryFilterSelectionMode selectionMode;
  final List<_HorizontalRevealRowItem> children;

  @override
  State<_HorizontalRevealRow> createState() => _HorizontalRevealRowState();
}

class _HorizontalRevealRowState extends State<_HorizontalRevealRow> {
  final _anchorKey = GlobalKey();
  bool _revealScheduled = false;
  bool _disposed = false;
  List<String>? _pendingSuppressionSelection;

  @override
  void initState() {
    super.initState();
    _scheduleReveal(widget.anchorId);
  }

  @override
  void didUpdateWidget(covariant _HorizontalRevealRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new anchor can come from persisted selection hydration.  Already
    // mounted anchors are intentionally not replayed after equivalent builds.
    final anchorWasAddedToCatalog = widget.anchorId != null &&
        !oldWidget.children.any((item) => item.identity == widget.anchorId);
    // Consume a row interaction only when its expected selection publication
    // arrives. Loading/catalog rebuilds can happen before that publication.
    final pendingSelection = _pendingSuppressionSelection;
    final selectionChanged = !listEquals(
      oldWidget.selectedItemIds,
      widget.selectedItemIds,
    );
    final suppressThisUpdate = pendingSelection != null &&
        selectionChanged &&
        listEquals(pendingSelection, widget.selectedItemIds);
    if (selectionChanged && pendingSelection != null) {
      _pendingSuppressionSelection = null;
    }
    if (oldWidget.anchorId != widget.anchorId &&
        (suppressThisUpdate && !anchorWasAddedToCatalog)) {
      return;
    }
    if (oldWidget.anchorId != widget.anchorId) {
      _scheduleReveal(widget.anchorId);
    }
  }

  void _scheduleReveal(String? anchorId) {
    if (anchorId == null || _revealScheduled) {
      return;
    }
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (_disposed) {
        return;
      }
      if (widget.anchorId != anchorId) {
        _scheduleReveal(widget.anchorId);
        return;
      }
      final targetContext = _anchorKey.currentContext;
      if (targetContext == null) {
        return;
      }
      _revealHorizontallyIfNeeded(targetContext);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _RowInteractionScope(
        markUserInteraction: _markUserInteraction,
        child: Row(
          children: [
            for (var index = 0; index < widget.children.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              KeyedSubtree(
                key: widget.anchorId != null &&
                        widget.children[index].identity == widget.anchorId
                    ? _anchorKey
                    : null,
                child: widget.children[index].child,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markUserInteraction(String toggledIdentity) {
    final selected = widget.selectedItemIds.toSet();
    if (!selected.remove(toggledIdentity)) {
      if (widget.selectionMode == DiscoveryFilterSelectionMode.single) {
        selected
          ..clear()
          ..add(toggledIdentity);
      } else {
        selected.add(toggledIdentity);
      }
    }
    _pendingSuppressionSelection = <String>[
      for (final item in widget.children)
        if (selected.contains(item.identity)) item.identity,
    ];
  }
}

class _HorizontalRevealRowItem {
  const _HorizontalRevealRowItem({required this.identity, required this.child});

  final String identity;
  final Widget child;
}

class _RowInteractionScope extends InheritedWidget {
  const _RowInteractionScope({
    required this.markUserInteraction,
    required super.child,
  });

  final ValueChanged<String> markUserInteraction;

  static _RowInteractionScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RowInteractionScope>();

  @override
  bool updateShouldNotify(covariant _RowInteractionScope oldWidget) => false;
}

void _revealHorizontallyIfNeeded(BuildContext context) {
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) {
    return;
  }

  final targetBox = context.findRenderObject();
  final viewportBox = scrollable.context.findRenderObject();
  if (targetBox is! RenderBox || viewportBox is! RenderBox) {
    return;
  }

  final targetOffset = targetBox.localToGlobal(
    Offset.zero,
    ancestor: viewportBox,
  );
  final targetRect = targetOffset & targetBox.size;
  final viewportWidth = viewportBox.size.width;
  const edgePadding = 8.0;

  double scrollDelta = 0;
  if (targetRect.left < edgePadding) {
    scrollDelta = targetRect.left - edgePadding;
  } else if (targetRect.right > viewportWidth - edgePadding) {
    scrollDelta = targetRect.right - viewportWidth + edgePadding;
  }

  if (scrollDelta == 0) {
    return;
  }

  final position = scrollable.position;
  final targetPixels = (position.pixels + scrollDelta)
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();
  if ((targetPixels - position.pixels).abs() < 0.5) {
    return;
  }

  unawaited(position.animateTo(
    targetPixels,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
  ));
}

class _TaxonomyGroupBlock extends StatelessWidget {
  const _TaxonomyGroupBlock({
    super.key,
    required this.group,
    required this.selection,
    required this.fallbackPolicy,
    required this.isLoading,
    required this.autoRevealSelectedChips,
    required this.onToggle,
  });

  final _ResolvedTaxonomyGroup group;
  final DiscoveryFilterSelection selection;
  final DiscoveryFilterPolicy fallbackPolicy;
  final bool isLoading;
  final bool autoRevealSelectedChips;
  final void Function(
    _ResolvedTaxonomyGroup group,
    DiscoveryFilterTaxonomyTermOption term,
  ) onToggle;

  @override
  Widget build(BuildContext context) {
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
          _buildWrappedTerms()
        else
          SizedBox(
            height: 40,
            child: _HorizontalRevealRow(
              key: ValueKey<String>(
                'discoveryFilterTaxonomyList_${group.option.key}',
              ),
              anchorId:
                  autoRevealSelectedChips ? _firstSelectedTermIdentity() : null,
              selectedItemIds: group.option.terms
                  .where(
                    (term) =>
                        selection.taxonomyTermKeys[group.option.key]?.contains(
                          term.value,
                        ) ??
                        false,
                  )
                  .map((term) => '${group.option.key}_${term.value}')
                  .toList(growable: false),
              selectionMode: group.config.selectionMode,
              children: group.option.terms.map((term) {
                final isSelected =
                    selection.taxonomyTermKeys[group.option.key]?.contains(
                          term.value,
                        ) ??
                        false;
                return _HorizontalRevealRowItem(
                  identity: '${group.option.key}_${term.value}',
                  child: _TaxonomyTermChip(
                    key: ValueKey<String>(
                      'discoveryFilterTaxonomyItem_${group.option.key}_${term.value}',
                    ),
                    group: group,
                    term: term,
                    isSelected: isSelected,
                    isLoading: isLoading,
                    onToggle: onToggle,
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  Widget _buildWrappedTerms() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: group.option.terms
          .map(
            (term) => _TaxonomyTermChip(
              group: group,
              term: term,
              isSelected:
                  selection.taxonomyTermKeys[group.option.key]?.contains(
                        term.value,
                      ) ??
                      false,
              isLoading: isLoading,
              onToggle: onToggle,
            ),
          )
          .toList(growable: false),
    );
  }

  String? _firstSelectedTermIdentity() {
    final selected = selection.taxonomyTermKeys[group.option.key];
    if (selected == null) {
      return null;
    }
    for (final term in group.option.terms) {
      if (selected.contains(term.value)) {
        return '${group.option.key}_${term.value}';
      }
    }
    return null;
  }
}

class _TaxonomyTermChip extends StatelessWidget {
  const _TaxonomyTermChip({
    super.key,
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
    const keyPrefix = 'discoveryFilterTaxonomyChip';

    return Semantics(
      key: ValueKey<String>(
        'discoveryFilterTaxonomySemantics_${group.option.key}_${term.value}',
      ),
      container: true,
      button: true,
      focusable: true,
      selected: isSelected,
      toggled: isSelected,
      label: term.label,
      onTap: isLoading ? null : () => _toggleFromRow(context),
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
              onTap: isLoading ? null : () => _toggleFromRow(context),
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

  void _toggleFromRow(BuildContext context) {
    _RowInteractionScope.maybeOf(context)?.markUserInteraction(
      '${group.option.key}_${term.value}',
    );
    onToggle(group, term);
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
