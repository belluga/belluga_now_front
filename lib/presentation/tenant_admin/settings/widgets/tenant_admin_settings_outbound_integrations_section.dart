import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsOutboundIntegrationsSection extends StatelessWidget {
  const TenantAdminSettingsOutboundIntegrationsSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.outboundWhatsappWebhookUrlController,
        controller.outboundOtpWebhookUrlController,
        controller.outboundOtpTtlMinutesController,
        controller.outboundOtpResendCooldownSecondsController,
        controller.outboundOtpMaxAttemptsController,
      ],
    );
  }

  Future<void> _editField({
    required BuildContext context,
    required TextEditingController fieldController,
    required String title,
    required String label,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: label,
      initialValue: fieldController.text,
      helperText: helperText,
      confirmLabel: 'Aplicar',
      keyboardType: keyboardType,
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

  String? _optionalUrlValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return 'Informe uma URL completa.';
    }
    return null;
  }

  String? _boundedIntValidator({
    required String? value,
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < min || parsed > max) {
      return 'Informe um valor entre $min e $max.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.outboundIntegrationsSubmittingStreamValue,
      builder: (context, isSaving) {
        return AnimatedBuilder(
          animation: _controllersListenable(),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsOutboundWhatsappWebhookEdit,
                label: 'Webhook WhatsApp',
                value: _displayValue(
                  controller.outboundWhatsappWebhookUrlController,
                ),
                onEdit: isSaving
                    ? null
                    : () => _editField(
                          context: context,
                          fieldController:
                              controller.outboundWhatsappWebhookUrlController,
                          title: 'Editar webhook WhatsApp',
                          label: 'Webhook WhatsApp',
                          helperText: 'https://...',
                          keyboardType: TextInputType.url,
                          validator: _optionalUrlValidator,
                        ),
              ),
              StreamValueBuilder<bool>(
                streamValue:
                    controller.outboundOtpSmsSecondaryEnabledStreamValue,
                builder: (context, smsSecondaryEnabled) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        key: TenantAdminSettingsKeys
                            .technicalIntegrationsOutboundOtpSmsSecondarySwitch,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Secondary OTP Channel com SMS'),
                        value: smsSecondaryEnabled,
                        onChanged: isSaving
                            ? null
                            : controller.updateOutboundOtpSmsSecondaryEnabled,
                      ),
                      if (smsSecondaryEnabled)
                        TenantAdminSettingsEditableValueRow(
                          key: TenantAdminSettingsKeys
                              .technicalIntegrationsOutboundOtpSmsUrlEdit,
                          label: 'URL SMS',
                          value: _displayValue(
                            controller.outboundOtpWebhookUrlController,
                          ),
                          onEdit: isSaving
                              ? null
                              : () => _editField(
                                    context: context,
                                    fieldController: controller
                                        .outboundOtpWebhookUrlController,
                                    title: 'Editar URL SMS',
                                    label: 'URL SMS',
                                    helperText: 'https://...',
                                    keyboardType: TextInputType.url,
                                    validator: _optionalUrlValidator,
                                  ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsOutboundOtpTtlEdit,
                label: 'TTL OTP (min)',
                value: controller.outboundOtpTtlMinutesController.text,
                onEdit: isSaving
                    ? null
                    : () => _editField(
                          context: context,
                          fieldController:
                              controller.outboundOtpTtlMinutesController,
                          title: 'Editar TTL OTP',
                          label: 'TTL OTP (min)',
                          keyboardType: TextInputType.number,
                          validator: (value) => _boundedIntValidator(
                            value: value,
                            min: 1,
                            max: 30,
                          ),
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsOutboundOtpCooldownEdit,
                label: 'Cooldown reenvio (s)',
                value:
                    controller.outboundOtpResendCooldownSecondsController.text,
                onEdit: isSaving
                    ? null
                    : () => _editField(
                          context: context,
                          fieldController: controller
                              .outboundOtpResendCooldownSecondsController,
                          title: 'Editar cooldown de reenvio',
                          label: 'Cooldown reenvio (s)',
                          keyboardType: TextInputType.number,
                          validator: (value) => _boundedIntValidator(
                            value: value,
                            min: 15,
                            max: 600,
                          ),
                        ),
              ),
              TenantAdminSettingsEditableValueRow(
                key: TenantAdminSettingsKeys
                    .technicalIntegrationsOutboundOtpMaxAttemptsEdit,
                label: 'Tentativas OTP',
                value: controller.outboundOtpMaxAttemptsController.text,
                onEdit: isSaving
                    ? null
                    : () => _editField(
                          context: context,
                          fieldController:
                              controller.outboundOtpMaxAttemptsController,
                          title: 'Editar tentativas OTP',
                          label: 'Tentativas OTP',
                          keyboardType: TextInputType.number,
                          validator: (value) => _boundedIntValidator(
                            value: value,
                            min: 1,
                            max: 10,
                          ),
                        ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: TenantAdminSettingsKeys.technicalIntegrationsSaveOutbound,
                onPressed: isSaving
                    ? null
                    : controller.saveOutboundIntegrationsSettings,
                icon: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar Webhooks'),
              ),
            ],
          ),
        );
      },
    );
  }
}
