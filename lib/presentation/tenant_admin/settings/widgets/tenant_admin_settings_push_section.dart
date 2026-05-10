import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_snapshot_row.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_push_status.dart';
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
        controller.pushCredentialsProjectIdController,
        controller.pushCredentialsClientEmailController,
        controller.pushCredentialsPrivateKeyController,
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

  Future<void> _editRequiredTextField({
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
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator ??
          (value) {
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

  Future<void> _editPrivateKeyField(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _PushSecretEditSheet(
          title: 'Editar private_key',
          label: 'private_key',
          helperText:
              'O backend aceita a chave no save, mas nunca devolve esse valor.',
          initialValue: controller.pushCredentialsPrivateKeyController.text,
        );
      },
    );
    if (result == null) {
      return;
    }
    final next = result.trim();
    if (next == controller.pushCredentialsPrivateKeyController.text.trim()) {
      return;
    }
    controller.pushCredentialsPrivateKeyController.text = next;
  }

  String _pushStatusLabel(TenantAdminPushStatus? status) {
    if (status == null) {
      return 'Carregando';
    }
    final value = status.status;
    switch (value) {
      case 'active':
        return 'Ativo';
      case 'pending_tests':
        return 'Pendente de testes';
      case 'not_configured':
        return 'Nao configurado';
      default:
        return value;
    }
  }

  String _pushEnabledLabel(bool? enabled) {
    if (enabled == null) {
      return 'Indefinido';
    }
    return enabled ? 'Sim' : 'Nao';
  }

  String _pushCredentialsLabel(bool configured) {
    return configured ? 'Configuradas' : 'Nao configuradas';
  }

  String _privateKeySummary(bool configured) {
    final localDraft = controller.pushCredentialsPrivateKeyController.text
        .trim()
        .isNotEmpty;
    if (localDraft) {
      return 'Pronta para salvar';
    }
    if (configured) {
      return 'Oculta por seguranca';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.pushSubmittingStreamValue,
      builder: (context, isSaving) {
        return StreamValueBuilder<bool>(
          streamValue: controller.pushCredentialsSubmittingStreamValue,
          builder: (context, isSavingCredentials) {
            return StreamValueBuilder<bool?>(
              streamValue: controller.pushEnabledStreamValue,
              builder: (context, pushEnabled) {
                return StreamValueBuilder<TenantAdminPushStatus?>(
                  streamValue: controller.pushStatusStreamValue,
                  builder: (context, pushStatus) {
                    return StreamValueBuilder<bool>(
                      streamValue:
                          controller.pushCredentialsConfiguredStreamValue,
                      builder: (context, hasCredentials) {
                        final isBusy = isSaving || isSavingCredentials;
                        return AnimatedBuilder(
                          animation: _controllersListenable(),
                          builder: (context, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TenantAdminSettingsSnapshotRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushStatusRow,
                                label: 'Status',
                                value: _pushStatusLabel(pushStatus),
                              ),
                              TenantAdminSettingsSnapshotRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushEnabledRow,
                                label: 'Push habilitado',
                                value: _pushEnabledLabel(pushEnabled),
                              ),
                              TenantAdminSettingsSnapshotRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushCredentialsRow,
                                label: 'Credenciais FCM',
                                value: _pushCredentialsLabel(hasCredentials),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    key: TenantAdminSettingsKeys
                                        .technicalIntegrationsPushEnable,
                                    onPressed:
                                        isBusy ? null : controller.enablePush,
                                    icon: const Icon(
                                      Icons.notifications_active_outlined,
                                    ),
                                    label: const Text('Habilitar push'),
                                  ),
                                  OutlinedButton.icon(
                                    key: TenantAdminSettingsKeys
                                        .technicalIntegrationsPushDisable,
                                    onPressed:
                                        isBusy ? null : controller.disablePush,
                                    icon: const Icon(
                                      Icons.notifications_off_outlined,
                                    ),
                                    label: const Text('Desabilitar push'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Credenciais FCM',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              TenantAdminSettingsEditableValueRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushCredentialsProjectIdEdit,
                                label: 'Project ID',
                                value: controller
                                    .pushCredentialsProjectIdController.text,
                                onEdit: isBusy
                                    ? null
                                    : () => _editRequiredTextField(
                                          context: context,
                                          fieldController: controller
                                              .pushCredentialsProjectIdController,
                                          title: 'Editar Project ID FCM',
                                          label: 'Project ID',
                                        ),
                              ),
                              TenantAdminSettingsEditableValueRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushCredentialsClientEmailEdit,
                                label: 'Client email',
                                value: controller
                                    .pushCredentialsClientEmailController.text,
                                onEdit: isBusy
                                    ? null
                                    : () => _editRequiredTextField(
                                          context: context,
                                          fieldController: controller
                                              .pushCredentialsClientEmailController,
                                          title: 'Editar client_email FCM',
                                          label: 'Client email',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            final trimmed =
                                                value?.trim() ?? '';
                                            if (trimmed.isEmpty) {
                                              return
                                                  'Client email obrigatorio.';
                                            }
                                            if (!trimmed.contains('@')) {
                                              return
                                                  'Informe um email valido.';
                                            }
                                            return null;
                                          },
                                        ),
                              ),
                              TenantAdminSettingsEditableValueRow(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsPushCredentialsPrivateKeyEdit,
                                label: 'Private key',
                                value: _privateKeySummary(hasCredentials),
                                onEdit: isBusy
                                    ? null
                                    : () => _editPrivateKeyField(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A private_key nunca volta do backend. Informe novamente esse campo sempre que atualizar as credenciais.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsSavePushCredentials,
                                onPressed: isBusy
                                    ? null
                                    : controller.savePushCredentials,
                                icon: isSavingCredentials
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.key_outlined),
                                label: const Text('Salvar credenciais FCM'),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Configuracao de envio',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              TenantAdminSettingsEditableValueRow(
                                key: const ValueKey(
                                  'tenant_admin_settings_push_ttl_edit',
                                ),
                                label: 'Max TTL (dias)',
                                value: controller.pushMaxTtlDaysController.text,
                                onEdit: isSaving
                                    ? null
                                    : () => _editPositiveIntField(
                                          context: context,
                                          fieldController:
                                              controller.pushMaxTtlDaysController,
                                          title: 'Editar Max TTL',
                                          label: 'Max TTL (dias)',
                                        ),
                              ),
                              TenantAdminSettingsEditableValueRow(
                                key: const ValueKey(
                                  'tenant_admin_settings_push_max_per_minute_edit',
                                ),
                                label: 'Maximo por minuto',
                                value:
                                    controller.pushMaxPerMinuteController.text,
                                onEdit: isSaving
                                    ? null
                                    : () => _editPositiveIntField(
                                          context: context,
                                          fieldController: controller
                                              .pushMaxPerMinuteController,
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
                                          fieldController:
                                              controller.pushMaxPerHourController,
                                          title: 'Editar maximo por hora',
                                          label: 'Maximo por hora',
                                        ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                key: TenantAdminSettingsKeys
                                    .technicalIntegrationsSavePush,
                                onPressed:
                                    isSaving ? null : controller.savePushSettings,
                                icon: isSaving
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Salvar configuracao de push'),
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
          },
        );
      },
    );
  }
}

class _PushSecretEditSheet extends StatefulWidget {
  const _PushSecretEditSheet({
    required this.title,
    required this.label,
    required this.helperText,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String helperText;
  final String initialValue;

  @override
  State<_PushSecretEditSheet> createState() => _PushSecretEditSheetState();
}

class _PushSecretEditSheetState extends State<_PushSecretEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    context.router.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              minLines: 6,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return '${widget.label} obrigatoria.';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: widget.label,
                helperText: widget.helperText,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.key_outlined),
                label: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
