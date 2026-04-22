import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
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
    this.onAddMapFilter,
    this.onEditMapFilterKey,
    this.onEditMapFilterLabel,
    this.onEditMapFilterRule,
    this.onEditMapFilterVisual,
    this.onRemoveMapFilter,
    this.onMoveMapFilterUp,
    this.onMoveMapFilterDown,
  });

  final TenantAdminSettingsController controller;
  final Future<void> Function() onOpenDefaultOriginPicker;
  final VoidCallback? onAddMapFilter;
  final Future<void> Function(int index)? onEditMapFilterKey;
  final Future<void> Function(int index)? onEditMapFilterLabel;
  final Future<void> Function(int index)? onEditMapFilterRule;
  final Future<void> Function(int index)? onEditMapFilterVisual;
  final void Function(int index)? onRemoveMapFilter;
  final void Function(int index)? onMoveMapFilterUp;
  final void Function(int index)? onMoveMapFilterDown;

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
                    Text('Raio do mapa', style: theme.textTheme.titleMedium),
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
        _DefaultOriginEditor(
          controller: controller,
          onOpenDefaultOriginPicker: onOpenDefaultOriginPicker,
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('Filtros públicos'),
            subtitle: const Text(
              'Os filtros de Mapa, Home e Descoberta agora ficam no menu principal Filtros.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.router.push(const TenantAdminDiscoveryFiltersRoute());
            },
          ),
        ),
      ],
    );
  }
}

class _DefaultOriginEditor extends StatelessWidget {
  const _DefaultOriginEditor({
    required this.controller,
    required this.onOpenDefaultOriginPicker,
  });

  final TenantAdminSettingsController controller;
  final Future<void> Function() onOpenDefaultOriginPicker;

  @override
  Widget build(BuildContext context) {
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
}
