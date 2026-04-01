import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsResendEmailSection extends StatelessWidget {
  const TenantAdminSettingsResendEmailSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.resendEmailTokenController,
        controller.resendEmailFromController,
        controller.resendEmailToController,
        controller.resendEmailCcController,
        controller.resendEmailBccController,
        controller.resendEmailReplyToController,
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

  String _displayValue(TextEditingController controller) {
    final normalized = controller.text.trim();
    return normalized.isEmpty ? '-' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.resendEmailSubmittingStreamValue,
      builder: (context, isSaving) {
        return AnimatedBuilder(
          animation: _controllersListenable(),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsResendTokenEdit,
                label: 'API Token',
                value: _displayValue(controller.resendEmailTokenController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController:
                              controller.resendEmailTokenController,
                          title: 'Editar API Token',
                          label: 'API Token',
                          validator: (value) {
                            if ((value?.trim() ?? '').isEmpty) {
                              return 'API Token obrigatório.';
                            }
                            return null;
                          },
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key:
                    TenantAdminSettingsKeys.technicalIntegrationsResendFromEdit,
                label: 'From',
                value: _displayValue(controller.resendEmailFromController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController: controller.resendEmailFromController,
                          title: 'Editar remetente',
                          label: 'From',
                          helperText:
                              'Use "Nome <email@dominio.com>" ou apenas "email@dominio.com".',
                          validator: (value) {
                            if ((value?.trim() ?? '').isEmpty) {
                              return 'From obrigatório.';
                            }
                            return null;
                          },
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys.technicalIntegrationsResendToEdit,
                label: 'To',
                value: _displayValue(controller.resendEmailToController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController: controller.resendEmailToController,
                          title: 'Editar destinatários principais',
                          label: 'To',
                          helperText:
                              'Separe por vírgula, ponto e vírgula ou quebra de linha.',
                          validator: (value) {
                            if ((value?.trim() ?? '').isEmpty) {
                              return 'To obrigatório.';
                            }
                            return null;
                          },
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys.technicalIntegrationsResendCcEdit,
                label: 'Cc',
                value: _displayValue(controller.resendEmailCcController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController: controller.resendEmailCcController,
                          title: 'Editar destinatários em cópia',
                          label: 'Cc',
                          helperText:
                              'Opcional. Separe por vírgula, ponto e vírgula ou quebra de linha.',
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys.technicalIntegrationsResendBccEdit,
                label: 'Bcc',
                value: _displayValue(controller.resendEmailBccController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController: controller.resendEmailBccController,
                          title: 'Editar destinatários em cópia oculta',
                          label: 'Bcc',
                          helperText:
                              'Opcional. Separe por vírgula, ponto e vírgula ou quebra de linha.',
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsResendReplyToEdit,
                label: 'Reply-To',
                value: _displayValue(controller.resendEmailReplyToController),
                onEdit: isSaving
                    ? null
                    : () => _editTextField(
                          context: context,
                          fieldController:
                              controller.resendEmailReplyToController,
                          title: 'Editar reply-to',
                          label: 'Reply-To',
                          helperText:
                              'Opcional. Separe por vírgula, ponto e vírgula ou quebra de linha.',
                        ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: TenantAdminSettingsKeys.technicalIntegrationsSaveResend,
                onPressed: isSaving ? null : controller.saveResendEmailSettings,
                icon: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar Resend'),
              ),
            ],
          ),
        );
      },
    );
  }
}
