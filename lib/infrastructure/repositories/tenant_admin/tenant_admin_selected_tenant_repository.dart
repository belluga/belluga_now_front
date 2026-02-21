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
      if (normalizedDomain == null) {
        continue;
      }
      tenantsByDomain[normalizedDomain] = LandlordTenantOption(
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
      selectTenant(tenants.first);
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
      if (_normalizeTenantDomain(tenant.mainDomain) == normalizedTarget) {
        return tenant;
      }
    }
    return null;
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }
}
