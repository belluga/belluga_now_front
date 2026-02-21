import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_snapshot_row.dart';
import 'package:flutter/material.dart';

class TenantAdminSettingsEnvironmentSnapshotSection extends StatelessWidget {
  const TenantAdminSettingsEnvironmentSnapshotSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final appData = controller.appData;
    final brightnessLabel =
        appData.themeDataSettings.brightnessDefault == Brightness.dark
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

    return Column(
      children: [
        TenantAdminSettingsSnapshotRow(
          label: 'Nome',
          value: appData.nameValue.value,
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Tipo',
          value: envTypeLabel,
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Hostname',
          value: appData.hostname,
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Main domain',
          value: appData.mainDomainValue.value.toString(),
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Domínios',
          value: appData.domains.map((item) => item.value.host).join(', '),
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'App domains',
          value: (appData.appDomains ?? const [])
              .map((item) => item.value)
              .join(', '),
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Theme default',
          value: brightnessLabel,
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Push habilitado',
          value: pushSettings?.enabled == true ? 'Sim' : 'Não',
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Tipos de push',
          value: pushSettings == null || pushSettings.types.isEmpty
              ? '-'
              : pushSettings.types.join(', '),
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Firebase project',
          value: firebaseSettings?.projectId ?? '-',
        ),
        TenantAdminSettingsSnapshotRow(
          label: 'Telemetry trackers',
          value: '$trackerCount',
        ),
      ],
    );
  }
}
