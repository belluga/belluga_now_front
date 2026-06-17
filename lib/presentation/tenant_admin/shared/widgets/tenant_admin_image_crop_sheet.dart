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

  TenantAdminImageSlotSpec get _slotSpec =>
      tenantAdminImageSlotSpecFor(widget.slot);

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

  double? get _aspectRatio => _slotSpec.aspectRatio;

  String get _title => _slotSpec.cropTitle;

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
                        withCircleUi: _slotSpec.circularCrop,
                        aspectRatio: _aspectRatio,
                        overlayBuilder: _slotSpec.safeAreaGuide == null
                            ? null
                            : (context, rect) =>
                                _TenantAdminImageSafeAreaGuideOverlay(
                                  guide: _slotSpec.safeAreaGuide!,
                                ),
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

class _TenantAdminImageSafeAreaGuideOverlay extends StatelessWidget {
  const _TenantAdminImageSafeAreaGuideOverlay({required this.guide});

  final TenantAdminImageSafeAreaGuideSpec guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final topHeight =
              height * guide.topOverlayFraction.clamp(0.0, 0.45).toDouble();
          final bottomHeight =
              height * guide.bottomOverlayFraction.clamp(0.0, 0.55).toDouble();
          final sideWidth =
              width * guide.sideInsetFraction.clamp(0.0, 0.25).toDouble();

          return Stack(
            key: const ValueKey<String>(
              'tenantAdminHeroCropCompositionGuide',
            ),
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.84),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey<String>(
                  'tenantAdminHeroCropTopInterfaceZone',
                ),
                left: 0,
                right: 0,
                top: 0,
                height: topHeight,
                child: _TenantAdminImageGuideBand(
                  label: guide.topLabel,
                  color: Colors.black.withValues(alpha: 0.34),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Positioned(
                key: const ValueKey<String>(
                  'tenantAdminHeroCropBottomInterfaceZone',
                ),
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomHeight,
                child: _TenantAdminImageGuideBand(
                  label: guide.bottomLabel,
                  helper: guide.helper,
                  color: Colors.black.withValues(alpha: 0.44),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              Positioned(
                key: const ValueKey<String>(
                  'tenantAdminHeroCropLeftBreathingZone',
                ),
                left: 0,
                top: topHeight,
                bottom: bottomHeight,
                width: sideWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey<String>(
                  'tenantAdminHeroCropRightBreathingZone',
                ),
                right: 0,
                top: topHeight,
                bottom: bottomHeight,
                width: sideWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey<String>(
                  'tenantAdminHeroCropFocusZone',
                ),
                left: sideWidth,
                right: sideWidth,
                top: topHeight,
                bottom: bottomHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: Colors.white.withValues(alpha: 0.72),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        guide.focusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TenantAdminImageGuideBand extends StatelessWidget {
  const _TenantAdminImageGuideBand({
    required this.label,
    required this.color,
    required this.alignment,
    required this.padding,
    this.helper,
  });

  final String label;
  final String? helper;
  final Color color;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: alignment,
            child: Padding(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.88,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (helper != null)
                          Text(
                            helper!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.66),
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
