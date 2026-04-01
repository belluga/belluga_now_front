import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';

class LandlordTenantsResponseDecoder {
  const LandlordTenantsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  Map<String, dynamic> decodeRoot(Object? rawResponse) {
    return _envelopeDecoder.decodeRootMap(
      rawResponse,
      label: 'landlord tenants',
    );
  }

  List<Map<String, dynamic>> decodeTenantList(Object? rawResponse) {
    return _envelopeDecoder.decodeListMap(
      rawResponse,
      label: 'landlord tenants',
    );
  }

  LandlordTenantOption? mapTenantOption(
    Map<String, dynamic> tenantMap, {
    required String? landlordHost,
  }) {
    final slug = tenantMap['slug']?.toString().trim();
    final tenantName = tenantMap['name']?.toString().trim();
    final subdomain = tenantMap['subdomain']?.toString().trim();
    if (subdomain == null || subdomain.isEmpty) {
      // Tenant admin routing requires a valid tenant subdomain contract.
      return null;
    }

    final mainDomain = _resolveMainDomain(
      tenantMap,
      landlordHost: landlordHost,
    );
    if (mainDomain == null || mainDomain.isEmpty) {
      return null;
    }

    final normalizedName = (tenantName == null || tenantName.isEmpty)
        ? (slug == null || slug.isEmpty ? mainDomain : slug)
        : tenantName;

    final tenantId = (slug == null || slug.isEmpty) ? mainDomain : slug;
    return landlordTenantOptionFromRaw(
      id: tenantId,
      name: normalizedName,
      mainDomain: mainDomain,
    );
  }

  String? _resolveMainDomain(
    Map<String, dynamic> tenantMap, {
    required String? landlordHost,
  }) {
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
    if (subdomain != null &&
        subdomain.isNotEmpty &&
        landlordHost != null &&
        landlordHost.isNotEmpty) {
      return '$subdomain.$landlordHost';
    }

    return null;
  }

  String? _resolveDomainFromDomains(Object? raw) {
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

  bool _isPrimaryDomainEntry(Object? entry) {
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

  bool _isTruthy(Object? value) {
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

  String? _normalizeDomainEntry(Object? raw) {
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
}
