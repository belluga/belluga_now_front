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
import 'package:belluga_now/presentation/tenant_admin/shell/tenant_admin_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('shows loading gate while tenant resolution is in progress',
      (tester) async {
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: _FakeAppDataRepository(domains: const []),
      landlordTenantsRepository: _PendingLandlordTenantsRepository(),
      selectedTenantRepository: _FakeSelectedTenantRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminShellController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: TenantAdminShellScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Preparando tenant'), findsOneWidget);
    expect(find.text('Carregando tenants disponíveis...'), findsOneWidget);
    expect(find.text('Selecionar tenant'), findsNothing);
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

class _PendingLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  final Completer<List<LandlordTenantOption>> _completer =
      Completer<List<LandlordTenantOption>>();

  @override
  Future<List<LandlordTenantOption>> fetchTenants() => _completer.future;
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
    _selectedTenantDomainStreamValue.addValue(tenant.mainDomain.trim());
    _selectedTenantStreamValue.addValue(tenant);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
    _selectedTenantStreamValue.addValue(
      availableTenants.where((tenant) {
        return tenant.mainDomain.trim() == tenantDomain.trim();
      }).firstOrNull,
    );
  }

  @override
  void setAvailableTenants(List<LandlordTenantOption> tenants) {
    _availableTenantsStreamValue.addValue(tenants);
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
