import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/json_object_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_settings_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_settings_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http_parser/http_parser.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminSettingsRepository
    implements TenantAdminSettingsRepositoryContract {
  TenantAdminSettingsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final JsonObjectResponseDecoder _jsonObjectResponseDecoder =
      const JsonObjectResponseDecoder();
  final RawJsonEnvelopeDecoder _envelopeDecoder =
      const RawJsonEnvelopeDecoder();
  final TenantAdminSettingsRequestEncoder _requestEncoder =
      const TenantAdminSettingsRequestEncoder();
  final TenantAdminSettingsResponseDecoder _responseDecoder =
      const TenantAdminSettingsResponseDecoder();
  final StreamValue<TenantAdminBrandingSettings?> _brandingSettingsStreamValue =
      StreamValue<TenantAdminBrandingSettings?>(defaultValue: null);
  int _brandingFetchSequence = 0;

  @override
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue =>
      _brandingSettingsStreamValue;

  @override
  void clearBrandingSettings() {
    _brandingSettingsStreamValue.addValue(null);
  }

  @override
  Future<TenantAdminMapUiSettings> fetchMapUiSettings() async {
    try {
      final response = await _dio.getUri(
        _buildTenantSettingsValuesUri(),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder.decodeMapUiSettings(
        response.data,
        tenantOrigin: _resolveTenantOriginUri(),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load map_ui settings');
    }
  }

  @override
  Future<TenantAdminMapUiSettings> updateMapUiSettings({
    required TenantAdminMapUiSettings settings,
  }) async {
    try {
      final response = await _dio.patchUri(
        _buildTenantSettingsValuesUri(namespace: 'map_ui'),
        data: _requestEncoder.encodeMapUiSettingsPatch(settings),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder.decodeMapUiSettings(
        response.data,
        tenantOrigin: _resolveTenantOriginUri(),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'update map_ui settings');
    }
  }

  @override
  Future<TenantAdminAppLinksSettings> fetchAppLinksSettings() async {
    try {
      final settingsFuture = _dio.getUri(
        _buildTenantSettingsValuesUri(),
        options: Options(headers: _buildHeaders()),
      );
      final appDomainIdentifiersFuture = _fetchAppDomainIdentifiers();

      final settingsResponse = await settingsFuture;
      final appDomainIdentifiers = await appDomainIdentifiersFuture;
      return _responseDecoder.decodeAppLinksSettings(
        settingsResponse.data,
        appDomainIdentifiers: appDomainIdentifiers,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load app_links settings');
    }
  }

  @override
  Future<TenantAdminAppLinksSettings> updateAppLinksSettings({
    required TenantAdminAppLinksSettings settings,
  }) async {
    try {
      var appDomainIdentifiers = await _fetchAppDomainIdentifiers();
      appDomainIdentifiers = await _syncAppDomainIdentifier(
        platform: 'android',
        desiredIdentifier: settings.androidAppIdentifier,
        currentIdentifiers: appDomainIdentifiers,
      );
      appDomainIdentifiers = await _syncAppDomainIdentifier(
        platform: 'ios',
        desiredIdentifier: settings.iosBundleId,
        currentIdentifiers: appDomainIdentifiers,
      );

      final response = await _dio.patchUri(
        _buildTenantSettingsValuesUri(namespace: 'app_links'),
        data: _requestEncoder.encodeAppLinksSettingsPatch(settings),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder.decodeAppLinksSettings(
        response.data,
        appDomainIdentifiers: appDomainIdentifiers,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'update app_links settings');
    }
  }

  @override
  Future<String> uploadMapFilterImage({
    required String key,
    required TenantAdminMediaUpload upload,
  }) async {
    try {
      final payload = FormData.fromMap({
        'key': key.trim(),
      });
      _appendUpload(
        payload,
        fieldName: 'image',
        upload: upload,
      );

      final response = await _dio.post(
        '$_apiBaseUrl/v1/media/map-filter-image',
        data: payload,
        options: Options(
          headers: _buildHeaders(),
          contentType: 'multipart/form-data',
        ),
      );
      return _responseDecoder.decodeMapFilterImageUpload(
        response.data,
        key: key,
        tenantOrigin: _resolveTenantOriginUri(),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'upload map filter image');
    }
  }

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
      return _responseDecoder.decodeFirebaseSettings(
        response.data,
      );
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
      final mapped = _responseDecoder.decodeFirebaseSettings(
        response.data,
      );
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
      return _responseDecoder.decodePushSettings(response.data);
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
      return _responseDecoder.decodeTelemetrySnapshot(response.data);
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
      return _responseDecoder.decodeTelemetrySnapshot(response.data);
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
      return _responseDecoder.decodeTelemetrySnapshot(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'delete telemetry integration');
    }
  }

  @override
  Future<TenantAdminBrandingSettings> fetchBrandingSettings() async {
    final requestedApiBaseUrl = _apiBaseUrl;
    final requestSequence = ++_brandingFetchSequence;
    try {
      final response = await _dio.getUri(
        _buildEnvironmentEndpointUri(
          apiBaseUrl: requestedApiBaseUrl,
        ),
        options: Options(
          headers: _buildBrandingReadHeaders(),
        ),
      );
      final payload = _envelopeDecoder.decodeEnvironmentMap(
        _jsonObjectResponseDecoder.decode(
          response.data,
          endpoint: response.requestOptions.uri,
        ),
        label: 'environment',
      );
      final settings = _responseDecoder.decodeBrandingFromEnvironment(
        payload,
        tenantOrigin: _resolveTenantOriginUri(
          apiBaseUrl: requestedApiBaseUrl,
        ),
      );
      if (_shouldPublishBrandingResponse(
        requestSequence: requestSequence,
        requestedApiBaseUrl: requestedApiBaseUrl,
      )) {
        _brandingSettingsStreamValue.addValue(settings);
      }
      return settings;
    } on DioException catch (error) {
      throw _wrapError(error, 'load branding settings');
    }
  }

  @override
  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  }) async {
    final requestedApiBaseUrl = _apiBaseUrl;
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
        '$requestedApiBaseUrl/v1/branding/update',
        data: payload,
        options: Options(
          headers: _buildHeaders(),
          contentType: 'multipart/form-data',
        ),
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Failed to update branding settings [status=${response.statusCode}]',
        );
      }
      try {
        return await fetchBrandingSettings();
      } catch (_) {
        final optimistic = _buildOptimisticBrandingSettings(
          input: input,
          apiBaseUrl: requestedApiBaseUrl,
        );
        if (_isBrandingScopeCurrent(requestedApiBaseUrl)) {
          _brandingSettingsStreamValue.addValue(optimistic);
        }
        return optimistic;
      }
    } on DioException catch (error) {
      throw _wrapError(error, 'update branding settings');
    }
  }

  Uri _buildEnvironmentEndpointUri({String? apiBaseUrl}) {
    final origin = _resolveTenantOriginUri(
      apiBaseUrl: apiBaseUrl,
    );
    return origin.replace(
      path: '/api/v1/environment',
      queryParameters: {
        '_ts': DateTime.now().microsecondsSinceEpoch.toString(),
      },
    );
  }

  Uri _buildTenantSettingsValuesUri({
    String? namespace,
  }) {
    final origin = _resolveTenantOriginUri();
    final encodedNamespace = namespace == null || namespace.trim().isEmpty
        ? null
        : Uri.encodeComponent(namespace.trim());
    final path = encodedNamespace == null
        ? '/admin/api/v1/settings/values'
        : '/admin/api/v1/settings/values/$encodedNamespace';
    return origin.replace(path: path);
  }

  Uri _buildTenantAppDomainsUri() {
    final origin = _resolveTenantOriginUri();
    return origin.replace(path: '/admin/api/v1/appdomains');
  }

  Uri _resolveTenantOriginUri({String? apiBaseUrl}) {
    final adminBaseUri = _parseToOriginUri(apiBaseUrl ?? _apiBaseUrl);
    if (adminBaseUri != null) {
      return adminBaseUri;
    }
    throw Exception(
      'Could not resolve tenant-scoped admin origin for branding settings.',
    );
  }

  bool _shouldPublishBrandingResponse({
    required int requestSequence,
    required String requestedApiBaseUrl,
  }) {
    if (requestSequence != _brandingFetchSequence) {
      return false;
    }
    return _isBrandingScopeCurrent(requestedApiBaseUrl);
  }

  bool _isBrandingScopeCurrent(String requestedApiBaseUrl) {
    try {
      return requestedApiBaseUrl == _apiBaseUrl;
    } catch (_) {
      return false;
    }
  }

  TenantAdminBrandingSettings _buildOptimisticBrandingSettings({
    required TenantAdminBrandingUpdateInput input,
    required String apiBaseUrl,
  }) {
    final current = _brandingSettingsStreamValue.value;
    final origin = _parseToOriginUri(apiBaseUrl);
    return TenantAdminBrandingSettings(
      tenantName: input.tenantName.trim(),
      brightnessDefault: input.brightnessDefault,
      primarySeedColor: input.primarySeedColor.trim().toUpperCase(),
      secondarySeedColor: input.secondarySeedColor.trim().toUpperCase(),
      lightLogoUrl: input.lightLogoUpload != null
          ? origin == null
              ? current?.lightLogoUrl
              : _buildTenantAssetUrl(origin, 'logo-light.png')
          : current?.lightLogoUrl,
      darkLogoUrl: input.darkLogoUpload != null
          ? origin == null
              ? current?.darkLogoUrl
              : _buildTenantAssetUrl(origin, 'logo-dark.png')
          : current?.darkLogoUrl,
      lightIconUrl: input.lightIconUpload != null
          ? origin == null
              ? current?.lightIconUrl
              : _buildTenantAssetUrl(origin, 'icon-light.png')
          : current?.lightIconUrl,
      darkIconUrl: input.darkIconUpload != null
          ? origin == null
              ? current?.darkIconUrl
              : _buildTenantAssetUrl(origin, 'icon-dark.png')
          : current?.darkIconUrl,
      faviconUrl: input.faviconUpload != null
          ? origin == null
              ? current?.faviconUrl
              : _buildTenantAssetUrl(origin, 'favicon.ico')
          : current?.faviconUrl,
      pwaIconUrl: current?.pwaIconUrl,
    );
  }

  Uri? _parseToOriginUri(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final parsed = Uri.tryParse(normalized);
    if (parsed == null || parsed.host.trim().isEmpty) {
      return null;
    }
    return Uri(
      scheme: parsed.scheme.isEmpty ? 'https' : parsed.scheme,
      host: parsed.host.trim(),
      port: parsed.hasPort ? parsed.port : null,
    );
  }

  String _buildTenantAssetUrl(Uri origin, String assetName) {
    return origin
        .replace(path: '/$assetName', queryParameters: null)
        .toString();
  }

  Map<String, String> _buildBrandingReadHeaders() {
    return {
      'Accept': 'application/json',
    };
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

  Exception _wrapError(DioException error, String label) {
    return tenantAdminWrapRepositoryError(error, label);
  }

  Future<TenantAdminAppDomainIdentifiers> _fetchAppDomainIdentifiers() async {
    final response = await _dio.getUri(
      _buildTenantAppDomainsUri(),
      options: Options(headers: _buildHeaders()),
    );
    return _responseDecoder.decodeAppDomainIdentifiers(response.data);
  }

  Future<TenantAdminAppDomainIdentifiers> _syncAppDomainIdentifier({
    required String platform,
    required String? desiredIdentifier,
    required TenantAdminAppDomainIdentifiers currentIdentifiers,
  }) async {
    final normalizedDesired = desiredIdentifier?.trim();
    final current = platform == 'android'
        ? currentIdentifiers.androidAppIdentifier
        : currentIdentifiers.iosBundleId;

    if (normalizedDesired == null || normalizedDesired.isEmpty) {
      if (current == null || current.trim().isEmpty) {
        return currentIdentifiers;
      }
      return _removeAppDomainIdentifier(platform: platform);
    }

    return _upsertAppDomainIdentifier(
      platform: platform,
      identifier: normalizedDesired,
    );
  }

  Future<TenantAdminAppDomainIdentifiers> _upsertAppDomainIdentifier({
    required String platform,
    required String identifier,
  }) async {
    final response = await _dio.postUri(
      _buildTenantAppDomainsUri(),
      data: {
        'platform': platform,
        'identifier': identifier,
      },
      options: Options(headers: _buildHeaders()),
    );
    return _responseDecoder.decodeAppDomainIdentifiers(response.data);
  }

  Future<TenantAdminAppDomainIdentifiers> _removeAppDomainIdentifier({
    required String platform,
  }) async {
    final response = await _dio.deleteUri(
      _buildTenantAppDomainsUri(),
      data: {
        'platform': platform,
      },
      options: Options(headers: _buildHeaders()),
    );
    return _responseDecoder.decodeAppDomainIdentifiers(response.data);
  }
}
