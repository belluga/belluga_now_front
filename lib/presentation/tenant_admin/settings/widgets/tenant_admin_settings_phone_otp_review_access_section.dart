import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_snapshot_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsPhoneOtpReviewAccessSection extends StatelessWidget {
  const TenantAdminSettingsPhoneOtpReviewAccessSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.phoneOtpReviewAccessPhoneController,
        controller.phoneOtpReviewAccessHelperCodeController,
        controller.phoneOtpReviewAccessCodeHashController,
      ],
    );
  }

  Future<void> _editTextField({
    required BuildContext context,
    required TextEditingController fieldController,
    required String title,
    required String label,
    String? helperText,
    String? Function(String?)? validator,
  }) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: label,
      initialValue: fieldController.text,
      helperText: helperText,
      confirmLabel: 'Aplicar',
      validator: validator,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
    );
    if (result == null) {
      return;
    }
    fieldController.text = result.value.trim();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.phoneOtpReviewAccessSubmittingStreamValue,
      builder: (context, isSaving) {
        return StreamValueBuilder<bool>(
          streamValue: controller.phoneOtpReviewAccessHashGeneratingStreamValue,
          builder: (context, isGeneratingHash) {
            final isBusy = isSaving || isGeneratingHash;
            return AnimatedBuilder(
              animation: _controllersListenable(),
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TenantAdminSettingsEditableValueRow(
                    key: TenantAdminSettingsKeys
                        .technicalIntegrationsPhoneOtpReviewPhoneEdit,
                    label: 'Telefone',
                    value: controller.phoneOtpReviewAccessPhoneController.text,
                    onEdit: isBusy
                        ? null
                        : () => _editTextField(
                              context: context,
                              fieldController: controller
                                  .phoneOtpReviewAccessPhoneController,
                              title: 'Editar telefone de revisão',
                              label: 'Telefone E.164',
                              helperText:
                                  'Use o formato internacional com + e DDI.',
                              validator: (value) {
                                final normalized = value?.trim() ?? '';
                                if (normalized.isEmpty) {
                                  return null;
                                }
                                if (!RegExp(r'^\+[1-9]\d{7,14}$')
                                    .hasMatch(normalized)) {
                                  return 'Use o formato E.164.';
                                }
                                return null;
                              },
                            ),
                  ),
                  TenantAdminSettingsEditableValueRow(
                    key: TenantAdminSettingsKeys
                        .technicalIntegrationsPhoneOtpReviewCodeEdit,
                    label: 'Código helper',
                    value: controller
                        .phoneOtpReviewAccessHelperCodeController.text,
                    onEdit: isBusy
                        ? null
                        : () => _editTextField(
                              context: context,
                              fieldController: controller
                                  .phoneOtpReviewAccessHelperCodeController,
                              title: 'Editar código de revisão',
                              label: 'Código de revisão',
                            ),
                  ),
                  TenantAdminSettingsSnapshotRow(
                    key: TenantAdminSettingsKeys
                        .technicalIntegrationsPhoneOtpReviewCodeHash,
                    label: 'Hash',
                    value:
                        controller.phoneOtpReviewAccessCodeHashController.text,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        key: TenantAdminSettingsKeys
                            .technicalIntegrationsPhoneOtpReviewGenerateHash,
                        onPressed: isBusy
                            ? null
                            : controller.generatePhoneOtpReviewAccessCodeHash,
                        icon: isGeneratingHash
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.password_outlined),
                        label: const Text('Gerar hash'),
                      ),
                      FilledButton.icon(
                        key: TenantAdminSettingsKeys
                            .technicalIntegrationsSavePhoneOtpReviewAccess,
                        onPressed: isBusy
                            ? null
                            : controller.savePhoneOtpReviewAccessSettings,
                        icon: isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar acesso OTP'),
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
  }
}
