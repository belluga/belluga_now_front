import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminSelectedTenantRepository
    implements
        TenantAdminSelectedTenantRepositoryContract,
        TenantAdminTenantScopeContract,
        Disposable {
  final StreamValue<List<LandlordTenantOption>> _availableTenantsStreamValue =
      StreamValue<List<LandlordTenantOption>>(defaultValue: const []);
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<LandlordTenantOption?> _selectedTenantStreamValue =
      StreamValue<LandlordTenantOption?>(defaultValue: null);

  @override
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue =>
      _availableTenantsStreamValue;

  @override
  List<LandlordTenantOption> get availableTenants =>
      _availableTenantsStreamValue.value;

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  StreamValue<LandlordTenantOption?> get selectedTenantStreamValue =>
      _selectedTenantStreamValue;

  @override
  LandlordTenantOption? get selectedTenant => _selectedTenantStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      resolveTenantAdminBaseUrl(selectedTenantDomain ?? '');

  @override
  void setAvailableTenants(List<LandlordTenantOption> tenants) {
    final normalized = _normalizeTenants(tenants);
    _availableTenantsStreamValue.addValue(normalized);
    _syncSelectionWithAvailableTenants(normalized);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    final normalized = _normalizeTenantDomain(tenantDomain);
    if (normalized == null) {
      return;
    }
    _selectedTenantDomainStreamValue.addValue(normalized);
    _selectedTenantStreamValue.addValue(
      _resolveTenantByDomain(
        tenants: availableTenants,
        tenantDomain: normalized,
      ),
    );
  }

  @override
  void selectTenant(LandlordTenantOption tenant) {
    final normalized = _normalizeTenantDomain(tenant.mainDomain);
    if (normalized == null) {
      return;
    }
    _selectedTenantDomainStreamValue.addValue(normalized);
    _selectedTenantStreamValue.addValue(
      _resolveTenantByDomain(
            tenants: availableTenants,
            tenantDomain: normalized,
          ) ??
          tenant,
    );
  }

  @override
  void clearSelectedTenant() {
    _selectedTenantDomainStreamValue.addValue(null);
    _selectedTenantStreamValue.addValue(null);
  }

  @override
  void clearSelectedTenantDomain() {
    clearSelectedTenant();
  }

  @override
  void onDispose() {
    _availableTenantsStreamValue.dispose();
    _selectedTenantDomainStreamValue.dispose();
    _selectedTenantStreamValue.dispose();
  }

  List<LandlordTenantOption> _normalizeTenants(List<LandlordTenantOption> raw) {
    final tenantsByDomain = <String, LandlordTenantOption>{};
    for (final tenant in raw) {
      final normalizedDomain = _normalizeTenantDomain(tenant.mainDomain);
      final identity = _domainIdentity(normalizedDomain);
      if (normalizedDomain == null || identity == null) {
        continue;
      }
      tenantsByDomain[identity] = LandlordTenantOption(
        id: tenant.id,
        name: tenant.name,
        mainDomain: normalizedDomain,
      );
    }

    final tenants = tenantsByDomain.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return tenants;
  }

  void _syncSelectionWithAvailableTenants(List<LandlordTenantOption> tenants) {
    final normalizedSelected = _normalizeTenantDomain(selectedTenantDomain);
    if (tenants.isEmpty) {
      if (normalizedSelected == null) {
        _selectedTenantStreamValue.addValue(null);
      }
      return;
    }

    if (tenants.length == 1) {
      final single = tenants.first;
      if (normalizedSelected != null &&
          _domainsMatch(normalizedSelected, single.mainDomain)) {
        _selectedTenantStreamValue.addValue(single);
      } else {
        selectTenant(single);
      }
      return;
    }

    if (normalizedSelected == null) {
      _selectedTenantStreamValue.addValue(null);
      return;
    }

    final selected = _resolveTenantByDomain(
      tenants: tenants,
      tenantDomain: normalizedSelected,
    );
    if (selected == null) {
      clearSelectedTenant();
      return;
    }
    _selectedTenantStreamValue.addValue(selected);
  }

  LandlordTenantOption? _resolveTenantByDomain({
    required List<LandlordTenantOption> tenants,
    required String tenantDomain,
  }) {
    final normalizedTarget = _normalizeTenantDomain(tenantDomain);
    if (normalizedTarget == null) {
      return null;
    }
    for (final tenant in tenants) {
      if (_domainsMatch(tenant.mainDomain, normalizedTarget)) {
        return tenant;
      }
    }
    return null;
  }

  String? _domainIdentity(String? raw) {
    final parsed = _parseTenantDomain(raw);
    return parsed?.host;
  }

  bool _domainsMatch(String rawLeft, String rawRight) {
    final left = _parseTenantDomain(rawLeft);
    final right = _parseTenantDomain(rawRight);
    if (left == null || right == null) {
      return rawLeft.trim().toLowerCase() == rawRight.trim().toLowerCase();
    }
    if (left.host != right.host) {
      return false;
    }
    if (!left.hasPort || !right.hasPort) {
      return true;
    }
    return left.port == right.port;
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final hasExplicitScheme = trimmed.contains('://');
    final uri = Uri.tryParse(hasExplicitScheme ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      final host = uri.host.trim().toLowerCase();
      if (hasExplicitScheme) {
        final scheme = uri.scheme.toLowerCase();
        if (scheme != 'http' && scheme != 'https') {
          return null;
        }
        return Uri(
          scheme: scheme,
          host: host,
          port: uri.hasPort ? uri.port : null,
        ).toString();
      }
      if (uri.hasPort) {
        return '$host:${uri.port}';
      }
      return host;
    }
    return trimmed;
  }

  _TenantDomain? _parseTenantDomain(String? raw) {
    final normalized = _normalizeTenantDomain(raw);
    if (normalized == null) {
      return null;
    }
    final parsed = Uri.tryParse(
      normalized.contains('://') ? normalized : 'https://$normalized',
    );
    if (parsed == null || parsed.host.trim().isEmpty) {
      return null;
    }
    return _TenantDomain(
      host: parsed.host.trim().toLowerCase(),
      hasPort: parsed.hasPort,
      port: parsed.hasPort ? parsed.port : null,
    );
  }
}

class _TenantDomain {
  const _TenantDomain({
    required this.host,
    required this.hasPort,
    required this.port,
  });

  final String host;
  final bool hasPort;
  final int? port;
}
