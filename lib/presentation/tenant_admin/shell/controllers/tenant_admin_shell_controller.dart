import 'dart:async';

import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminShellController implements Disposable {
  TenantAdminShellController({
    AdminModeRepositoryContract? adminModeRepository,
    AppDataRepositoryContract? appDataRepository,
    LandlordTenantsRepositoryContract? landlordTenantsRepository,
    TenantAdminSelectedTenantRepositoryContract? selectedTenantRepository,
  })  : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _landlordTenantsRepository = landlordTenantsRepository ??
            GetIt.I.get<LandlordTenantsRepositoryContract>(),
        _selectedTenantRepository = selectedTenantRepository ??
            GetIt.I.get<TenantAdminSelectedTenantRepositoryContract>();

  final AdminModeRepositoryContract _adminModeRepository;
  final AppDataRepositoryContract _appDataRepository;
  final LandlordTenantsRepositoryContract _landlordTenantsRepository;
  final TenantAdminSelectedTenantRepositoryContract _selectedTenantRepository;
  final StreamValue<bool> isTenantSelectionResolvingStreamValue =
      StreamValue<bool>(defaultValue: false);

  StreamValue<AdminMode> get modeStreamValue =>
      _adminModeRepository.modeStreamValue;
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue =>
      _selectedTenantRepository.availableTenantsStreamValue;
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantRepository.selectedTenantDomainStreamValue;
  String? get selectedTenantDomain =>
      _selectedTenantRepository.selectedTenantDomain;

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
    _selectedTenantRepository.selectTenantDomain(normalized);
  }

  void clearTenantSelection() {
    _selectedTenantRepository.clearSelectedTenant();
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
    } catch (error) {
      debugPrint(
        '[TenantAdmin] Failed to read bootstrap tenant domains: $error',
      );
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
    _selectedTenantRepository.setAvailableTenants(tenants);
  }

  bool _hasSelectedTenantDomain() {
    return _normalizeTenantDomain(
            _selectedTenantRepository.selectedTenantDomain ?? '') !=
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
      if (_domainsMatch(tenant.mainDomain, normalizedTarget)) {
        return tenant;
      }
    }

    return null;
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

  String? _normalizeTenantDomain(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
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

  _TenantDomain? _parseTenantDomain(String raw) {
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
    isTenantSelectionResolvingStreamValue.dispose();
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
