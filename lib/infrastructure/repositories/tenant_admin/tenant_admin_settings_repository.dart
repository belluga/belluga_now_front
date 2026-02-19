import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http_parser/http_parser.dart';

class TenantAdminSettingsRepository
    implements TenantAdminSettingsRepositoryContract {
  TenantAdminSettingsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/settings/firebase',
        options: Options(headers: _buildHeaders()),
      );
      final payload = _extractDataMap(response.data);
      return _mapFirebaseSettings(payload);
    } on DioException catch (error) {
      throw _wrapError(error, 'load firebase settings');
    }
  }

  @override
  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  }) async {
    try {
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/settings/firebase',
        data: {'firebase': settings.toJson()},
        options: Options(headers: _buildHeaders()),
      );
      final payload = _extractDataMap(response.data);
      final mapped = _mapFirebaseSettings(payload);
      if (mapped == null) {
        throw Exception('Firebase settings response is empty.');
      }
      return mapped;
    } on DioException catch (error) {
      throw _wrapError(error, 'update firebase settings');
    }
  }

  @override
  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  }) async {
    try {
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/settings/push',
        data: {'push': settings.toJson()},
        options: Options(headers: _buildHeaders()),
      );
      final payload = _extractDataMap(response.data);
      return _mapPushSettings(payload);
    } on DioException catch (error) {
      throw _wrapError(error, 'update push settings');
    }
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/settings/telemetry',
        options: Options(headers: _buildHeaders()),
      );
      return _mapTelemetrySnapshot(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'load telemetry settings');
    }
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/settings/telemetry',
        data: integration.toUpsertPayload(),
        options: Options(headers: _buildHeaders()),
      );
      return _mapTelemetrySnapshot(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'save telemetry integration');
    }
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required String type,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.trim());
      final response = await _dio.delete(
        '$_apiBaseUrl/v1/settings/telemetry/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
      return _mapTelemetrySnapshot(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'delete telemetry integration');
    }
  }

  @override
  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  }) async {
    try {
      final payload = FormData.fromMap({
        'name': input.tenantName.trim(),
        'theme_data_settings[brightness_default]':
            input.brightnessDefault.rawValue,
        'theme_data_settings[primary_seed_color]': input.primarySeedColor,
        'theme_data_settings[secondary_seed_color]': input.secondarySeedColor,
      });

      _appendUpload(
        payload,
        fieldName: 'logo_settings[light_logo_uri]',
        upload: input.lightLogoUpload,
      );
      _appendUpload(
        payload,
        fieldName: 'logo_settings[dark_logo_uri]',
        upload: input.darkLogoUpload,
      );
      _appendUpload(
        payload,
        fieldName: 'logo_settings[light_icon_uri]',
        upload: input.lightIconUpload,
      );
      _appendUpload(
        payload,
        fieldName: 'logo_settings[dark_icon_uri]',
        upload: input.darkIconUpload,
      );
      _appendUpload(
        payload,
        fieldName: 'logo_settings[favicon_uri]',
        upload: input.faviconUpload,
      );
      _appendUpload(
        payload,
        fieldName: 'logo_settings[pwa_icon]',
        upload: input.pwaIconUpload,
      );

      final response = await _dio.post(
        '$_apiBaseUrl/v1/branding/update',
        data: payload,
        options: Options(
          headers: _buildHeaders(),
          contentType: 'multipart/form-data',
        ),
      );
      return _mapBrandingSettings(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update branding settings');
    }
  }

  Map<String, dynamic> _extractDataMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (raw.containsKey('data')) {
        return const {};
      }
      return raw;
    }
    throw Exception('Unexpected settings response shape.');
  }

  TenantAdminTelemetrySettingsSnapshot _mapTelemetrySnapshot(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected telemetry response shape.');
    }

    final integrations =
        _extractDataList(raw['data']).map(_mapTelemetry).toList(
              growable: false,
            );
    final availableEvents = _extractStringList(raw['available_events']);
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: integrations,
      availableEvents: availableEvents,
    );
  }

  List<Map<String, dynamic>> _extractDataList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    return const [];
  }

  List<String> _extractStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((entry) => entry.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  TenantAdminFirebaseSettings? _mapFirebaseSettings(Map<String, dynamic> map) {
    final apiKey = map['apiKey']?.toString().trim();
    final appId = map['appId']?.toString().trim();
    final projectId = map['projectId']?.toString().trim();
    final sender = map['messagingSenderId']?.toString().trim();
    final storageBucket = map['storageBucket']?.toString().trim();
    if (apiKey == null ||
        appId == null ||
        projectId == null ||
        sender == null ||
        storageBucket == null ||
        apiKey.isEmpty ||
        appId.isEmpty ||
        projectId.isEmpty ||
        sender.isEmpty ||
        storageBucket.isEmpty) {
      return null;
    }
    return TenantAdminFirebaseSettings(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: sender,
      storageBucket: storageBucket,
    );
  }

  TenantAdminPushSettings _mapPushSettings(Map<String, dynamic> map) {
    final ttlDays = _parseInt(map['max_ttl_days']) ?? 30;
    final throttlesRaw = map['throttles'];
    final throttles = throttlesRaw is Map<String, dynamic>
        ? throttlesRaw
        : const <String, dynamic>{};
    final maxPerMinute = _parseInt(throttles['max_per_minute']) ?? 60;
    final maxPerHour = _parseInt(throttles['max_per_hour']) ?? 600;
    return TenantAdminPushSettings(
      maxTtlDays: ttlDays,
      maxPerMinute: maxPerMinute,
      maxPerHour: maxPerHour,
    );
  }

  TenantAdminTelemetryIntegration _mapTelemetry(Map<String, dynamic> map) {
    final type = map['type']?.toString().trim() ?? '';
    final trackAll = _parseBool(map['track_all']);
    final events = _extractStringList(map['events']);
    final token = map['token']?.toString().trim();
    final url = map['url']?.toString().trim();

    final extra = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key == 'type' ||
          entry.key == 'track_all' ||
          entry.key == 'events' ||
          entry.key == 'token' ||
          entry.key == 'url') {
        continue;
      }
      extra[entry.key] = entry.value;
    }

    return TenantAdminTelemetryIntegration(
      type: type,
      trackAll: trackAll,
      events: events,
      token: token == null || token.isEmpty ? null : token,
      url: url == null || url.isEmpty ? null : url,
      extra: extra.isEmpty ? null : extra,
    );
  }

  TenantAdminBrandingSettings _mapBrandingSettings(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected branding response shape.');
    }
    final brandingRaw = raw['branding_data'];
    if (brandingRaw is! Map<String, dynamic>) {
      throw Exception('Unexpected branding_data response shape.');
    }

    final themeSettingsRaw = brandingRaw['theme_data_settings'];
    final themeSettings = themeSettingsRaw is Map<String, dynamic>
        ? themeSettingsRaw
        : const <String, dynamic>{};
    final logoSettingsRaw = brandingRaw['logo_settings'];
    final logoSettings = logoSettingsRaw is Map<String, dynamic>
        ? logoSettingsRaw
        : const <String, dynamic>{};
    final pwaIconRaw = brandingRaw['pwa_icon'];
    final pwaIcon = pwaIconRaw is Map<String, dynamic>
        ? pwaIconRaw
        : const <String, dynamic>{};

    return TenantAdminBrandingSettings(
      tenantName: '',
      brightnessDefault: TenantAdminBrandingBrightness.fromRaw(
        themeSettings['brightness_default']?.toString(),
      ),
      primarySeedColor:
          themeSettings['primary_seed_color']?.toString().trim() ?? '#4FA0E3',
      secondarySeedColor:
          themeSettings['secondary_seed_color']?.toString().trim() ?? '#E80D5D',
      lightLogoUrl: _normalizeOptionalString(logoSettings['light_logo_uri']),
      darkLogoUrl: _normalizeOptionalString(logoSettings['dark_logo_uri']),
      lightIconUrl: _normalizeOptionalString(logoSettings['light_icon_uri']),
      darkIconUrl: _normalizeOptionalString(logoSettings['dark_icon_uri']),
      faviconUrl: _normalizeOptionalString(logoSettings['favicon_uri']),
      pwaIconUrl: _normalizeOptionalString(
        pwaIcon['icon512_uri'] ?? pwaIcon['source_uri'],
      ),
    );
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }

  void _appendUpload(
    FormData formData, {
    required String fieldName,
    required TenantAdminMediaUpload? upload,
  }) {
    if (upload == null) {
      return;
    }
    formData.files.add(
      MapEntry(
        fieldName,
        MultipartFile.fromBytes(
          upload.bytes,
          filename: upload.fileName,
          contentType: _resolveMediaType(upload),
        ),
      ),
    );
  }

  MediaType _resolveMediaType(TenantAdminMediaUpload upload) {
    final mime = upload.mimeType?.trim();
    if (mime == null || mime.isEmpty) {
      return MediaType('application', 'octet-stream');
    }
    final parts = mime.split('/');
    if (parts.length != 2) {
      return MediaType('application', 'octet-stream');
    }
    return MediaType(parts[0], parts[1]);
  }

  String? _normalizeOptionalString(dynamic raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.toString().trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Exception _wrapError(DioException error, String label) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $label [status=$status] (${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }
}
