import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_timezone_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dao/self_profile_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/self_profile_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http_parser/http_parser.dart';

class LaravelSelfProfileBackend implements SelfProfileBackendContract {
  LaravelSelfProfileBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  @override
  Future<SelfProfileDto> fetchCurrentProfile() async {
    final headers = await TenantPublicAuthHeaders.build(
      includeJsonAccept: true,
    );
    final response = await _dio.get(
      '$_apiBaseUrl/v1/me',
      options: Options(headers: headers),
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected self-profile response shape.');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing self-profile payload.');
    }
    return SelfProfileDto.fromJson(data);
  }

  @override
  Future<void> updateCurrentProfile({
    UserDisplayNameValue? displayNameValue,
    DescriptionValue? bioValue,
    UserTimezoneValue? timezoneValue,
    UserProfileMediaUpload? avatarUpload,
    DomainBooleanValue? removeAvatarValue,
  }) async {
    final headers = await TenantPublicAuthHeaders.build(
      includeJsonAccept: true,
    );
    final payload = <String, dynamic>{};
    if (displayNameValue != null) {
      payload['name'] = displayNameValue.value;
    }
    if (bioValue != null) {
      payload['bio'] = bioValue.value;
    }
    if (timezoneValue != null && timezoneValue.value.trim().isNotEmpty) {
      payload['timezone'] = timezoneValue.value;
    }
    if (removeAvatarValue?.value == true) {
      payload['remove_avatar'] = true;
    }

    final hasMediaMutation =
        avatarUpload != null || removeAvatarValue?.value == true;
    if (!hasMediaMutation) {
      await _dio.patch(
        '$_apiBaseUrl/v1/profile',
        data: payload,
        options: Options(headers: headers),
      );
      return;
    }

    final body = FormData.fromMap(
      <String, dynamic>{
        ...payload,
        '_method': 'PATCH',
        if (avatarUpload != null)
          'avatar': MultipartFile.fromBytes(
            avatarUpload.bytes,
            filename: avatarUpload.fileName,
            contentType: _resolveMediaType(
              avatarUpload.mimeType,
              avatarUpload.fileName,
            ),
          ),
      },
      ListFormat.multiCompatible,
    );

    await _dio.post(
      '$_apiBaseUrl/v1/profile',
      data: body,
      options: Options(headers: headers),
    );
  }

  MediaType _resolveMediaType(String? mimeType, String fileName) {
    final normalizedMimeType = mimeType?.trim();
    if (normalizedMimeType != null && normalizedMimeType.contains('/')) {
      final parts = normalizedMimeType.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
    }

    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('application', 'octet-stream');
  }
}
