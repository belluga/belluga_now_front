import 'dart:typed_data';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_favicon_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_exception.dart';
import 'package:get_it/get_it.dart';

class TenantAdminFaviconIngestionService {
  TenantAdminFaviconIngestionService({
    TenantAdminExternalImageProxyContract? externalImageProxy,
  }) : _externalImageProxy = externalImageProxy;

  final TenantAdminExternalImageProxyContract? _externalImageProxy;

  static const int _maxBytes = 2 * 1024 * 1024;
  static const String _defaultFileName = 'favicon.ico';
  static const List<String> _allowedMimeTypes = [
    'image/x-icon',
    'image/vnd.microsoft.icon',
  ];

  Future<TenantAdminMediaUpload?> pickFromDevice() async {
    try {
      final selected = await pickTenantAdminFaviconFile();
      if (selected == null) {
        return null;
      }

      return _buildValidatedUpload(
        bytes: selected.bytes,
        fileName: selected.name,
        mimeType: selected.mimeType,
      );
    } on UnsupportedError {
      throw TenantAdminImageIngestionException(
        'Selecao de favicon pelo dispositivo esta disponivel apenas no web admin.',
      );
    }
  }

  Future<TenantAdminMediaUpload> fetchFromUrl({
    required String faviconUrl,
  }) async {
    final uri = Uri.tryParse(faviconUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw TenantAdminImageIngestionException('URL do favicon invalida.');
    }

    try {
      final proxy = _externalImageProxy ??
          GetIt.I.get<TenantAdminExternalImageProxyContract>();
      final imageUrlValue = TenantAdminOptionalUrlValue();
      imageUrlValue.parse(uri.toString());
      final data = await proxy.fetchExternalImageBytes(imageUrl: imageUrlValue);

      return _buildValidatedUpload(
        bytes: data,
        fileName: _fileNameFromUri(uri),
      );
    } on TenantAdminImageIngestionException {
      rethrow;
    } catch (_) {
      throw TenantAdminImageIngestionException(
        'Nao foi possivel baixar o favicon informado.',
      );
    }
  }

  TenantAdminMediaUpload _buildValidatedUpload({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      throw TenantAdminImageIngestionException(
        'O favicon selecionado esta vazio.',
      );
    }

    if (bytes.length > _maxBytes) {
      throw TenantAdminImageIngestionException(
        'Favicon muito grande. Maximo 2MB.',
      );
    }

    if (!_looksLikeIco(bytes)) {
      throw TenantAdminImageIngestionException(
        'Use um arquivo favicon .ico valido.',
      );
    }

    return tenantAdminMediaUploadFromRaw(
      bytes: bytes,
      fileName: _normalizeFileName(fileName),
      mimeType: _normalizeMimeType(mimeType),
    );
  }

  bool _looksLikeIco(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0 &&
        bytes[1] == 0 &&
        bytes[2] == 1 &&
        bytes[3] == 0 &&
        bytes[4] > 0;
  }

  String _normalizeFileName(String rawFileName) {
    final trimmed = rawFileName.trim();
    if (trimmed.isEmpty) {
      return _defaultFileName;
    }

    final segments = trimmed.split('/');
    final fileName = segments.isEmpty ? trimmed : segments.last;
    if (fileName.toLowerCase().endsWith('.ico')) {
      return fileName;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);

    return '${baseName.isEmpty ? 'favicon' : baseName}.ico';
  }

  String _normalizeMimeType(String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return _allowedMimeTypes.first;
    }

    if (_allowedMimeTypes.contains(normalized)) {
      return normalized;
    }

    return _allowedMimeTypes.first;
  }

  String _fileNameFromUri(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return _defaultFileName;
    }

    final rawName = uri.pathSegments.last.trim();
    return rawName.isEmpty ? _defaultFileName : rawName;
  }
}
