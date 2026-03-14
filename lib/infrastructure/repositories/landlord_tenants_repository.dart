import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord/landlord_tenants_response_decoder.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LandlordTenantsRepository implements LandlordTenantsRepositoryContract {
  LandlordTenantsRepository({
    Dio? dio,
    LandlordAuthRepositoryContract? landlordAuthRepository,
    String? landlordOriginOverride,
  })  : _dio = dio ?? Dio(),
        _landlordAuthRepository = landlordAuthRepository,
        _landlordOriginOverride = landlordOriginOverride;

  final Dio _dio;
  final LandlordAuthRepositoryContract? _landlordAuthRepository;
  final String? _landlordOriginOverride;
  final LandlordTenantsResponseDecoder _responseDecoder =
      const LandlordTenantsResponseDecoder();

  LandlordAuthRepositoryContract get _authRepository =>
      _landlordAuthRepository ?? GetIt.I.get<LandlordAuthRepositoryContract>();

  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    final tenantsById = <String, LandlordTenantOption>{};
    var currentPage = 1;
    var lastPage = 1;

    do {
      final response = await _dio.get(
        '${_apiBaseUrl()}/v1/tenants',
        queryParameters: {
          'per_page': 100,
          'page': currentPage,
        },
        options: Options(headers: _buildHeaders()),
      );

      final responseMap = _responseDecoder.decodeRoot(response.data);
      final data = _responseDecoder.decodeTenantList(response.data);
      for (final tenantMap in data) {
        final tenant = _responseDecoder.mapTenantOption(
          tenantMap,
          landlordHost:
              _resolveHost(_landlordOriginOverride ?? BellugaConstants.landlordDomain),
        );
        if (tenant == null) {
          continue;
        }
        tenantsById[tenant.id] = tenant;
      }

      lastPage = _parseInt(responseMap['last_page']) ?? 1;
      currentPage += 1;
    } while (currentPage <= lastPage);

    final sorted = tenantsById.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  Map<String, String> _buildHeaders() {
    final token = _authRepository.token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  String _apiBaseUrl() {
    final raw =
        (_landlordOriginOverride ?? BellugaConstants.landlordDomain).trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      throw StateError(
        'Invalid LANDLORD_DOMAIN: "$raw". Expected a full origin.',
      );
    }
    final origin =
        uri.replace(path: '', query: null, fragment: null).toString();
    final normalized =
        origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
    return '$normalized/admin/api';
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _resolveHost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }
}
