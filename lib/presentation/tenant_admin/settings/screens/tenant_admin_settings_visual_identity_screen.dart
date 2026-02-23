import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_branding_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_remote_status_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminSettingsVisualIdentityScreen extends StatefulWidget {
  const TenantAdminSettingsVisualIdentityScreen({super.key});

  @override
  State<TenantAdminSettingsVisualIdentityScreen> createState() =>
      _TenantAdminSettingsVisualIdentityScreenState();
}

class _TenantAdminSettingsVisualIdentityScreenState
    extends State<TenantAdminSettingsVisualIdentityScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();
  final TenantAdminImageIngestionService _imageIngestionService =
      GetIt.I.get<TenantAdminImageIngestionService>();

  final Map<TenantAdminBrandingAssetSlot, bool> _brandingBusy = {
    TenantAdminBrandingAssetSlot.lightLogo: false,
    TenantAdminBrandingAssetSlot.darkLogo: false,
    TenantAdminBrandingAssetSlot.lightIcon: false,
    TenantAdminBrandingAssetSlot.darkIcon: false,
    TenantAdminBrandingAssetSlot.pwaIcon: false,
  };

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  void _handleBack() {
    if (context.router.canPop()) {
      context.router.pop();
      return;
    }
    context.router.replace(const TenantAdminSettingsRoute());
  }

  bool _isBrandingBusy(TenantAdminBrandingAssetSlot slot) =>
      _brandingBusy[slot] ?? false;

  void _setBrandingBusy(TenantAdminBrandingAssetSlot slot, bool value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _brandingBusy[slot] = value;
    });
  }

  TenantAdminImageSlot _toImageSlot(TenantAdminBrandingAssetSlot slot) {
    return switch (slot) {
      TenantAdminBrandingAssetSlot.lightLogo => TenantAdminImageSlot.lightLogo,
      TenantAdminBrandingAssetSlot.darkLogo => TenantAdminImageSlot.darkLogo,
      TenantAdminBrandingAssetSlot.lightIcon => TenantAdminImageSlot.lightIcon,
      TenantAdminBrandingAssetSlot.darkIcon => TenantAdminImageSlot.darkIcon,
      TenantAdminBrandingAssetSlot.pwaIcon => TenantAdminImageSlot.pwaIcon,
    };
  }

  String _brandingSlotTitle(TenantAdminBrandingAssetSlot slot) {
    return switch (slot) {
      TenantAdminBrandingAssetSlot.lightLogo => 'Logo claro',
      TenantAdminBrandingAssetSlot.darkLogo => 'Logo escuro',
      TenantAdminBrandingAssetSlot.lightIcon => 'Icone claro',
      TenantAdminBrandingAssetSlot.darkIcon => 'Icone escuro',
      TenantAdminBrandingAssetSlot.pwaIcon => 'Icone PWA',
    };
  }

  Future<void> _pickBrandingImage({
    required TenantAdminBrandingAssetSlot slot,
  }) async {
    if (_isBrandingBusy(slot)) {
      return;
    }
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: 'Selecionar ${_brandingSlotTitle(slot).toLowerCase()}',
    );
    if (!mounted || source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _pickBrandingImageFromDevice(slot: slot);
      return;
    }
    await _pickBrandingImageFromWeb(slot: slot);
  }

  Future<void> _pickBrandingImageFromDevice({
    required TenantAdminBrandingAssetSlot slot,
  }) async {
    _setBrandingBusy(slot, true);
    try {
      final imageSlot = _toImageSlot(slot);
      final selected = await _imageIngestionService.pickFromDevice(
        slot: imageSlot,
      );
      if (selected == null || !mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: selected,
        slot: imageSlot,
        ingestionService: _imageIngestionService,
      );
      if (cropped == null) {
        return;
      }
      _controller.updateBrandingFile(slot, cropped);
    } on TenantAdminImageIngestionException catch (error) {
      _controller.remoteErrorStreamValue.addValue(error.message);
    } catch (_) {
      _controller.remoteErrorStreamValue.addValue(
        'Nao foi possivel selecionar a imagem.',
      );
    } finally {
      _setBrandingBusy(slot, false);
    }
  }

  Future<void> _pickBrandingImageFromWeb({
    required TenantAdminBrandingAssetSlot slot,
  }) async {
    _setBrandingBusy(slot, true);
    try {
      final currentUrl = _controller.brandingUrlStream(slot).value ?? '';
      final result = await showTenantAdminFieldEditSheet(
        context: context,
        title: 'URL da imagem',
        label: _brandingSlotTitle(slot),
        initialValue: currentUrl,
        confirmLabel: 'Baixar e recortar',
        keyboardType: TextInputType.url,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) {
            return 'Informe a URL da imagem.';
          }
          final uri = Uri.tryParse(trimmed);
          if (uri == null ||
              (uri.scheme != 'http' && uri.scheme != 'https') ||
              uri.host.trim().isEmpty) {
            return 'Informe uma URL valida (http/https).';
          }
          return null;
        },
      );
      if (!mounted || result == null) {
        return;
      }
      final sourceFile = await _imageIngestionService.fetchFromUrlForCrop(
        imageUrl: result.value.trim(),
      );
      if (!mounted) {
        return;
      }
      final imageSlot = _toImageSlot(slot);
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: imageSlot,
        ingestionService: _imageIngestionService,
      );
      if (cropped == null) {
        return;
      }
      _controller.updateBrandingFile(slot, cropped);
    } on TenantAdminImageIngestionException catch (error) {
      _controller.remoteErrorStreamValue.addValue(error.message);
    } catch (_) {
      _controller.remoteErrorStreamValue.addValue(
        'Nao foi possivel processar a imagem da web.',
      );
    } finally {
      _setBrandingBusy(slot, false);
    }
  }

  Future<void> _saveBranding() async {
    try {
      final lightLogoUpload = await _imageIngestionService.buildUpload(
        _controller.brandingLightLogoFileStreamValue.value,
        slot: TenantAdminImageSlot.lightLogo,
      );
      final darkLogoUpload = await _imageIngestionService.buildUpload(
        _controller.brandingDarkLogoFileStreamValue.value,
        slot: TenantAdminImageSlot.darkLogo,
      );
      final lightIconUpload = await _imageIngestionService.buildUpload(
        _controller.brandingLightIconFileStreamValue.value,
        slot: TenantAdminImageSlot.lightIcon,
      );
      final darkIconUpload = await _imageIngestionService.buildUpload(
        _controller.brandingDarkIconFileStreamValue.value,
        slot: TenantAdminImageSlot.darkIcon,
      );
      final pwaIconUpload = await _imageIngestionService.buildUpload(
        _controller.brandingPwaIconFileStreamValue.value,
        slot: TenantAdminImageSlot.pwaIcon,
      );

      await _controller.saveBranding(
        lightLogoUpload: lightLogoUpload,
        darkLogoUpload: darkLogoUpload,
        lightIconUpload: lightIconUpload,
        darkIconUpload: darkIconUpload,
        pwaIconUpload: pwaIconUpload,
      );
    } on TenantAdminImageIngestionException catch (error) {
      _controller.remoteErrorStreamValue.addValue(error.message);
    } catch (_) {
      _controller.remoteErrorStreamValue.addValue(
        'Nao foi possivel preparar as imagens de branding.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: TenantAdminSettingsKeys.visualIdentityScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.visualIdentityScopedAppBar,
          title: 'Identidade visual',
          backButtonKey: TenantAdminSettingsKeys.visualIdentityBackButton,
          onBack: _handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsRemoteStatusPanel(
          controller: _controller,
          onReload: _controller.loadBrandingSettings,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Branding do tenant',
          description: 'Tema default, cores e ativos gráficos do tenant.',
          icon: Icons.palette_outlined,
          child: TenantAdminSettingsBrandingSection(
            controller: _controller,
            isSlotBusy: _isBrandingBusy,
            onPickImage: _pickBrandingImage,
            onClearLocalSelection: (slot) =>
                _controller.clearBrandingFile(slot),
            onSave: _saveBranding,
          ),
        ),
      ],
    );
  }
}
