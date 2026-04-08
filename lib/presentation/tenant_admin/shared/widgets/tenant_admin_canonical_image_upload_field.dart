import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminCanonicalImageUploadField extends StatefulWidget {
  const TenantAdminCanonicalImageUploadField({
    super.key,
    required this.variant,
    required this.preview,
    required this.addLabel,
    required this.sourceSheetTitle,
    required this.urlPromptTitle,
    required this.slot,
    required this.pickFromDevice,
    required this.fetchImageFromUrlForCrop,
    required this.readBytesForCrop,
    required this.prepareCroppedFile,
    required this.onImageSelected,
    this.selectedLabel,
    this.removeLabel = 'Remover',
    this.addButtonKey,
    this.removeButtonKey,
    this.onRemove,
    this.canRemove = false,
    this.busy = false,
    this.initialWebUrl,
    this.onBusyChanged,
    this.onIngestionError,
  });

  final TenantAdminImageUploadVariant variant;
  final Widget preview;
  final String? selectedLabel;
  final String addLabel;
  final String removeLabel;
  final String sourceSheetTitle;
  final String urlPromptTitle;
  final Key? addButtonKey;
  final Key? removeButtonKey;
  final VoidCallback? onRemove;
  final bool canRemove;
  final bool busy;
  final String? initialWebUrl;
  final TenantAdminImageSlot slot;
  final Future<XFile?> Function() pickFromDevice;
  final Future<XFile> Function({required String imageUrl})
      fetchImageFromUrlForCrop;
  final Future<Uint8List> Function(XFile sourceFile) readBytesForCrop;
  final Future<XFile> Function(
    Uint8List croppedData,
    {
    required TenantAdminImageSlot slot,
  }
  ) prepareCroppedFile;
  final FutureOr<void> Function(XFile file) onImageSelected;
  final ValueChanged<bool>? onBusyChanged;
  final ValueChanged<String>? onIngestionError;

  @override
  State<TenantAdminCanonicalImageUploadField> createState() =>
      _TenantAdminCanonicalImageUploadFieldState();
}

class _TenantAdminCanonicalImageUploadFieldState
    extends State<TenantAdminCanonicalImageUploadField> {
  bool _processing = false;

  bool get _effectiveBusy => widget.busy || _processing;

  Future<void> _handleAdd() async {
    if (_effectiveBusy) {
      return;
    }
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: widget.sourceSheetTitle,
    );
    if (!mounted || source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _runImageFlow(loadSourceFile: widget.pickFromDevice);
      return;
    }
    await _pickFromWeb();
  }

  Future<void> _pickFromWeb() async {
    if (_effectiveBusy) {
      return;
    }
    final url = await _promptWebImageUrl();
    if (!mounted || url == null) {
      return;
    }
    await _runImageFlow(
      loadSourceFile: () =>
          widget.fetchImageFromUrlForCrop(imageUrl: url.trim()),
    );
  }

  Future<String?> _promptWebImageUrl() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: widget.urlPromptTitle,
      label: 'URL da imagem',
      initialValue: widget.initialWebUrl ?? '',
      helperText: 'Use URL completa (http/https).',
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'URL obrigatória.';
        }
        final uri = Uri.tryParse(trimmed);
        final hasScheme = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!hasScheme) {
          return 'URL inválida.';
        }
        return null;
      },
    );
    return result?.value.trim();
  }

  Future<void> _runImageFlow({
    required Future<XFile?> Function() loadSourceFile,
  }) async {
    if (_effectiveBusy) {
      return;
    }
    _setProcessing(true);
    try {
      final sourceFile = await loadSourceFile();
      if (sourceFile == null || !mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: widget.slot,
        readBytesForCrop: widget.readBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            widget.prepareCroppedFile(
          croppedData,
          slot: cropSlot,
        ),
      );
      if (cropped == null) {
        return;
      }
      await widget.onImageSelected(cropped);
    } on TenantAdminImageIngestionException catch (error) {
      _reportIngestionError(error.message);
    } finally {
      _setProcessing(false);
    }
  }

  void _setProcessing(bool value) {
    if (_processing == value) {
      return;
    }
    setState(() {
      _processing = value;
    });
    widget.onBusyChanged?.call(value);
  }

  void _reportIngestionError(String message) {
    final customReporter = widget.onIngestionError;
    if (customReporter != null) {
      customReporter(message);
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TenantAdminImageUploadField(
      variant: widget.variant,
      preview: widget.preview,
      selectedLabel: widget.selectedLabel,
      addLabel: widget.addLabel,
      removeLabel: widget.removeLabel,
      addButtonKey: widget.addButtonKey,
      removeButtonKey: widget.removeButtonKey,
      onAdd: _handleAdd,
      busy: _effectiveBusy,
      canRemove: widget.canRemove,
      onRemove: widget.onRemove,
    );
  }
}
