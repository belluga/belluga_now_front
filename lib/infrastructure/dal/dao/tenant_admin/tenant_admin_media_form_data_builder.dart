import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class TenantAdminMediaFormDataBuilder {
  const TenantAdminMediaFormDataBuilder();

  FormData buildMultipartPayload({
    required Object payload,
  }) {
    if (payload case final Map<String, dynamic> mapPayload) {
      return FormData.fromMap(mapPayload, ListFormat.multiCompatible);
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
        normalizedPayload[key] = entry.value;
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

    final formData = FormData.fromMap(payload, ListFormat.multiCompatible);
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
}
