import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/landlord_public_instances_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/environment_origin_normalizer.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';

class LandlordKnownPublicInstancesBackend
    implements LandlordPublicInstancesBackendContract {
  LandlordKnownPublicInstancesBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const List<String> _knownTenantSubdomains = ['guarappari'];
  static const Map<String, String> _productionCustomDomains = {
    'guarappari': 'guarappari.com.br',
  };

  final Dio _dio;

  @override
  Future<List<AppDataDTO>> fetchFeaturedInstanceEnvironments({
    required String landlordOrigin,
  }) async {
    final instances = <AppDataDTO>[];
    for (final origin in _resolveKnownTenantOrigins(landlordOrigin)) {
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

  List<String> _resolveKnownTenantOrigins(String landlordOrigin) {
    final normalizedLandlordOrigin = _normalizeOrigin(landlordOrigin);
    final landlordUri = Uri.parse(normalizedLandlordOrigin);
    final scheme = landlordUri.scheme.isEmpty ? 'https' : landlordUri.scheme;
    final landlordHost = landlordUri.host.trim().toLowerCase();

    return _knownTenantSubdomains
        .map((slug) => _resolveTenantOriginForHost(
              slug: slug,
              landlordHost: landlordHost,
              scheme: scheme,
            ))
        .toList(growable: false);
  }

  String _resolveTenantOriginForHost({
    required String slug,
    required String landlordHost,
    required String scheme,
  }) {
    if (landlordHost == 'booraagora.com.br') {
      final customDomain = _productionCustomDomains[slug];
      if (customDomain != null && customDomain.trim().isNotEmpty) {
        return '$scheme://${customDomain.trim()}';
      }
    }

    return '$scheme://$slug.$landlordHost';
  }
}
