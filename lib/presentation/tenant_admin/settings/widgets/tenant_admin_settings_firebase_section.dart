import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsFirebaseSection extends StatelessWidget {
  const TenantAdminSettingsFirebaseSection({
    super.key,
    required this.controller,
  });

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
              TenantAdminSettingsEditableValueRow(
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
              TenantAdminSettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_firebase_app_id_edit',
                ),
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
              TenantAdminSettingsEditableValueRow(
                key: const ValueKey(
                  'tenant_admin_settings_firebase_api_key_edit',
                ),
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
              TenantAdminSettingsEditableValueRow(
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
              TenantAdminSettingsEditableValueRow(
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
              const SizedBox(height: 10),
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
