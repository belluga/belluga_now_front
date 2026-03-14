import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsLocalPreferencesSection extends StatelessWidget {
  const TenantAdminSettingsLocalPreferencesSection({
    super.key,
    required this.controller,
    required this.onOpenDefaultOriginPicker,
    required this.onAddMapFilter,
    required this.onEditMapFilterKey,
    required this.onEditMapFilterLabel,
    required this.onEditMapFilterRule,
    required this.onEditMapFilterImage,
    required this.onRemoveMapFilter,
    required this.onMoveMapFilterUp,
    required this.onMoveMapFilterDown,
    required this.onClearMapFilterImage,
    required this.isMapFilterImageBusy,
  });

  final TenantAdminSettingsController controller;
  final Future<void> Function() onOpenDefaultOriginPicker;
  final VoidCallback onAddMapFilter;
  final Future<void> Function(int index) onEditMapFilterKey;
  final Future<void> Function(int index) onEditMapFilterLabel;
  final Future<void> Function(int index) onEditMapFilterRule;
  final Future<void> Function(int index) onEditMapFilterImage;
  final void Function(int index) onRemoveMapFilter;
  final void Function(int index) onMoveMapFilterUp;
  final void Function(int index) onMoveMapFilterDown;
  final void Function(int index) onClearMapFilterImage;
  final bool Function(String filterKey) isMapFilterImageBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamValueBuilder<ThemeMode?>(
          streamValue: controller.themeModeStreamValue,
          builder: (context, themeMode) {
            final selectedThemeMode = themeMode ?? ThemeMode.system;
            return SegmentedButton<ThemeMode>(
              key: const ValueKey('tenant_admin_settings_theme_segmented'),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Escuro'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.phone_android_outlined),
                ),
              ],
              selected: {selectedThemeMode},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                controller.updateThemeMode(selection.first);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        StreamValueBuilder<double>(
          streamValue: controller.maxRadiusMetersStreamValue,
          builder: (context, maxRadiusMeters) {
            final current = maxRadiusMeters.clamp(1000.0, 100000.0);
            final kilometers = (current / 1000).toStringAsFixed(0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Raio do mapa',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '$kilometers km',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 1000,
                  max: 100000,
                  divisions: 99,
                  value: current,
                  label: '${current.toStringAsFixed(0)} m',
                  onChanged: controller.updateMaxRadiusMeters,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _buildDefaultOriginEditor(context),
        const SizedBox(height: 16),
        _buildMapFiltersEditor(context),
      ],
    );
  }

  Widget _buildDefaultOriginEditor(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Origem padrão de localização',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Usada quando a localização do usuário não estiver disponível.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key:
                  TenantAdminSettingsKeys.localPreferencesDefaultOriginLatField,
              controller: controller.mapDefaultOriginLatitudeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: tenantAdminCoordinateInputFormatters,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Ex: -20.673600',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key:
                  TenantAdminSettingsKeys.localPreferencesDefaultOriginLngField,
              controller: controller.mapDefaultOriginLongitudeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: tenantAdminCoordinateInputFormatters,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Ex: -40.497600',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: TenantAdminSettingsKeys
                  .localPreferencesDefaultOriginLabelField,
              controller: controller.mapDefaultOriginLabelController,
              decoration: const InputDecoration(
                labelText: 'Rótulo (opcional)',
                hintText: 'Ex: Centro de Guarapari',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: TenantAdminSettingsKeys.localPreferencesSelectOnMapButton,
              onPressed: onOpenDefaultOriginPicker,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Selecionar no mapa'),
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<bool>(
              streamValue: controller.mapUiSubmittingStreamValue,
              builder: (context, isSubmitting) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: TenantAdminSettingsKeys
                        .localPreferencesSaveOriginButton,
                    onPressed:
                        isSubmitting ? null : controller.saveMapUiSettings,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salvar preferências de mapa'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapFiltersEditor(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<TenantAdminMapUiSettings>(
      streamValue: controller.mapUiSettingsStreamValue,
      builder: (context, settings) {
        final filters = settings.filters;
        return Card(
          key: TenantAdminSettingsKeys.localPreferencesMapFiltersCard,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros do mapa',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      key: TenantAdminSettingsKeys
                          .localPreferencesAddMapFilterButton,
                      onPressed: onAddMapFilter,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'A ordem da lista define a ordem de exibição dos filtros.',
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
                    child: _buildMapFilterRow(
                      context,
                      index: index,
                      item: filters[index],
                      hasPrevious: index > 0,
                      hasNext: index < filters.length - 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamValueBuilder<bool>(
                  streamValue: controller.mapUiSubmittingStreamValue,
                  builder: (context, isSubmitting) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed:
                            isSubmitting ? null : controller.saveMapFilters,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar filtros do mapa'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapFilterRow(
    BuildContext context, {
    required int index,
    required TenantAdminMapFilterCatalogItem item,
    required bool hasPrevious,
    required bool hasNext,
  }) {
    final theme = Theme.of(context);
    final imageBusy = isMapFilterImageBusy(item.key);
    final hasImage = item.imageUri != null && item.imageUri!.trim().isNotEmpty;

    return Container(
      key: TenantAdminSettingsKeys.localPreferencesMapFilterRow(index),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
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
                  width: 56,
                  height: 56,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: hasImage
                      ? BellugaNetworkImage(
                          item.imageUri!,
                          key: ValueKey(item.imageUri),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.filter_alt_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ruleSummary(item.query),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit_key',
                    child: Text('Editar chave'),
                  ),
                  PopupMenuItem(
                    value: 'edit_label',
                    child: Text('Editar rótulo'),
                  ),
                  PopupMenuItem(
                    value: 'edit_rule',
                    child: Text('Editar regra'),
                  ),
                  PopupMenuItem(
                    value: 'edit_image',
                    child: Text('Editar imagem'),
                  ),
                  PopupMenuItem(
                    value: 'clear_image',
                    child: Text('Limpar imagem'),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remover'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit_key':
                      onEditMapFilterKey(index);
                      return;
                    case 'edit_label':
                      onEditMapFilterLabel(index);
                      return;
                    case 'edit_rule':
                      onEditMapFilterRule(index);
                      return;
                    case 'edit_image':
                      onEditMapFilterImage(index);
                      return;
                    case 'clear_image':
                      onClearMapFilterImage(index);
                      return;
                    case 'remove':
                      onRemoveMapFilter(index);
                      return;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onEditMapFilterKey(index),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Chave'),
              ),
              OutlinedButton.icon(
                onPressed: () => onEditMapFilterLabel(index),
                icon: const Icon(Icons.label_outline),
                label: const Text('Rótulo'),
              ),
              OutlinedButton.icon(
                onPressed: () => onEditMapFilterRule(index),
                icon: const Icon(Icons.rule_outlined),
                label: const Text('Regra'),
              ),
              OutlinedButton.icon(
                onPressed: imageBusy ? null : () => onEditMapFilterImage(index),
                icon: imageBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(imageBusy ? 'Enviando...' : 'Imagem'),
              ),
              if (hasImage)
                OutlinedButton.icon(
                  onPressed: () => onClearMapFilterImage(index),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpar imagem'),
                ),
              OutlinedButton.icon(
                onPressed: hasPrevious ? () => onMoveMapFilterUp(index) : null,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Subir'),
              ),
              OutlinedButton.icon(
                onPressed: hasNext ? () => onMoveMapFilterDown(index) : null,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Descer'),
              ),
              TextButton.icon(
                onPressed: () => onRemoveMapFilter(index),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ruleSummary(TenantAdminMapFilterQuery query) {
    final source = query.source?.label ?? 'Origem não definida';
    final typesCount = query.types.length;
    final taxonomyCount = query.taxonomy.length;
    return '$source · tipos: $typesCount · taxonomias: $taxonomyCount';
  }
}
