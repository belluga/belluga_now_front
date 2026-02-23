import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsPushSection extends StatelessWidget {
  const TenantAdminSettingsPushSection({
    super.key,
    required this.controller,
  });

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
              TenantAdminSettingsEditableValueRow(
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
              TenantAdminSettingsEditableValueRow(
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
              TenantAdminSettingsEditableValueRow(
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
              const SizedBox(height: 10),
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
