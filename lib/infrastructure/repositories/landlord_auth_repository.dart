import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stream_value/main.dart';

class LandlordAuthRepository implements LandlordAuthRepositoryContract {
  LandlordAuthRepository({Dio? dio}) : _dio = dio;

  static const String _tokenStorageKey = 'landlord_token';
  static const String _userIdStorageKey = 'landlord_user_id';

  final StreamValue<String?> _tokenStreamValue = StreamValue<String?>();
  final StreamValue<String?> _userIdStreamValue = StreamValue<String?>();
  Dio? _dio;

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  @override
  bool get hasValidSession => token.isNotEmpty;

  @override
  String get token => _tokenStreamValue.value ?? '';

  Future<Dio> _resolveDio() async {
    if (_dio != null) {
      return _dio!;
    }
    _dio = Dio(
      BaseOptions(
        baseUrl:
            '${BellugaConstants.apiScheme}://${BellugaConstants.landlordDomain}/admin/api',
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
      final data = _extractDataMap(response.data);
      final token = data['token']?.toString() ?? '';
      final user = data['user'];
      final userId =
          user is Map<String, dynamic> ? user['id']?.toString() : null;
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
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final userId = data['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          _userIdStreamValue.addValue(userId);
          await storage.write(key: _userIdStorageKey, value: userId);
        }
      }
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
}

Map<String, dynamic> _extractDataMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
  }
  throw Exception('Unexpected landlord auth response shape.');
}

String _responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}
