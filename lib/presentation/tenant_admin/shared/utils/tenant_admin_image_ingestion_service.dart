import 'dart:math' as math;
import 'dart:typed_data';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';

enum TenantAdminImageSlot {
  avatar,
  cover,
}

class TenantAdminImageIngestionException implements Exception {
  TenantAdminImageIngestionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TenantAdminImageIngestionService {
  TenantAdminImageIngestionService({
    ImagePicker? imagePicker,
    TenantAdminExternalImageProxyContract? externalImageProxy,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _externalImageProxy = externalImageProxy;

  final ImagePicker _imagePicker;
  final TenantAdminExternalImageProxyContract? _externalImageProxy;

  static const int _maxSourceBytes = 15 * 1024 * 1024;
  static const int _maxOutputBytes = 2 * 1024 * 1024;

  /// Picks an image from the device gallery without transforming it.
  ///
  /// The caller is responsible for passing the selected file through the crop
  /// + normalize pipeline before uploading.
  Future<XFile?> pickFromDevice({required TenantAdminImageSlot slot}) async {
    final selected = await _imagePicker.pickImage(source: ImageSource.gallery);
    return selected;
  }

  Future<XFile> fetchFromUrlForCrop({
    required String imageUrl,
  }) async {
    final uri = Uri.tryParse(imageUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw TenantAdminImageIngestionException('URL da imagem invalida.');
    }

    try {
      final proxy = _externalImageProxy ??
          GetIt.I.get<TenantAdminExternalImageProxyContract>();
      final data = await proxy.fetchExternalImageBytes(imageUrl: uri.toString());
      if (data.isEmpty) {
        throw TenantAdminImageIngestionException(
          'Nao foi possivel baixar a imagem da URL informada.',
        );
      }
      if (data.length > _maxSourceBytes) {
        throw TenantAdminImageIngestionException(
          'Imagem muito grande para processamento. Maximo 15MB.',
        );
      }
      return XFile.fromData(
        data,
        name: 'url_${DateTime.now().millisecondsSinceEpoch}',
      );
    } on TenantAdminImageIngestionException {
      rethrow;
    } catch (error) {
      throw TenantAdminImageIngestionException(
        'Esse site nao permite importacao direta. '
        'Baixe a imagem e envie do dispositivo.',
      );
    }
  }

  Future<XFile> prepareXFile(
    XFile file, {
    required TenantAdminImageSlot slot,
  }) async {
    final bytes = await file.readAsBytes();
    return prepareBytesAsXFile(
      bytes,
      slot: slot,
      applyAspectCrop: true,
    );
  }

  Future<Uint8List> readBytesForCrop(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxSourceBytes) {
      throw TenantAdminImageIngestionException(
        'Imagem muito grande para processamento. Maximo 15MB.',
      );
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw TenantAdminImageIngestionException(
        'Arquivo de imagem invalido. Use JPG, PNG ou WEBP.',
      );
    }
    return bytes;
  }

  Future<XFile> prepareBytesAsXFile(
    Uint8List sourceBytes, {
    required TenantAdminImageSlot slot,
    required bool applyAspectCrop,
  }) async {
    return _prepareBytesAsFile(
      sourceBytes,
      slot: slot,
      applyAspectCrop: applyAspectCrop,
    );
  }

  Future<TenantAdminMediaUpload?> buildUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) async {
    if (file == null) {
      return null;
    }
    var bytes = await file.readAsBytes();
    if (bytes.length > _maxOutputBytes || file.mimeType != 'image/jpeg') {
      final prepared = await prepareXFile(file, slot: slot);
      bytes = await prepared.readAsBytes();
    }
    return TenantAdminMediaUpload(
      bytes: bytes,
      fileName: _buildOutputFileName(slot),
      mimeType: 'image/jpeg',
    );
  }

  Future<XFile> _prepareBytesAsFile(
    Uint8List sourceBytes, {
    required TenantAdminImageSlot slot,
    required bool applyAspectCrop,
  }) async {
    if (sourceBytes.length > _maxSourceBytes) {
      throw TenantAdminImageIngestionException(
        'Imagem muito grande para processamento. Maximo 15MB.',
      );
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw TenantAdminImageIngestionException(
        'Arquivo de imagem invalido. Use JPG, PNG ou WEBP.',
      );
    }

    final ratio = slot == TenantAdminImageSlot.avatar ? 1.0 : (16 / 9);
    final cropped =
        applyAspectCrop ? _centerCropToRatio(decoded, ratio) : decoded;
    final resized = _resizeToBounds(
      cropped,
      maxWidth: slot == TenantAdminImageSlot.avatar ? 1024 : 1920,
      maxHeight: slot == TenantAdminImageSlot.avatar ? 1024 : 1080,
    );

    final encoded = _encodeJpegWithinLimit(resized, _maxOutputBytes);
    final fileName = _buildOutputFileName(slot);
    return XFile.fromData(
      encoded,
      mimeType: 'image/jpeg',
      name: fileName,
    );
  }

  img.Image _centerCropToRatio(img.Image source, double targetRatio) {
    final sourceRatio = source.width / source.height;
    if ((sourceRatio - targetRatio).abs() < 0.0001) {
      return source;
    }

    if (sourceRatio > targetRatio) {
      final cropWidth = (source.height * targetRatio).round();
      final left = ((source.width - cropWidth) / 2).round();
      return img.copyCrop(
        source,
        x: math.max(0, left),
        y: 0,
        width: cropWidth,
        height: source.height,
      );
    }

    final cropHeight = (source.width / targetRatio).round();
    final top = ((source.height - cropHeight) / 2).round();
    return img.copyCrop(
      source,
      x: 0,
      y: math.max(0, top),
      width: source.width,
      height: cropHeight,
    );
  }

  img.Image _resizeToBounds(
    img.Image source, {
    required int maxWidth,
    required int maxHeight,
  }) {
    if (source.width <= maxWidth && source.height <= maxHeight) {
      return source;
    }
    final widthScale = maxWidth / source.width;
    final heightScale = maxHeight / source.height;
    final scale = math.min(widthScale, heightScale);
    final width = math.max(1, (source.width * scale).round());
    final height = math.max(1, (source.height * scale).round());
    return img.copyResize(
      source,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }

  Uint8List _encodeJpegWithinLimit(img.Image source, int maxBytes) {
    const qualities = <int>[88, 82, 76, 70, 64, 58, 52];
    img.Image current = source;

    for (var pass = 0; pass < 6; pass++) {
      for (final quality in qualities) {
        final bytes =
            Uint8List.fromList(img.encodeJpg(current, quality: quality));
        if (bytes.length <= maxBytes) {
          return bytes;
        }
      }

      final nextWidth = math.max(1, (current.width * 0.85).round());
      final nextHeight = math.max(1, (current.height * 0.85).round());
      if (nextWidth == current.width && nextHeight == current.height) {
        break;
      }
      current = img.copyResize(
        current,
        width: nextWidth,
        height: nextHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    final fallback = Uint8List.fromList(img.encodeJpg(current, quality: 48));
    if (fallback.length > maxBytes) {
      throw TenantAdminImageIngestionException(
        'Nao foi possivel reduzir a imagem para o tamanho permitido.',
      );
    }
    return fallback;
  }

  String _buildOutputFileName(TenantAdminImageSlot slot) {
    return '${slot.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
