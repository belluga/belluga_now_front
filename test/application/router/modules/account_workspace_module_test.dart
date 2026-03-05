import 'package:belluga_now/application/router/modular_app/modules/account_workspace_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_type_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
      'bootstrapTenantScopeSelection selects tenant host for tenant environment when none is selected',
      () {
    final appDataRepository = _FakeAppDataRepository(
      hostname: 'guarappari.belluga.space',
      environmentType: EnvironmentType.tenant,
    );
    final selectedTenantRepository = _FakeSelectedTenantRepository();

    AccountWorkspaceModule.bootstrapTenantScopeSelection(
      appDataRepository: appDataRepository,
      selectedTenantRepository: selectedTenantRepository,
    );

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'guarappari.belluga.space',
    );
    expect(selectedTenantRepository.selectTenantDomainCalls, 1);
  });

  test(
      'bootstrapTenantScopeSelection does not override an existing selected tenant domain',
      () {
    final appDataRepository = _FakeAppDataRepository(
      hostname: 'guarappari.belluga.space',
      environmentType: EnvironmentType.tenant,
    );
    final selectedTenantRepository = _FakeSelectedTenantRepository()
      ..selectTenantDomain('tenant-already-selected.example.com');

    AccountWorkspaceModule.bootstrapTenantScopeSelection(
      appDataRepository: appDataRepository,
      selectedTenantRepository: selectedTenantRepository,
    );

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'tenant-already-selected.example.com',
    );
    expect(selectedTenantRepository.selectTenantDomainCalls, 1);
  });

  test('bootstrapTenantScopeSelection does nothing for landlord environment',
      () {
    final appDataRepository = _FakeAppDataRepository(
      hostname: 'landlord.belluga.space',
      environmentType: EnvironmentType.landlord,
    );
    final selectedTenantRepository = _FakeSelectedTenantRepository();

    AccountWorkspaceModule.bootstrapTenantScopeSelection(
      appDataRepository: appDataRepository,
      selectedTenantRepository: selectedTenantRepository,
    );

    expect(selectedTenantRepository.selectedTenantDomain, isNull);
    expect(selectedTenantRepository.selectTenantDomainCalls, 0);
  });
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({
    required String hostname,
    required EnvironmentType environmentType,
  }) : _appData = _FakeAppData(
          hostname: hostname,
          environmentType: environmentType,
        );

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.dark);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required this.hostname,
    required EnvironmentType environmentType,
  }) : _typeValue = _buildTypeValue(environmentType);

  final EnvironmentTypeValue _typeValue;

  @override
  final String hostname;

  @override
  EnvironmentTypeValue get typeValue => _typeValue;

  static EnvironmentTypeValue _buildTypeValue(EnvironmentType environmentType) {
    final value = EnvironmentTypeValue(defaultValue: environmentType);
    value.parse(environmentType.name);
    return value;
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

  int selectTenantDomainCalls = 0;

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
  String get selectedTenantAdminBaseUrl => '';

  @override
  void clearSelectedTenant() {
    _selectedTenantDomainStreamValue.addValue(null);
    _selectedTenantStreamValue.addValue(null);
  }

  @override
  void selectTenant(LandlordTenantOption tenant) {
    selectTenantDomain(tenant.mainDomain);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    selectTenantDomainCalls += 1;
    final normalized = tenantDomain.trim();
    _selectedTenantDomainStreamValue.addValue(
      normalized.isEmpty ? null : normalized,
    );
  }

  @override
  void setAvailableTenants(List<LandlordTenantOption> tenants) {
    _availableTenantsStreamValue.addValue(List.unmodifiable(tenants));
  }
}
