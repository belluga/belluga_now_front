import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsScreen extends StatefulWidget {
  const TenantAdminSettingsScreen({super.key});

  @override
  State<TenantAdminSettingsScreen> createState() =>
      _TenantAdminSettingsScreenState();
}

class _TenantAdminSettingsScreenState extends State<TenantAdminSettingsScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final appData = _controller.appData;
    final theme = Theme.of(context);
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
        _buildLocalPreferencesCard(context),
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
                  value:
                      appData.domains.map((item) => item.value.host).join(', '),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildRemoteSettingsCard(context),
      ],
    );
  }

  Widget _buildLocalPreferencesCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
    );
  }

  Widget _buildRemoteSettingsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações remotas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Endpoints admin do tenant para firebase, push e telemetry.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _RemoteStatusPanel(controller: _controller),
            const SizedBox(height: 12),
            _FirebaseSettingsSection(controller: _controller),
            const Divider(height: 32),
            _PushSettingsSection(controller: _controller),
            const Divider(height: 32),
            _TelemetrySettingsSection(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _RemoteStatusPanel extends StatelessWidget {
  const _RemoteStatusPanel({required this.controller});

  final TenantAdminSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<String?>(
      streamValue: controller.remoteErrorStreamValue,
      builder: (context, errorMessage) {
        return StreamValueBuilder<String?>(
          streamValue: controller.remoteSuccessStreamValue,
          builder: (context, successMessage) {
            return StreamValueBuilder<bool>(
              streamValue: controller.isRemoteLoadingStreamValue,
              builder: (context, isRemoteLoading) {
                if (!isRemoteLoading &&
                    (errorMessage == null || errorMessage.isEmpty) &&
                    (successMessage == null || successMessage.isEmpty)) {
                  return const SizedBox.shrink();
                }
                final hasError =
                    errorMessage != null && errorMessage.isNotEmpty;
                final message = hasError ? errorMessage : successMessage ?? '';
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: hasError
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRemoteLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasError
                                  ? scheme.onErrorContainer
                                  : scheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: isRemoteLoading
                                ? null
                                : controller.loadRemoteSettings,
                            child: const Text('Recarregar'),
                          ),
                          if ((hasError || successMessage != null) &&
                              !isRemoteLoading)
                            TextButton(
                              onPressed: controller.clearStatusMessages,
                              child: const Text('Fechar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FirebaseSettingsSection extends StatelessWidget {
  const _FirebaseSettingsSection({required this.controller});

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.firebaseProjectIdController,
        controller.firebaseAppIdController,
        controller.firebaseApiKeyController,
        controller.firebaseMessagingSenderIdController,
        controller.firebaseStorageBucketController,
      ],
    );
  }

  Future<void> _editRequiredField({
    required BuildContext context,
    required TextEditingController fieldController,
    required String title,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: label,
      initialValue: fieldController.text,
      confirmLabel: 'Aplicar',
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return '$label obrigatorio.';
        }
        return null;
      },
    );
    if (result == null) {
      return;
    }
    final next = result.value.trim();
    if (next == fieldController.text.trim()) {
      return;
    }
    fieldController.text = next;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.firebaseSubmittingStreamValue,
      builder: (context, isSaving) {
        return AnimatedBuilder(
          animation: _controllersListenable(),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _SettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_firebase_project_id_edit',
                ),
                label: 'Project ID',
                value: controller.firebaseProjectIdController.text,
                onEdit: isSaving
                    ? null
                    : () => _editRequiredField(
                          context: context,
                          fieldController:
                              controller.firebaseProjectIdController,
                          title: 'Editar Project ID',
                          label: 'Project ID',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                    'tenant_admin_settings_firebase_app_id_edit'),
                label: 'App ID',
                value: controller.firebaseAppIdController.text,
                onEdit: isSaving
                    ? null
                    : () => _editRequiredField(
                          context: context,
                          fieldController: controller.firebaseAppIdController,
                          title: 'Editar App ID',
                          label: 'App ID',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                    'tenant_admin_settings_firebase_api_key_edit'),
                label: 'API Key',
                value: controller.firebaseApiKeyController.text,
                onEdit: isSaving
                    ? null
                    : () => _editRequiredField(
                          context: context,
                          fieldController: controller.firebaseApiKeyController,
                          title: 'Editar API Key',
                          label: 'API Key',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_firebase_sender_id_edit',
                ),
                label: 'Messaging Sender ID',
                value: controller.firebaseMessagingSenderIdController.text,
                onEdit: isSaving
                    ? null
                    : () => _editRequiredField(
                          context: context,
                          fieldController:
                              controller.firebaseMessagingSenderIdController,
                          title: 'Editar Messaging Sender ID',
                          label: 'Messaging Sender ID',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_firebase_storage_bucket_edit',
                ),
                label: 'Storage Bucket',
                value: controller.firebaseStorageBucketController.text,
                onEdit: isSaving
                    ? null
                    : () => _editRequiredField(
                          context: context,
                          fieldController:
                              controller.firebaseStorageBucketController,
                          title: 'Editar Storage Bucket',
                          label: 'Storage Bucket',
                        ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('tenant_admin_settings_save_firebase'),
                onPressed: isSaving ? null : controller.saveFirebaseSettings,
                icon: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar Firebase'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PushSettingsSection extends StatelessWidget {
  const _PushSettingsSection({required this.controller});

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.pushMaxTtlDaysController,
        controller.pushMaxPerMinuteController,
        controller.pushMaxPerHourController,
      ],
    );
  }

  Future<void> _editPositiveIntField({
    required BuildContext context,
    required TextEditingController fieldController,
    required String title,
    required String label,
  }) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: label,
      initialValue: fieldController.text,
      confirmLabel: 'Aplicar',
      keyboardType: TextInputType.number,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        final parsed = int.tryParse(trimmed);
        if (parsed == null || parsed <= 0) {
          return 'Informe um numero positivo.';
        }
        return null;
      },
    );
    if (result == null) {
      return;
    }
    final next = result.value.trim();
    if (next == fieldController.text.trim()) {
      return;
    }
    fieldController.text = next;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.pushSubmittingStreamValue,
      builder: (context, isSaving) {
        return AnimatedBuilder(
          animation: _controllersListenable(),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Push',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _SettingsEditableValueRow(
                key: const ValueKey('tenant_admin_settings_push_ttl_edit'),
                label: 'Max TTL (dias)',
                value: controller.pushMaxTtlDaysController.text,
                onEdit: isSaving
                    ? null
                    : () => _editPositiveIntField(
                          context: context,
                          fieldController: controller.pushMaxTtlDaysController,
                          title: 'Editar Max TTL',
                          label: 'Max TTL (dias)',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_push_max_per_minute_edit',
                ),
                label: 'Maximo por minuto',
                value: controller.pushMaxPerMinuteController.text,
                onEdit: isSaving
                    ? null
                    : () => _editPositiveIntField(
                          context: context,
                          fieldController:
                              controller.pushMaxPerMinuteController,
                          title: 'Editar maximo por minuto',
                          label: 'Maximo por minuto',
                        ),
              ),
              _SettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_push_max_per_hour_edit',
                ),
                label: 'Maximo por hora',
                value: controller.pushMaxPerHourController.text,
                onEdit: isSaving
                    ? null
                    : () => _editPositiveIntField(
                          context: context,
                          fieldController: controller.pushMaxPerHourController,
                          title: 'Editar maximo por hora',
                          label: 'Maximo por hora',
                        ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: isSaving ? null : controller.savePushSettings,
                icon: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar Push'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TelemetrySettingsSection extends StatelessWidget {
  const _TelemetrySettingsSection({required this.controller});

  final TenantAdminSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminTelemetrySettingsSnapshot>(
      streamValue: controller.telemetrySnapshotStreamValue,
      builder: (context, snapshot) {
        return StreamValueBuilder<String>(
          streamValue: controller.selectedTelemetryTypeStreamValue,
          builder: (context, selectedType) {
            return StreamValueBuilder<bool>(
              streamValue: controller.telemetryTrackAllStreamValue,
              builder: (context, trackAll) {
                return StreamValueBuilder<bool>(
                  streamValue: controller.telemetrySubmittingStreamValue,
                  builder: (context, isSaving) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Telemetry',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.availableEvents.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: snapshot.availableEvents
                                .map((event) => Chip(label: Text(event)))
                                .toList(growable: false),
                          ),
                        if (snapshot.availableEvents.isNotEmpty)
                          const SizedBox(height: 8),
                        if (snapshot.integrations.isEmpty)
                          Text(
                            'Nenhuma integração cadastrada.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          ...snapshot.integrations.map(
                            (integration) => Card(
                              child: ListTile(
                                title: Text(integration.type),
                                subtitle: Text(
                                  integration.trackAll
                                      ? 'track_all=true'
                                      : integration.events.join(', '),
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: isSaving
                                          ? null
                                          : () =>
                                              controller.prefillTelemetryForm(
                                                integration,
                                              ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Excluir',
                                      onPressed: isSaving
                                          ? null
                                          : () => controller
                                                  .deleteTelemetryIntegration(
                                                integration.type,
                                              ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                              'tenant_admin_settings_type_$selectedType'),
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: TenantAdminSettingsController.telemetryTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    controller.selectTelemetryType(value);
                                  }
                                },
                        ),
                        SwitchListTile.adaptive(
                          value: trackAll,
                          onChanged: isSaving
                              ? null
                              : controller.updateTelemetryTrackAll,
                          title: const Text('Track all'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (!trackAll) ...[
                          TextField(
                            controller: controller.telemetryEventsController,
                            decoration: const InputDecoration(
                              labelText: 'Eventos (separados por vírgula)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: controller.telemetryTokenController,
                          decoration: const InputDecoration(
                            labelText: 'Token (opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.telemetryUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL webhook (opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : controller.saveTelemetryIntegration,
                              icon: isSaving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Salvar integração'),
                            ),
                            OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : controller.clearTelemetryForm,
                              child: const Text('Limpar formulário'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
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

class _SettingsEditableValueRow extends StatelessWidget {
  const _SettingsEditableValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Editar $label',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}
