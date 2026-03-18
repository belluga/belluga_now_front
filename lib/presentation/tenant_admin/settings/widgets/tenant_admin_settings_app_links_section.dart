import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsAppLinksSection extends StatelessWidget {
  const TenantAdminSettingsAppLinksSection({
    super.key,
    required this.controller,
  });

  final TenantAdminSettingsController controller;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.appLinksAndroidPackageNameController,
        controller.appLinksAndroidFingerprintsController,
        controller.appLinksIosTeamIdController,
        controller.appLinksIosBundleIdController,
      ],
    );
  }

  String _formatListValue(String raw) {
    final normalized = raw
        .split(RegExp(r'[\n,;]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) {
      return '-';
    }
    if (normalized.length == 1) {
      return normalized.first;
    }
    return '${normalized.first} (+${normalized.length - 1})';
  }

  Future<void> _editField({
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
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
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

  String _formatPathSelection({
    required List<String> selectedPaths,
    required List<String> canonicalPaths,
  }) {
    if (selectedPaths.length == canonicalPaths.length) {
      return 'Todos os paths canônicos (${selectedPaths.length})';
    }
    if (selectedPaths.isEmpty) {
      return 'Nenhum path selecionado';
    }
    if (selectedPaths.length == 1) {
      return selectedPaths.first;
    }
    return '${selectedPaths.first} (+${selectedPaths.length - 1})';
  }

  Future<void> _editIosPaths({
    required BuildContext context,
    required List<String> selectedPaths,
  }) async {
    final canonicalPaths = controller.appLinksCanonicalIosPaths;
    final selected = selectedPaths.toSet();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Selecionar iOS paths'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecione os paths canônicos suportados para Universal Links.',
                      ),
                      const SizedBox(height: 12),
                      for (final path in canonicalPaths)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(path),
                          value: selected.contains(path),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selected.add(path);
                              } else {
                                selected.remove(path);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.router.maybePop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    dialogContext.router.maybePop(
                      canonicalPaths
                          .where(selected.contains)
                          .toList(growable: false),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    controller.updateAppLinksIosPathsSelection(result);
  }

  String? _validateSha256List(String? raw) {
    final entries = (raw ?? '')
        .split(RegExp(r'[\n,;]'))
        .map((entry) => entry.trim().toUpperCase())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return 'Informe ao menos um fingerprint SHA-256.';
    }
    final pattern = RegExp(r'^([A-F0-9]{2}:){31}[A-F0-9]{2}$');
    final invalid = entries.firstWhere(
      (entry) => !pattern.hasMatch(entry),
      orElse: () => '',
    );
    if (invalid.isNotEmpty) {
      return 'Fingerprint inválido: $invalid';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.appLinksSubmittingStreamValue,
      builder: (context, isSaving) {
        return StreamValueBuilder<List<String>>(
          streamValue: controller.appLinksIosPathsSelectionStreamValue,
          builder: (context, selectedIosPaths) => AnimatedBuilder(
            animation: _controllersListenable(),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TenantAdminSettingsEditableValueRow(
                  key: TenantAdminSettingsKeys
                      .technicalIntegrationsAppLinksAndroidPackageEdit,
                  label: 'Android package',
                  value: controller.appLinksAndroidPackageNameController.text,
                  onEdit: isSaving
                      ? null
                      : () => _editField(
                            context: context,
                            fieldController:
                                controller.appLinksAndroidPackageNameController,
                            title: 'Editar Android package',
                            label: 'Package',
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Package obrigatório.';
                              }
                              return null;
                            },
                          ),
                ),
                TenantAdminSettingsEditableValueRow(
                  key: TenantAdminSettingsKeys
                      .technicalIntegrationsAppLinksFingerprintsEdit,
                  label: 'SHA-256 fingerprints',
                  value: _formatListValue(
                    controller.appLinksAndroidFingerprintsController.text,
                  ),
                  onEdit: isSaving
                      ? null
                      : () => _editField(
                            context: context,
                            fieldController: controller
                                .appLinksAndroidFingerprintsController,
                            title: 'Editar SHA-256 fingerprints',
                            label: 'Fingerprints',
                            helperText: 'Separe por vírgula.',
                            validator: _validateSha256List,
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                    'Android paths são definidos no manifest/intent-filter do app (não editável aqui).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TenantAdminSettingsEditableValueRow(
                  key: TenantAdminSettingsKeys
                      .technicalIntegrationsAppLinksIosTeamIdEdit,
                  label: 'iOS team_id',
                  value: controller.appLinksIosTeamIdController.text,
                  onEdit: isSaving
                      ? null
                      : () => _editField(
                            context: context,
                            fieldController:
                                controller.appLinksIosTeamIdController,
                            title: 'Editar iOS team_id',
                            label: 'team_id',
                          ),
                ),
                TenantAdminSettingsEditableValueRow(
                  key: TenantAdminSettingsKeys
                      .technicalIntegrationsAppLinksIosBundleIdEdit,
                  label: 'iOS bundle_id',
                  value: controller.appLinksIosBundleIdController.text,
                  onEdit: isSaving
                      ? null
                      : () => _editField(
                            context: context,
                            fieldController:
                                controller.appLinksIosBundleIdController,
                            title: 'Editar iOS bundle_id',
                            label: 'bundle_id',
                          ),
                ),
                TenantAdminSettingsEditableValueRow(
                  key: TenantAdminSettingsKeys
                      .technicalIntegrationsAppLinksIosPathsEdit,
                  label: 'iOS paths',
                  value: _formatPathSelection(
                    selectedPaths: selectedIosPaths,
                    canonicalPaths: controller.appLinksCanonicalIosPaths,
                  ),
                  onEdit: isSaving
                      ? null
                      : () => _editIosPaths(
                            context: context,
                            selectedPaths: selectedIosPaths,
                          ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key:
                      TenantAdminSettingsKeys.technicalIntegrationsSaveAppLinks,
                  onPressed: isSaving ? null : controller.saveAppLinksSettings,
                  icon: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Salvar App Links'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
