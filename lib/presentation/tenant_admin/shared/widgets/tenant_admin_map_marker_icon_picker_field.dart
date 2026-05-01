import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_marker_icon_resolver.dart';
import 'package:flutter/material.dart';

class TenantAdminMapMarkerIconPickerField extends StatelessWidget {
  const TenantAdminMapMarkerIconPickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) {
      return;
    }
    final selected = MapMarkerIconToken.fromStorage(controller.text);
    final picked = await showModalBottomSheet<MapMarkerIconToken>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TenantAdminMapMarkerIconPickerSheet(
        selected: selected,
      ),
    );
    if (picked == null) {
      return;
    }
    controller.text = picked.storageKey;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final selected = MapMarkerIconToken.fromStorage(value.text);
        final resolvedIcon = selected?.iconData ??
            MapMarkerIconResolver.resolve(
                value.text.isEmpty ? null : value.text);
        final selectedLabel = selected?.label ?? 'Selecionar ícone';

        return InkWell(
          onTap: enabled ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: labelText,
              enabled: enabled,
              suffixIcon: IconButton(
                tooltip: 'Selecionar ícone',
                onPressed: enabled ? () => _openPicker(context) : null,
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  resolvedIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TenantAdminMapMarkerIconPickerSheet extends StatelessWidget {
  const _TenantAdminMapMarkerIconPickerSheet({
    required this.selected,
  });

  final MapMarkerIconToken? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecionar ícone',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...MapMarkerIconGroup.values.map((group) {
                final items = MapMarkerIconToken.byGroup(group);
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((item) {
                          final isSelected = item == selected;
                          final colorScheme = Theme.of(context).colorScheme;
                          final foregroundColor = isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant;
                          return FilterChip(
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(color: foregroundColor),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.iconData,
                                  size: 16,
                                  color: foregroundColor,
                                ),
                                const SizedBox(width: 6),
                                Text(item.label),
                              ],
                            ),
                            onSelected: (_) => context.router.pop(item),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.router.maybePop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
