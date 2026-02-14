import 'dart:async';

import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminShellController implements Disposable {
  TenantAdminShellController({
    AdminModeRepositoryContract? adminModeRepository,
    AppDataRepositoryContract? appDataRepository,
    LandlordTenantsRepositoryContract? landlordTenantsRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _landlordTenantsRepository = landlordTenantsRepository ??
            GetIt.I.get<LandlordTenantsRepositoryContract>(),
        _tenantScope =
            tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>();

  final AdminModeRepositoryContract _adminModeRepository;
  final AppDataRepositoryContract _appDataRepository;
  final LandlordTenantsRepositoryContract _landlordTenantsRepository;
  final TenantAdminTenantScopeContract _tenantScope;

  final StreamValue<List<LandlordTenantOption>> availableTenantsStreamValue =
      StreamValue<List<LandlordTenantOption>>(defaultValue: const []);
  final StreamValue<bool> isTenantSelectionResolvingStreamValue =
      StreamValue<bool>(defaultValue: false);

  StreamValue<AdminMode> get modeStreamValue =>
      _adminModeRepository.modeStreamValue;
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _tenantScope.selectedTenantDomainStreamValue;
  String? get selectedTenantDomain => _tenantScope.selectedTenantDomain;

  Future<void> switchToUserMode() => _adminModeRepository.setUserMode();

  void init() {
    final bootstrapTenants = _resolveBootstrapTenants();
    _setAvailableTenants(bootstrapTenants);

    final hasSelectedTenant = _hasSelectedTenantDomain();
    final shouldResolveBeforeShowingPicker = !hasSelectedTenant;
    isTenantSelectionResolvingStreamValue
        .addValue(shouldResolveBeforeShowingPicker);

    unawaited(
      _refreshTenantsFromBackend(
        completeInitialResolution: shouldResolveBeforeShowingPicker,
      ),
    );
  }

  void selectTenantDomain(String tenantDomain) {
    final normalized = _normalizeTenantDomain(tenantDomain);
    if (normalized == null) {
      return;
    }
    _tenantScope.selectTenantDomain(normalized);
  }

  void clearTenantSelection() {
    _tenantScope.clearSelectedTenantDomain();
  }

  String resolveTenantLabel({
    required List<LandlordTenantOption> tenants,
    required String tenantDomain,
  }) {
    final selectedTenant = _resolveTenantByDomain(
      tenants: tenants,
      tenantDomain: tenantDomain,
    );
    return selectedTenant?.name ?? tenantDomain;
  }

  List<LandlordTenantOption> _resolveBootstrapTenants() {
    final tenantsByDomain = <String, LandlordTenantOption>{};
    final landlordHost = _resolveHost(BellugaConstants.landlordDomain);
    try {
      final appData = _appDataRepository.appData;

      for (final domain in appData.domains) {
        final host = domain.value.host.trim();
        if (host.isEmpty || host == landlordHost) {
          continue;
        }
        tenantsByDomain[host] = LandlordTenantOption(
          id: host,
          name: host,
          mainDomain: host,
        );
      }
    } catch (_) {
      return const [];
    }

    final sorted = tenantsByDomain.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  Future<void> _refreshTenantsFromBackend({
    required bool completeInitialResolution,
  }) async {
    try {
      final remoteTenants = await _landlordTenantsRepository.fetchTenants();
      if (remoteTenants.isEmpty) {
        return;
      }

      _setAvailableTenants(remoteTenants);
    } catch (error) {
      debugPrint(
        '[TenantAdmin] Failed to load tenants from landlord endpoint: $error',
      );
      // Keep bootstrap tenants as fallback when backend listing is unavailable.
    } finally {
      if (completeInitialResolution) {
        isTenantSelectionResolvingStreamValue.addValue(false);
      }
    }
  }

  void _setAvailableTenants(List<LandlordTenantOption> tenants) {
    availableTenantsStreamValue.addValue(tenants);
    _syncSelectionWithAvailableTenants(tenants);
  }

  void _syncSelectionWithAvailableTenants(List<LandlordTenantOption> tenants) {
    final normalizedSelected =
        _normalizeTenantDomain(_tenantScope.selectedTenantDomain ?? '');

    if (tenants.isEmpty) {
      return;
    }

    if (tenants.length == 1) {
      final onlyTenantDomain = _normalizeTenantDomain(tenants.first.mainDomain);
      if (onlyTenantDomain == null) {
        return;
      }
      if (normalizedSelected == onlyTenantDomain) {
        return;
      }
      _tenantScope.selectTenantDomain(onlyTenantDomain);
      return;
    }

    if (normalizedSelected == null) {
      return;
    }

    final hasSelectedTenant = tenants.any(
      (tenant) =>
          _normalizeTenantDomain(tenant.mainDomain) == normalizedSelected,
    );
    if (!hasSelectedTenant) {
      _tenantScope.clearSelectedTenantDomain();
    }
  }

  bool _hasSelectedTenantDomain() {
    return _normalizeTenantDomain(_tenantScope.selectedTenantDomain ?? '') !=
        null;
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

  String? _normalizeTenantDomain(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
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

  @override
  void onDispose() {
    availableTenantsStreamValue.dispose();
    isTenantSelectionResolvingStreamValue.dispose();
  }
}
