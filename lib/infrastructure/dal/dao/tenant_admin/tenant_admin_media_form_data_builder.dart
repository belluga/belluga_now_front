import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class TenantAdminMediaFormDataBuilder {
  const TenantAdminMediaFormDataBuilder();

  FormData buildMultipartPayload({
    required Object payload,
  }) {
    if (payload case final Map<String, dynamic> mapPayload) {
      return FormData.fromMap(
        _normalizeMultipartMap(mapPayload),
        ListFormat.multiCompatible,
      );
    }
    if (payload case final Map mapPayload) {
      final normalizedPayload = <String, dynamic>{};
      for (final entry in mapPayload.entries) {
        final key = entry.key;
        if (key is! String) {
          throw const FormatException(
            'Failed to build multipart payload: payload keys must be strings.',
          );
        }
        normalizedPayload[key] = _normalizeMultipartValue(entry.value);
      }
      return FormData.fromMap(normalizedPayload, ListFormat.multiCompatible);
    }
    throw const FormatException(
      'Failed to build multipart payload: expected map-compatible payload.',
    );
  }

  FormData? buildAvatarCoverPayload({
    required Map<String, dynamic> payload,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) {
    if (avatarUpload == null && coverUpload == null) {
      return null;
    }

    final formData = FormData.fromMap(
      _normalizeMultipartMap(payload),
      ListFormat.multiCompatible,
    );
    if (avatarUpload != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            avatarUpload.bytes,
            filename: avatarUpload.fileName,
            contentType: _resolveMediaType(avatarUpload),
          ),
        ),
      );
    }
    if (coverUpload != null) {
      formData.files.add(
        MapEntry(
          'cover',
          MultipartFile.fromBytes(
            coverUpload.bytes,
            filename: coverUpload.fileName,
            contentType: _resolveMediaType(coverUpload),
          ),
        ),
      );
    }
    return formData;
  }

  FormData? buildTypeAssetPayload({
    required Map<String, dynamic> payload,
    TenantAdminMediaUpload? typeAssetUpload,
  }) {
    if (typeAssetUpload == null) {
      return null;
    }

    final formData = FormData.fromMap(
      _normalizeMultipartMap(payload),
      ListFormat.multiCompatible,
    );
    formData.files.add(
      MapEntry(
        'type_asset',
        MultipartFile.fromBytes(
          typeAssetUpload.bytes,
          filename: typeAssetUpload.fileName,
          contentType: _resolveMediaType(typeAssetUpload),
        ),
      ),
    );
    return formData;
  }

  MediaType _resolveMediaType(TenantAdminMediaUpload upload) {
    final mimeType = upload.mimeType ?? _inferMimeType(upload.fileName);
    if (mimeType == null) {
      return MediaType('application', 'octet-stream');
    }
    final parts = mimeType.split('/');
    if (parts.length != 2) {
      return MediaType('application', 'octet-stream');
    }
    return MediaType(parts[0], parts[1]);
  }

  String? _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Map<String, dynamic> _normalizeMultipartMap(Map<String, dynamic> payload) {
    return payload.map(
      (key, value) => MapEntry(key, _normalizeMultipartValue(value)),
    );
  }

  dynamic _normalizeMultipartValue(Object? value) {
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is Map<String, dynamic>) {
      return _normalizeMultipartMap(value);
    }
    if (value is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw const FormatException(
            'Failed to build multipart payload: payload keys must be strings.',
          );
        }
        normalized[key] = _normalizeMultipartValue(entry.value);
      }
      return normalized;
    }
    if (value is List) {
      return value.map(_normalizeMultipartValue).toList(growable: false);
    }
    return value;
  }
}
