import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('auto-selects the tenant when only one is available in bootstrap',
      () async {
    final tenantScope = _FakeTenantScope();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(
        domains: ['tenant-one.example.com'],
      ),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      tenantScope: tenantScope,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(tenantScope.selectedTenantDomain, 'tenant-one.example.com');
    expect(controller.availableTenantsStreamValue.value, hasLength(1));
    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
  });

  test('auto-selects remote tenant when backend returns a single tenant',
      () async {
    final tenantScope = _FakeTenantScope();
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
      tenantScope: tenantScope,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(tenantScope.selectedTenantDomain, 'tenant-a.example.com');
    expect(controller.availableTenantsStreamValue.value, hasLength(1));
    expect(
        controller.availableTenantsStreamValue.value.single.name, 'Tenant A');
    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
  });

  test('keeps resolving tenant selection until backend returns when needed',
      () async {
    final tenantScope = _FakeTenantScope();
    final backendRepository = _ControllableLandlordTenantsRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository: backendRepository,
      tenantScope: tenantScope,
    );

    controller.init();
    expect(controller.isTenantSelectionResolvingStreamValue.value, isTrue);
    expect(tenantScope.selectedTenantDomain, isNull);

    backendRepository.complete(const [
      LandlordTenantOption(
        id: 'tenant-x',
        name: 'Tenant X',
        mainDomain: 'tenant-x.example.com',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(tenantScope.selectedTenantDomain, 'tenant-x.example.com');
  });

  test('stops resolving and keeps no selection when backend returns empty list',
      () async {
    final tenantScope = _FakeTenantScope();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      tenantScope: tenantScope,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(tenantScope.selectedTenantDomain, isNull);
  });

  test('does not bootstrap tenant selection from app domains', () async {
    final tenantScope = _FakeTenantScope();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(
        domains: const [],
        appDomains: ['com.tenant.app'],
      ),
      landlordTenantsRepository:
          _FakeLandlordTenantsRepository(remoteTenants: const []),
      tenantScope: tenantScope,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.availableTenantsStreamValue.value, isEmpty);
    expect(tenantScope.selectedTenantDomain, isNull);
  });

  test('stops resolving when backend throws during tenant fetch', () async {
    final tenantScope = _FakeTenantScope();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository: _ThrowingLandlordTenantsRepository(),
      tenantScope: tenantScope,
    );

    controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isTenantSelectionResolvingStreamValue.value, isFalse);
    expect(tenantScope.selectedTenantDomain, isNull);
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

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}
