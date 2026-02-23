import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('auto-selects the tenant when only one is available in bootstrap',
      () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(
        domains: ['tenant-one.example.com'],
      ),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'tenant-one.example.com',
    );
    expect(controller.availableTenantsStreamValue.value, hasLength(1));
    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
  });

  test('auto-selects remote tenant when backend returns a single tenant',
      () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(
        domains: ['tenant-a.example.com', 'tenant-b.example.com'],
      ),
      landlordTenantsRepository: _FakeLandlordTenantsRepository(
        remoteTenants: const [
          LandlordTenantOption(
            id: 'tenant-a',
            name: 'Tenant A',
            mainDomain: 'tenant-a.example.com',
          ),
        ],
      ),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'tenant-a.example.com',
    );
    expect(controller.availableTenantsStreamValue.value, hasLength(1));
    expect(
        controller.availableTenantsStreamValue.value.single.name, 'Tenant A');
    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
  });

  test('keeps resolving tenant selection until backend returns when needed',
      () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final backendRepository = _ControllableLandlordTenantsRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository: backendRepository,
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    expect(controller.isTenantSelectionResolvingStreamValue.value, isTrue);
    expect(selectedTenantRepository.selectedTenantDomain, isNull);

    backendRepository.complete(const [
      LandlordTenantOption(
        id: 'tenant-x',
        name: 'Tenant X',
        mainDomain: 'tenant-x.example.com',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(
      selectedTenantRepository.selectedTenantDomain,
      'tenant-x.example.com',
    );
  });

  test('stops resolving and keeps no selection when backend returns empty list',
      () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(selectedTenantRepository.selectedTenantDomain, isNull);
  });

  test('does not bootstrap tenant selection from app domains', () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(
        domains: const [],
        appDomains: ['com.tenant.app'],
      ),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.availableTenantsStreamValue.value, isEmpty);
    expect(selectedTenantRepository.selectedTenantDomain, isNull);
  });

  test('stops resolving when backend throws during tenant fetch', () async {
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository: _ThrowingLandlordTenantsRepository(),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(selectedTenantRepository.selectedTenantDomain, isNull);
  });
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: AdminMode.landlord);

  @override
  AdminMode get mode => AdminMode.landlord;

  @override
  bool get isLandlordMode => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {}

  @override
  Future<void> setUserMode() async {}
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({
    required List<String> domains,
    List<String> appDomains = const [],
  }) : _appData = _FakeAppData(domains: domains, appDomains: appDomains);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required List<String> domains,
    required List<String> appDomains,
  })  : _domains = domains
            .map((domain) => DomainValue()..parse(_normalize(domain)))
            .toList(growable: false),
        _appDomains = appDomains
            .map((domain) => AppDomainValue()..parse(domain))
            .toList(growable: false);

  final List<DomainValue> _domains;
  final List<AppDomainValue> _appDomains;

  @override
  List<DomainValue> get domains => _domains;

  @override
  List<AppDomainValue>? get appDomains => _appDomains;

  @override
  String get hostname => 'landlord.example.com';

  static String _normalize(String domain) {
    if (domain.contains('://')) {
      return domain;
    }
    return 'https://$domain';
  }
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  _FakeLandlordTenantsRepository({required this.remoteTenants});

  final List<LandlordTenantOption> remoteTenants;

  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return remoteTenants;
  }
}

class _ControllableLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  final Completer<List<LandlordTenantOption>> _completer =
      Completer<List<LandlordTenantOption>>();

  void complete(List<LandlordTenantOption> tenants) {
    if (_completer.isCompleted) return;
    _completer.complete(tenants);
  }

  @override
  Future<List<LandlordTenantOption>> fetchTenants() {
    return _completer.future;
  }
}

class _ThrowingLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    throw Exception('backend unavailable');
  }
}

class _FakeSelectedTenantRepository
    implements TenantAdminSelectedTenantRepositoryContract {
  final StreamValue<List<LandlordTenantOption>> _availableTenantsStreamValue =
      StreamValue<List<LandlordTenantOption>>(defaultValue: const []);
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<LandlordTenantOption?> _selectedTenantStreamValue =
      StreamValue<LandlordTenantOption?>(defaultValue: null);

  @override
  List<LandlordTenantOption> get availableTenants =>
      _availableTenantsStreamValue.value;

  @override
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue =>
      _availableTenantsStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  LandlordTenantOption? get selectedTenant => _selectedTenantStreamValue.value;

  @override
  StreamValue<LandlordTenantOption?> get selectedTenantStreamValue =>
      _selectedTenantStreamValue;

  @override
  String get selectedTenantAdminBaseUrl =>
      resolveTenantAdminBaseUrl(selectedTenantDomain ?? '');

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenant() {
    _selectedTenantDomainStreamValue.addValue(null);
    _selectedTenantStreamValue.addValue(null);
  }

  @override
  void selectTenant(LandlordTenantOption tenant) {
    final normalizedDomain = _normalizeTenantDomain(tenant.mainDomain);
    if (normalizedDomain == null) {
      return;
    }
    _selectedTenantDomainStreamValue.addValue(normalizedDomain);
    _selectedTenantStreamValue.addValue(tenant);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    final normalizedDomain = _normalizeTenantDomain(tenantDomain);
    if (normalizedDomain == null) {
      return;
    }
    _selectedTenantDomainStreamValue.addValue(normalizedDomain);
    final selected = availableTenants.where((tenant) {
      return _normalizeTenantDomain(tenant.mainDomain) == normalizedDomain;
    }).firstOrNull;
    _selectedTenantStreamValue.addValue(selected);
  }

  @override
  void setAvailableTenants(List<LandlordTenantOption> tenants) {
    _availableTenantsStreamValue.addValue(tenants);
    if (tenants.length == 1) {
      selectTenant(tenants.first);
      return;
    }
    if (selectedTenantDomain == null) {
      return;
    }
    final selected = tenants.where((tenant) {
      return _normalizeTenantDomain(tenant.mainDomain) == selectedTenantDomain;
    }).firstOrNull;
    if (selected == null) {
      clearSelectedTenant();
      return;
    }
    _selectedTenantStreamValue.addValue(selected);
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (this.isEmpty) {
      return null;
    }
    return first;
  }
}
