import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_branding_image_field.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_editable_value_row.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_color_picker_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminBrandingBusyResolver = bool Function(
  TenantAdminBrandingAssetSlot slot,
);

class TenantAdminSettingsBrandingSection extends StatelessWidget {
  const TenantAdminSettingsBrandingSection({
    super.key,
    required this.controller,
    required this.isSlotBusy,
    required this.onPickImage,
    required this.onClearLocalSelection,
    required this.onSave,
  });

  final TenantAdminSettingsController controller;
  final TenantAdminBrandingBusyResolver isSlotBusy;
  final TenantAdminBrandingPickCallback onPickImage;
  final TenantAdminBrandingClearCallback onClearLocalSelection;
  final Future<void> Function() onSave;

  Listenable _controllersListenable() {
    return Listenable.merge(
      [
        controller.brandingTenantNameController,
        controller.brandingPrimarySeedColorController,
        controller.brandingSecondarySeedColorController,
      ],
    );
  }

  Future<void> _editTenantName(BuildContext context) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome do tenant',
      label: 'Nome',
      initialValue: controller.brandingTenantNameController.text,
      confirmLabel: 'Aplicar',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Nome obrigatorio.';
        }
        return null;
      },
    );
    if (result == null) {
      return;
    }
    controller.brandingTenantNameController.text = result.value.trim();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.brandingSubmittingStreamValue,
      builder: (context, isSaving) {
        return StreamValueBuilder<TenantAdminBrandingBrightness>(
          streamValue: controller.brandingBrightnessStreamValue,
          builder: (context, brightness) {
            return AnimatedBuilder(
              animation: _controllersListenable(),
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Observacao: o endpoint atual de branding salva tema e logos/icones. '
                        'A persistencia do nome do tenant depende de endpoint dedicado.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsEditableValueRow(
                      key: const ValueKey(
                        'tenant_admin_settings_branding_name_edit',
                      ),
                      label: 'Nome do tenant',
                      value: controller.brandingTenantNameController.text,
                      onEdit: isSaving ? null : () => _editTenantName(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tema default',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<TenantAdminBrandingBrightness>(
                      segments: const [
                        ButtonSegment(
                          value: TenantAdminBrandingBrightness.light,
                          label: Text('Claro'),
                        ),
                        ButtonSegment(
                          value: TenantAdminBrandingBrightness.dark,
                          label: Text('Escuro'),
                        ),
                      ],
                      selected: {brightness},
                      onSelectionChanged: isSaving
                          ? null
                          : (selection) {
                              if (selection.isEmpty) {
                                return;
                              }
                              controller
                                  .selectBrandingBrightness(selection.first);
                            },
                    ),
                    const SizedBox(height: 8),
                    TenantAdminColorPickerField(
                      key: TenantAdminSettingsKeys.brandingPrimaryField,
                      controller: controller.brandingPrimarySeedColorController,
                      labelText: 'Cor primaria (#RRGGBB)',
                      enabled: !isSaving,
                      semanticsIdentifier:
                          'tenant_admin_branding_primary_color_field',
                      pickerButtonSemanticsIdentifier:
                          'tenant_admin_branding_primary_color_picker_button',
                      pickerButtonKey:
                          TenantAdminSettingsKeys.brandingPrimaryPickerButton,
                    ),
                    const SizedBox(height: 8),
                    TenantAdminColorPickerField(
                      key: TenantAdminSettingsKeys.brandingSecondaryField,
                      controller:
                          controller.brandingSecondarySeedColorController,
                      labelText: 'Cor secundaria (#RRGGBB)',
                      enabled: !isSaving,
                      semanticsIdentifier:
                          'tenant_admin_branding_secondary_color_field',
                      pickerButtonSemanticsIdentifier:
                          'tenant_admin_branding_secondary_color_picker_button',
                      pickerButtonKey:
                          TenantAdminSettingsKeys.brandingSecondaryPickerButton,
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsBrandingImageField(
                      title: 'Logo claro',
                      slot: TenantAdminBrandingAssetSlot.lightLogo,
                      controller: controller,
                      isBusy: isSaving ||
                          isSlotBusy(TenantAdminBrandingAssetSlot.lightLogo),
                      onPick: onPickImage,
                      onClearLocalSelection: onClearLocalSelection,
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsBrandingImageField(
                      title: 'Logo escuro',
                      slot: TenantAdminBrandingAssetSlot.darkLogo,
                      controller: controller,
                      isBusy: isSaving ||
                          isSlotBusy(TenantAdminBrandingAssetSlot.darkLogo),
                      onPick: onPickImage,
                      onClearLocalSelection: onClearLocalSelection,
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsBrandingImageField(
                      title: 'Icone claro',
                      slot: TenantAdminBrandingAssetSlot.lightIcon,
                      controller: controller,
                      isBusy: isSaving ||
                          isSlotBusy(TenantAdminBrandingAssetSlot.lightIcon),
                      onPick: onPickImage,
                      onClearLocalSelection: onClearLocalSelection,
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsBrandingImageField(
                      title: 'Icone escuro',
                      slot: TenantAdminBrandingAssetSlot.darkIcon,
                      controller: controller,
                      isBusy: isSaving ||
                          isSlotBusy(TenantAdminBrandingAssetSlot.darkIcon),
                      onPick: onPickImage,
                      onClearLocalSelection: onClearLocalSelection,
                    ),
                    const SizedBox(height: 12),
                    TenantAdminSettingsBrandingImageField(
                      title: 'Icone PWA',
                      slot: TenantAdminBrandingAssetSlot.pwaIcon,
                      controller: controller,
                      isBusy: isSaving ||
                          isSlotBusy(TenantAdminBrandingAssetSlot.pwaIcon),
                      onPick: onPickImage,
                      onClearLocalSelection: onClearLocalSelection,
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: 'tenant_admin_branding_save_button',
                      button: true,
                      onTap: isSaving ? null : () => onSave(),
                      child: FilledButton.icon(
                        key: const ValueKey(
                            'tenant_admin_settings_save_branding'),
                        onPressed: isSaving ? null : onSave,
                        icon: isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar Branding'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
