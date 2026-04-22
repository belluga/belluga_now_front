import 'dart:async';

import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/controllers/tenant_admin_discovery_filters_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filters_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/tenant_admin_discovery_filters_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/widgets/tenant_admin_discovery_filter_rule_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_visual_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminDiscoveryFilterSurfaceScreen extends StatefulWidget {
  const TenantAdminDiscoveryFilterSurfaceScreen({
    super.key,
    required this.surface,
  });

  final TenantAdminDiscoveryFilterSurfaceDefinition surface;

  @override
  State<TenantAdminDiscoveryFilterSurfaceScreen> createState() =>
      _TenantAdminDiscoveryFilterSurfaceScreenState();
}

class _TenantAdminDiscoveryFilterSurfaceScreenState
    extends State<TenantAdminDiscoveryFilterSurfaceScreen> {
  final TenantAdminDiscoveryFiltersController _controller =
      GetIt.I.get<TenantAdminDiscoveryFiltersController>();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.init());
  }

  Future<void> _editKey(int index) async {
    final current =
        _controller.filtersForSurface(widget.surface).elementAt(index);
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar chave do filtro',
      label: 'Chave',
      initialValue: current.key,
      confirmLabel: 'Salvar',
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Informe a chave do filtro.';
        }
        return null;
      },
    );
    if (result == null) {
      return;
    }
    _controller.updateFilterKey(widget.surface, index, result.value);
  }

  Future<void> _editLabel(int index) async {
    final current =
        _controller.filtersForSurface(widget.surface).elementAt(index);
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar rótulo do filtro',
      label: 'Rótulo',
      initialValue: current.label,
      confirmLabel: 'Salvar',
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Informe o rótulo do filtro.';
        }
        return null;
      },
    );
    if (result == null) {
      return;
    }
    _controller.updateFilterLabel(widget.surface, index, result.value);
  }

  Future<void> _editRule(int index) async {
    await _controller.loadRuleCatalog();
    if (!mounted) {
      return;
    }
    final catalog = _controller.ruleCatalogStreamValue.value;
    if (catalog.isEmpty) {
      _controller.remoteErrorStreamValue.addValue(
        'Catálogo de tipos/taxonomias indisponível.',
      );
      return;
    }
    final current =
        _controller.filtersForSurface(widget.surface).elementAt(index);
    final result = await showTenantAdminDiscoveryFilterRuleSheet(
      context: context,
      filter: current,
      surface: widget.surface,
      catalog: catalog,
    );
    if (result == null) {
      return;
    }
    _controller.updateFilterRule(widget.surface, index, result);
  }

  Future<void> _editVisual(int index) async {
    final current =
        _controller.filtersForSurface(widget.surface).elementAt(index);
    final result = await showTenantAdminMapFilterVisualSheet(
      context: context,
      filter: _toMapFilterItem(current),
    );
    if (result == null) {
      return;
    }
    _controller.updateFilterVisual(
      widget.surface,
      index,
      current.copyWith(
        imageUriValue: result.imageUri == null
            ? null
            : (TenantAdminOptionalUrlValue()..parse(result.imageUri)),
        clearImageUriValue: TenantAdminFlagValue(result.imageUri == null),
        overrideMarkerValue: TenantAdminFlagValue(result.overrideMarker),
        markerOverride: result.markerOverride,
        clearMarkerOverrideValue: TenantAdminFlagValue(!result.overrideMarker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildTenantAdminCurrentRouteBackPolicy(
      context,
      fallbackRoute: const TenantAdminDiscoveryFiltersRoute(),
    );
    return ListView(
      key: TenantAdminDiscoveryFiltersKeys.surfaceScreen(widget.surface.key),
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          title: widget.surface.title,
          onBack: backPolicy.handleBack,
        ),
        const SizedBox(height: 12),
        StreamValueBuilder<String>(
          streamValue: _controller.remoteErrorStreamValue,
          builder: (context, error) {
            if (error.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusBanner(
                message: error,
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.errorContainer,
              ),
            );
          },
        ),
        StreamValueBuilder<String>(
          streamValue: _controller.remoteSuccessStreamValue,
          builder: (context, success) {
            if (success.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusBanner(
                message: success,
                icon: Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
            );
          },
        ),
        TenantAdminSettingsSection(
          title: widget.surface.title,
          description: widget.surface.description,
          icon: Icons.filter_alt_outlined,
          child: _SurfaceFiltersEditor(
            controller: _controller,
            surface: widget.surface,
            onAddFilter: () => _controller.addFilterItem(widget.surface),
            onEditKey: _editKey,
            onEditLabel: _editLabel,
            onEditRule: _editRule,
            onEditVisual: _editVisual,
          ),
        ),
      ],
    );
  }

  TenantAdminMapFilterCatalogItem _toMapFilterItem(
    TenantAdminDiscoveryFilterCatalogItem item,
  ) {
    return TenantAdminMapFilterCatalogItem(
      keyValue: TenantAdminLowercaseTokenValue.fromRaw(item.key),
      labelValue: TenantAdminRequiredTextValue()..parse(item.label),
      imageUriValue: item.imageUri == null
          ? null
          : (TenantAdminOptionalUrlValue()..parse(item.imageUri)),
      overrideMarkerValue: TenantAdminFlagValue(item.overrideMarker),
      markerOverride: item.markerOverride,
    );
  }
}

class _SurfaceFiltersEditor extends StatelessWidget {
  const _SurfaceFiltersEditor({
    required this.controller,
    required this.surface,
    required this.onAddFilter,
    required this.onEditKey,
    required this.onEditLabel,
    required this.onEditRule,
    required this.onEditVisual,
  });

  final TenantAdminDiscoveryFiltersController controller;
  final TenantAdminDiscoveryFilterSurfaceDefinition surface;
  final VoidCallback onAddFilter;
  final ValueChanged<int> onEditKey;
  final ValueChanged<int> onEditLabel;
  final ValueChanged<int> onEditRule;
  final ValueChanged<int> onEditVisual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<TenantAdminDiscoveryFiltersSettings>(
      streamValue: controller.settingsStreamValue,
      builder: (context, _) {
        final filters = controller.filtersForSurface(surface);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros configurados',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  key: TenantAdminDiscoveryFiltersKeys.addFilterButton,
                  onPressed: onAddFilter,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'A ordem da lista define a ordem de exibição pública.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (filters.isEmpty)
              Text(
                'Nenhum filtro configurado.',
                style: theme.textTheme.bodyMedium,
              ),
            ...List.generate(
              filters.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == filters.length - 1 ? 0 : 12,
                ),
                child: _SurfaceFilterRow(
                  surface: surface,
                  index: index,
                  item: filters.elementAt(index),
                  hasPrevious: index > 0,
                  hasNext: index < filters.length - 1,
                  onEditKey: () => onEditKey(index),
                  onEditLabel: () => onEditLabel(index),
                  onEditRule: () => onEditRule(index),
                  onEditVisual: () => onEditVisual(index),
                  onRemove: () => controller.removeFilterItem(surface, index),
                  onMoveUp: () => controller.moveFilterItemUp(surface, index),
                  onMoveDown: () =>
                      controller.moveFilterItemDown(surface, index),
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<bool>(
              streamValue: controller.isSubmittingStreamValue,
              builder: (context, isSubmitting) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: TenantAdminDiscoveryFiltersKeys.saveFiltersButton,
                    onPressed: isSubmitting
                        ? null
                        : () => controller.saveFilters(surface),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salvar filtros'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SurfaceFilterRow extends StatelessWidget {
  const _SurfaceFilterRow({
    required this.surface,
    required this.index,
    required this.item,
    required this.hasPrevious,
    required this.hasNext,
    required this.onEditKey,
    required this.onEditLabel,
    required this.onEditRule,
    required this.onEditVisual,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final TenantAdminDiscoveryFilterSurfaceDefinition surface;
  final int index;
  final TenantAdminDiscoveryFilterCatalogItem item;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onEditKey;
  final VoidCallback onEditLabel;
  final VoidCallback onEditRule;
  final VoidCallback onEditVisual;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _resolveVisual(item);
    final visualBackgroundColor = switch (visual.kind) {
      _RowVisualKind.icon =>
        (MapMarkerVisualResolver.tryParseHexColor(visual.color) ??
                theme.colorScheme.surfaceContainerHighest)
            .withValues(alpha: 0.22),
      _ => theme.colorScheme.surfaceContainerHighest,
    };

    return Container(
      key: TenantAdminDiscoveryFiltersKeys.filterRow(surface.key, index),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  key: TenantAdminDiscoveryFiltersKeys.filterVisualPreview(
                    surface.key,
                    index,
                  ),
                  width: 56,
                  height: 56,
                  color: visualBackgroundColor,
                  child: switch (visual.kind) {
                    _RowVisualKind.image => KeyedSubtree(
                        key: ValueKey<String>(visual.imageUri!),
                        child: BellugaNetworkImage(
                          visual.imageUri!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    _RowVisualKind.icon => Icon(
                        MapMarkerVisualResolver.resolveIcon(visual.icon),
                        color: MapMarkerVisualResolver.tryParseHexColor(
                              visual.iconColor,
                            ) ??
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    _RowVisualKind.fallback => Icon(
                        Icons.filter_alt_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      item.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ruleSummary(item),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEditKey,
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Chave'),
              ),
              OutlinedButton.icon(
                onPressed: onEditLabel,
                icon: const Icon(Icons.label_outline),
                label: const Text('Rótulo'),
              ),
              OutlinedButton.icon(
                key: TenantAdminDiscoveryFiltersKeys.filterRuleButton(
                  surface.key,
                  index,
                ),
                onPressed: onEditRule,
                icon: const Icon(Icons.rule_outlined),
                label: const Text('Regra'),
              ),
              OutlinedButton.icon(
                key: TenantAdminDiscoveryFiltersKeys.filterVisualButton(
                  surface.key,
                  index,
                ),
                onPressed: onEditVisual,
                icon: const Icon(Icons.palette_outlined),
                label: Text(surface.supportsMarkerOverride
                    ? 'Visual/Marcador'
                    : 'Visual'),
              ),
              OutlinedButton.icon(
                onPressed: hasPrevious ? onMoveUp : null,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Subir'),
              ),
              OutlinedButton.icon(
                onPressed: hasNext ? onMoveDown : null,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Descer'),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ruleSummary(TenantAdminDiscoveryFilterCatalogItem item) {
    final entities = item.query.entities;
    final typeCount = item.query.typeValuesByEntity.values
        .fold<int>(0, (total, values) => total + values.length);
    final taxonomyCount = item.query.taxonomyValuesByGroup.values
        .fold<int>(0, (total, values) => total + values.length);
    final marker = surface.supportsMarkerOverride &&
            item.overrideMarker &&
            item.markerOverride != null
        ? item.markerOverride!.mode.label
        : 'sem override';
    return 'entidades: ${entities.length} · tipos: $typeCount · taxonomias: $taxonomyCount · marcador: $marker';
  }

  _RowVisual _resolveVisual(TenantAdminDiscoveryFilterCatalogItem item) {
    final markerOverride = item.markerOverride;
    if (surface.supportsMarkerOverride &&
        item.overrideMarker &&
        markerOverride?.isValid == true) {
      if (markerOverride!.mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
        return _RowVisual.icon(
          icon: markerOverride.icon ?? '',
          color: markerOverride.color,
          iconColor: markerOverride.iconColor,
        );
      }
      final imageUri = markerOverride.imageUri?.trim();
      if (imageUri != null && imageUri.isNotEmpty) {
        return _RowVisual.image(imageUri: imageUri);
      }
      return const _RowVisual.fallback();
    }

    final imageUri = item.imageUri?.trim();
    if (imageUri != null && imageUri.isNotEmpty) {
      return _RowVisual.image(imageUri: imageUri);
    }
    return const _RowVisual.fallback();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

enum _RowVisualKind {
  icon,
  image,
  fallback,
}

class _RowVisual {
  const _RowVisual.icon({
    required this.icon,
    required this.color,
    required this.iconColor,
  })  : kind = _RowVisualKind.icon,
        imageUri = null;

  const _RowVisual.image({
    required this.imageUri,
  })  : kind = _RowVisualKind.image,
        icon = null,
        color = null,
        iconColor = null;

  const _RowVisual.fallback()
      : kind = _RowVisualKind.fallback,
        icon = null,
        color = null,
        iconColor = null,
        imageUri = null;

  final _RowVisualKind kind;
  final String? icon;
  final String? color;
  final String? iconColor;
  final String? imageUri;
}
