import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsScreen extends StatelessWidget {
  const TenantAdminSettingsScreen({super.key});

  TenantAdminSettingsController get _controller =>
      GetIt.I.get<TenantAdminSettingsController>();

  @override
  Widget build(BuildContext context) {
    final appData = _controller.appData;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightnessLabel = appData.themeDataSettings.brightnessDefault ==
            Brightness.dark
        ? 'Escuro'
        : 'Claro';
    final envType = appData.typeValue.value;
    final envTypeLabel = switch (envType) {
      EnvironmentType.landlord => 'Landlord',
      EnvironmentType.tenant => 'Tenant',
    };
    final pushSettings = appData.pushSettings;
    final firebaseSettings = appData.firebaseSettings;
    final trackerCount = appData.telemetrySettings.trackers.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Configurações',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Ajustes operacionais e snapshot do environment atual.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferências locais',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                StreamValueBuilder<ThemeMode?>(
                  streamValue: _controller.themeModeStreamValue,
                  builder: (context, themeMode) {
                    final selectedThemeMode = themeMode ?? ThemeMode.system;
                    return SegmentedButton<ThemeMode>(
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
                        _controller.updateThemeMode(selection.first);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamValueBuilder<double>(
                  streamValue: _controller.maxRadiusMetersStreamValue,
                  builder: (context, maxRadiusMeters) {
                    final current = maxRadiusMeters.clamp(1000.0, 100000.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raio máximo do mapa: ${current.toStringAsFixed(0)} m',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Slider(
                          min: 1000,
                          max: 100000,
                          divisions: 99,
                          value: current,
                          label: '${current.toStringAsFixed(0)} m',
                          onChanged: _controller.updateMaxRadiusMeters,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snapshot do environment',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _SettingRow(
                  label: 'Nome',
                  value: appData.nameValue.value,
                ),
                _SettingRow(
                  label: 'Tipo',
                  value: envTypeLabel,
                ),
                _SettingRow(
                  label: 'Hostname',
                  value: appData.hostname,
                ),
                _SettingRow(
                  label: 'Main domain',
                  value: appData.mainDomainValue.value.toString(),
                ),
                _SettingRow(
                  label: 'Domínios',
                  value: appData.domains.map((item) => item.value.host).join(', '),
                ),
                _SettingRow(
                  label: 'App domains',
                  value: (appData.appDomains ?? const [])
                      .map((item) => item.value)
                      .join(', '),
                ),
                _SettingRow(
                  label: 'Theme default',
                  value: brightnessLabel,
                ),
                _SettingRow(
                  label: 'Push habilitado',
                  value: pushSettings?.enabled == true ? 'Sim' : 'Não',
                ),
                _SettingRow(
                  label: 'Tipos de push',
                  value: pushSettings == null || pushSettings.types.isEmpty
                      ? '-'
                      : pushSettings.types.join(', '),
                ),
                _SettingRow(
                  label: 'Firebase project',
                  value: firebaseSettings?.projectId ?? '-',
                ),
                _SettingRow(
                  label: 'Telemetry trackers',
                  value: '$trackerCount',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    'Configurações remotas (firebase/push/telemetry) serão '
                    'editáveis na próxima etapa com endpoints dedicados do admin.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
