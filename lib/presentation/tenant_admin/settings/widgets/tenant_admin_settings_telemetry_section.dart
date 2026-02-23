import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsTelemetrySection extends StatelessWidget {
  const TenantAdminSettingsTelemetrySection({
    super.key,
    required this.controller,
  });

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
                          ...snapshot.integrations.asMap().entries.map((entry) {
                            final index = entry.key;
                            final integration = entry.value;
                            final isLast =
                                index == snapshot.integrations.length - 1;
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
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
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                              ],
                            );
                          }),
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
