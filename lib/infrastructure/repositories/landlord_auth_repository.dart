import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord/landlord_auth_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';

class LandlordAuthRepository implements LandlordAuthRepositoryContract {
  LandlordAuthRepository({
    Dio? dio,
    Dio Function(String baseUrl)? dioFactory,
  })  : _dio = dio,
        _dioFactory = dioFactory;

  static const String _tokenStorageKey = 'landlord_token';
  static const String _userIdStorageKey = 'landlord_user_id';

  final StreamValue<String?> _tokenStreamValue = StreamValue<String?>();
  final StreamValue<String?> _userIdStreamValue = StreamValue<String?>();
  final LandlordAuthResponseDecoder _responseDecoder =
      const LandlordAuthResponseDecoder();
  Dio? _dio;
  final Dio Function(String baseUrl)? _dioFactory;

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  @override
  bool get hasValidSession => token.isNotEmpty;

  @override
  String get token => _tokenStreamValue.value ?? '';

  Future<Dio> _resolveDio() async {
    if (_dio != null) {
      return _dio!;
    }
    final adminApiBaseUrl = _resolveAdminApiBaseUrl();
    final dioFactory = _dioFactory;
    _dio = dioFactory != null
        ? dioFactory(adminApiBaseUrl)
        : Dio(
            BaseOptions(
              baseUrl: adminApiBaseUrl,
            ),
          );
    return _dio!;
  }

  @override
  Future<void> init() async {
    await _loadFromStorage();
    if (token.isEmpty) {
      return;
    }
    try {
      await _tokenValidate();
      await _fetchProfile();
    } catch (_) {
      await _clearSession();
    }
  }

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    final deviceName = await _resolveDeviceName();
    final payload = {
      'email': email,
      'password': password,
      'device_name': deviceName,
    };
    final dio = await _resolveDio();
    try {
      final response = await dio.post('/v1/auth/login', data: payload);
      final loginPayload = _responseDecoder.decodeLogin(response.data);
      final token = loginPayload.token;
      final userId = loginPayload.userId;
      if (token.isEmpty) {
        throw Exception('Landlord token missing.');
      }
      _tokenStreamValue.addValue(token);
      await storage.write(key: _tokenStorageKey, value: token);
      if (userId != null && userId.isNotEmpty) {
        _userIdStreamValue.addValue(userId);
        await storage.write(key: _userIdStorageKey, value: userId);
      }
      await _tokenValidate();
      await _fetchProfile();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Landlord login failed '
        '[${_responseLabel(statusCode)}]: '
        '${data ?? e.message}',
      );
    }
  }

  @override
  Future<void> logout() async {
    if (token.isEmpty) {
      return;
    }
    final dio = await _resolveDio();
    try {
      await dio.post(
        '/v1/auth/logout',
        data: {'device': await _resolveDeviceName()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // Ignore logout failures; clear local session regardless.
    }
    await _clearSession();
  }

  Future<void> _tokenValidate() async {
    final dio = await _resolveDio();
    await dio.get(
      '/v1/auth/token_validate',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> _fetchProfile() async {
    final dio = await _resolveDio();
    final response = await dio.get(
      '/v1/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final userId = _responseDecoder.decodeProfileUserId(response.data);
    if (userId != null && userId.isNotEmpty) {
      _userIdStreamValue.addValue(userId);
      await storage.write(key: _userIdStorageKey, value: userId);
    }
  }

  Future<void> _loadFromStorage() async {
    final storedToken = await storage.read(key: _tokenStorageKey);
    final storedUserId = await storage.read(key: _userIdStorageKey);
    _tokenStreamValue.addValue(storedToken);
    _userIdStreamValue.addValue(storedUserId);
  }

  Future<void> _clearSession() async {
    _tokenStreamValue.addValue(null);
    _userIdStreamValue.addValue(null);
    await storage.delete(key: _tokenStorageKey);
    await storage.delete(key: _userIdStorageKey);
  }

  Future<String> _resolveDeviceName() async {
    final deviceId = await AuthRepository.ensureDeviceId();
    final platformLabel = _resolvePlatformLabel();
    final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;
    return 'boora-$platformLabel-$shortId';
  }

  String _resolvePlatformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
    }
  }

  String _resolveAdminApiBaseUrl() {
    final appDataAdminUrl = _resolveAppDataAdminApiBaseUrl();
    if (appDataAdminUrl != null) {
      return appDataAdminUrl;
    }

    final runtimeAdminUrl = _resolveRuntimeAdminApiBaseUrl();
    if (runtimeAdminUrl != null) {
      return runtimeAdminUrl;
    }

    throw StateError(
      'Failed to resolve landlord auth admin base URL. '
      'Root cause: runtime app context is unavailable (AppData/BackendContext).',
    );
  }

  String? _resolveAppDataAdminApiBaseUrl() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }

    final rawHref = GetIt.I.get<AppData>().href.trim();
    if (rawHref.isEmpty) {
      return null;
    }

    final hrefUri = Uri.tryParse(rawHref);
    if (hrefUri == null || !hrefUri.hasScheme || hrefUri.host.trim().isEmpty) {
      return null;
    }

    return hrefUri.resolve('/admin/api').toString();
  }

  String? _resolveRuntimeAdminApiBaseUrl() {
    if (!GetIt.I.isRegistered<BackendContext>()) {
      return null;
    }

    final raw = GetIt.I.get<BackendContext>().adminUrl.trim();
    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return null;
    }

    final normalized = uri.replace(query: null, fragment: null).toString();
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }
}

String _responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}
