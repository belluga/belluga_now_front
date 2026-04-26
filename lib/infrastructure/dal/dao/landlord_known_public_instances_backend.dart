import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/landlord_public_instances_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/environment_origin_normalizer.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';

class LandlordKnownPublicInstancesBackend
    implements LandlordPublicInstancesBackendContract {
  LandlordKnownPublicInstancesBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const List<String> _knownTenantOrigins = [
    'https://guarappari.com.br',
  ];

  final Dio _dio;

  @override
  Future<List<AppDataDTO>> fetchFeaturedInstanceEnvironments() async {
    final instances = <AppDataDTO>[];
    for (final origin in _knownTenantOrigins) {
      instances.add(await _fetchEnvironment(origin));
    }
    return instances;
  }

  Future<AppDataDTO> _fetchEnvironment(String origin) async {
    final normalizedOrigin = _normalizeOrigin(origin);
    final response = await _dio.getUri<dynamic>(
      Uri.parse('$normalizedOrigin/api/v1/environment'),
      options: Options(
        headers: const <String, String>{
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final payload = _extractPayload(response.data);
    return AppDataDTO.fromJson(
      normalizeEnvironmentOrigins(
        payload,
        bootstrapBaseUrl: normalizedOrigin,
      ),
    );
  }

  Map<String, dynamic> _extractPayload(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      return data is Map<String, dynamic> ? data : raw;
    }
    if (raw is Map) {
      return _extractPayload(Map<String, dynamic>.from(raw));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      return _extractPayload(decoded);
    }
    throw StateError('Unexpected public tenant environment response shape.');
  }

  String _normalizeOrigin(String raw) {
    final origin = Uri.parse(raw.trim()).replace(
      path: '',
      query: null,
      fragment: null,
    );
    final value = origin.toString();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
