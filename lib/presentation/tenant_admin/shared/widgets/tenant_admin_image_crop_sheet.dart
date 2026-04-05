import 'dart:async';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> showTenantAdminImageCropSheet({
  required BuildContext context,
  required XFile sourceFile,
  required TenantAdminImageSlot slot,
  required Future<Uint8List> Function(XFile sourceFile) readBytesForCrop,
  required Future<XFile> Function(
    Uint8List croppedData,
    TenantAdminImageSlot slot,
  ) prepareCroppedFile,
}) {
  return showModalBottomSheet<XFile?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TenantAdminImageCropSheet(
      sourceFile: sourceFile,
      slot: slot,
      readBytesForCrop: readBytesForCrop,
      prepareCroppedFile: prepareCroppedFile,
    ),
  );
}

class _TenantAdminImageCropSheet extends StatefulWidget {
  const _TenantAdminImageCropSheet({
    required this.sourceFile,
    required this.slot,
    required this.readBytesForCrop,
    required this.prepareCroppedFile,
  });

  final XFile sourceFile;
  final TenantAdminImageSlot slot;
  final Future<Uint8List> Function(XFile sourceFile) readBytesForCrop;
  final Future<XFile> Function(
    Uint8List croppedData,
    TenantAdminImageSlot slot,
  ) prepareCroppedFile;

  @override
  State<_TenantAdminImageCropSheet> createState() =>
      _TenantAdminImageCropSheetState();
}

class _TenantAdminImageCropSheetState
    extends State<_TenantAdminImageCropSheet> {
  final CropController _cropController = CropController();

  Uint8List? _bytes;
  String? _errorMessage;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  void _requestRebuild() {
    if (!mounted) {
      return;
    }
    (context as Element).markNeedsBuild();
  }

  Future<void> _loadBytes() async {
    _loading = true;
    _errorMessage = null;
    _requestRebuild();
    try {
      final bytes = await widget.readBytesForCrop(widget.sourceFile);
      if (!mounted) return;
      _bytes = bytes;
      _requestRebuild();
    } on TenantAdminImageIngestionException catch (error) {
      if (!mounted) return;
      _errorMessage = error.message;
      _requestRebuild();
    } catch (error) {
      if (!mounted) return;
      _errorMessage = 'Nao foi possivel carregar a imagem selecionada.';
      _requestRebuild();
    } finally {
      if (mounted) {
        _loading = false;
        _requestRebuild();
      }
    }
  }

  double get _aspectRatio => widget.slot == TenantAdminImageSlot.avatar
      ? 1.0
      : switch (widget.slot) {
          TenantAdminImageSlot.cover => 16 / 9,
          TenantAdminImageSlot.lightLogo => 18 / 5,
          TenantAdminImageSlot.darkLogo => 18 / 5,
          TenantAdminImageSlot.lightIcon => 1.0,
          TenantAdminImageSlot.darkIcon => 1.0,
          TenantAdminImageSlot.pwaIcon => 1.0,
          TenantAdminImageSlot.mapFilter => 1.0,
          TenantAdminImageSlot.typeVisual => 1.0,
          TenantAdminImageSlot.avatar => 1.0,
        };

  String get _title => switch (widget.slot) {
        TenantAdminImageSlot.avatar => 'Recortar avatar',
        TenantAdminImageSlot.cover => 'Recortar capa',
        TenantAdminImageSlot.lightLogo => 'Recortar logo claro',
        TenantAdminImageSlot.darkLogo => 'Recortar logo escuro',
        TenantAdminImageSlot.lightIcon => 'Recortar icone claro',
        TenantAdminImageSlot.darkIcon => 'Recortar icone escuro',
        TenantAdminImageSlot.pwaIcon => 'Recortar icone PWA',
        TenantAdminImageSlot.mapFilter => 'Recortar imagem do filtro',
        TenantAdminImageSlot.typeVisual => 'Recortar imagem canônica do tipo',
      };

  Future<void> _submit() async {
    if (_submitting || _bytes == null) return;
    _submitting = true;
    _requestRebuild();
    _cropController.crop();
  }

  Future<void> _handleCropResult(CropResult result) async {
    if (result case CropSuccess(:final croppedImage)) {
      await _handleCropped(croppedImage);
      return;
    }
    if (!mounted) return;
    _errorMessage = 'Nao foi possivel recortar a imagem.';
    _submitting = false;
    _requestRebuild();
  }

  Future<void> _handleCropped(Uint8List croppedData) async {
    widget.prepareCroppedFile(croppedData, widget.slot).then((output) {
      if (!mounted) return;
      context.router.maybePop(output);
    }).catchError((error) {
      if (!mounted) return;
      if (error is TenantAdminImageIngestionException) {
        _errorMessage = error.message;
      } else {
        _errorMessage = 'Nao foi possivel preparar a imagem recortada.';
      }
      _submitting = false;
      _requestRebuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * 0.82).clamp(360.0, 900.0);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed:
                      _submitting ? null : () => context.router.maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_bytes != null)
                      Crop(
                        image: _bytes!,
                        controller: _cropController,
                        withCircleUi:
                            widget.slot == TenantAdminImageSlot.avatar,
                        aspectRatio: _aspectRatio,
                        onCropped: (result) {
                          unawaited(_handleCropResult(result));
                        },
                      )
                    else
                      const Center(
                        child: Text('Nenhuma imagem selecionada.'),
                      ),
                    if (_submitting)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.35),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => context.router.maybePop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_loading || _bytes == null || _submitting)
                        ? null
                        : _submit,
                    child: const Text('Usar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
