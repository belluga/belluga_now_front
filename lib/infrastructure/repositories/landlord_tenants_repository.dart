import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
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

      final responseMap = _asMap(response.data);
      final data = _extractDataList(responseMap['data']);
      for (final tenantMap in data) {
        final tenant = _mapTenant(tenantMap);
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

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw Exception('Unexpected landlord tenants response shape.');
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

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  LandlordTenantOption? _mapTenant(
    Map<String, dynamic> tenantMap,
  ) {
    final slug = tenantMap['slug']?.toString().trim();
    final tenantName = tenantMap['name']?.toString().trim();
    final subdomain = tenantMap['subdomain']?.toString().trim();
    if (subdomain == null || subdomain.isEmpty) {
      // Tenant admin routing requires a valid tenant subdomain contract.
      return null;
    }

    final mainDomain = _resolveMainDomain(tenantMap);
    if (mainDomain == null || mainDomain.isEmpty) {
      return null;
    }

    final normalizedName = (tenantName == null || tenantName.isEmpty)
        ? (slug == null || slug.isEmpty ? mainDomain : slug)
        : tenantName;

    final tenantId = (slug == null || slug.isEmpty) ? mainDomain : slug;
    return LandlordTenantOption(
      id: tenantId,
      name: normalizedName,
      mainDomain: mainDomain,
    );
  }

  String? _resolveMainDomain(Map<String, dynamic> tenantMap) {
    final mainDomainField = _normalizeDomainEntry(
      tenantMap['main_domain'] ?? tenantMap['mainDomain'],
    );
    if (mainDomainField != null) {
      return mainDomainField;
    }

    final domains = _resolveDomainFromDomains(tenantMap['domains']);
    if (domains != null) {
      return domains;
    }

    // Prefer tenant web domain from subdomain over mobile app-domain aliases.
    final subdomain = tenantMap['subdomain']?.toString().trim();
    if (subdomain != null && subdomain.isNotEmpty) {
      final landlordHost =
          _resolveHost(_landlordOriginOverride ?? BellugaConstants.landlordDomain);
      if (landlordHost != null && landlordHost.isNotEmpty) {
        return '$subdomain.$landlordHost';
      }
    }

    return null;
  }

  String? _resolveDomainFromDomains(dynamic raw) {
    if (raw is! List) {
      return null;
    }

    String? firstValid;
    for (final entry in raw) {
      final normalized = _normalizeDomainEntry(entry);
      if (normalized == null) {
        continue;
      }
      firstValid ??= normalized;
      if (_isPrimaryDomainEntry(entry)) {
        return normalized;
      }
    }
    return firstValid;
  }

  bool _isPrimaryDomainEntry(dynamic entry) {
    if (entry is! Map) {
      return false;
    }
    final map = Map<String, dynamic>.from(entry);
    return _isTruthy(map['is_main']) ||
        _isTruthy(map['main']) ||
        _isTruthy(map['is_primary']) ||
        _isTruthy(map['primary']) ||
        _isTruthy(map['default']);
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  String? _normalizeDomainEntry(dynamic raw) {
    String? candidate;
    if (raw is String) {
      candidate = raw.trim();
    } else if (raw is Map) {
      candidate = raw['path']?.toString() ??
          raw['domain']?.toString() ??
          raw['url']?.toString() ??
          raw['href']?.toString();
      candidate = candidate?.trim();
    }

    if (candidate == null || candidate.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(
      candidate.contains('://') ? candidate : 'https://$candidate',
    );
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }

    return candidate;
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
