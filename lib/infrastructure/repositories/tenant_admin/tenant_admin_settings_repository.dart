import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes';
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
