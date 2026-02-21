import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsLocalPreferencesSection extends StatelessWidget {
  const TenantAdminSettingsLocalPreferencesSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

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
      ],
    );
  }
}
