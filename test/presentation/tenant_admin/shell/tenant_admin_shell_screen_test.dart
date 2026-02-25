import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/tenant_admin_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      urlLauncherChannel,
      null,
    );
    await GetIt.I.reset();
  });

  testWidgets('shows loading gate while tenant resolution is in progress',
      (tester) async {
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'landlord',
        hostname: 'belluga.space',
        domains: const ['https://belluga.space'],
      ),
    );
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordTenantsRepository: _PendingLandlordTenantsRepository(),
      selectedTenantRepository: _FakeSelectedTenantRepository(),
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
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

  testWidgets('tenant selection redirects landlord flow to tenant domain admin',
      (tester) async {
    final launchedUrls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      urlLauncherChannel,
      (MethodCall call) async {
        if (call.method == 'launch') {
          final url = (call.arguments as Map)['url']?.toString();
          if (url != null) {
            launchedUrls.add(url);
          }
          return true;
        }
        if (call.method == 'canLaunch') {
          return true;
        }
        return null;
      },
    );

    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'landlord',
        hostname: 'belluga.space',
        domains: const ['https://belluga.space'],
      ),
    );

    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordTenantsRepository: _FixedLandlordTenantsRepository(
        const [
          LandlordTenantOption(
            id: 'tenant-guarappari',
            name: 'Guarappari',
            mainDomain: 'https://guarappari.belluga.space',
          ),
        ],
      ),
      selectedTenantRepository: _FakeSelectedTenantRepository(),
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
    GetIt.I.registerSingleton<TenantAdminShellController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: TenantAdminShellScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Selecionar tenant'), findsOneWidget);
    await tester.tap(find.text('Guarappari'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      launchedUrls,
      contains('https://guarappari.belluga.space/admin'),
    );
  });

  test('tenant environment auto-selects current host on init', () {
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'tenant',
        hostname: 'guarappari.belluga.space',
        domains: const [
          'https://guarappari.belluga.space',
          'https://belluga.space',
        ],
      ),
    );
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordTenantsRepository: _PendingLandlordTenantsRepository(),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'guarappari.belluga.space',
    );
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
  _FakeAppDataRepository({required AppData appData}) : _appData = appData;

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

class _PendingLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  final Completer<List<LandlordTenantOption>> _completer =
      Completer<List<LandlordTenantOption>>();

  @override
  Future<List<LandlordTenantOption>> fetchTenants() => _completer.future;
}

class _FixedLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  const _FixedLandlordTenantsRepository(this._tenants);

  final List<LandlordTenantOption> _tenants;

  @override
  Future<List<LandlordTenantOption>> fetchTenants() async => _tenants;
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

AppData _buildAppData({
  required String envType,
  required String hostname,
  required List<String> domains,
  List<String> appDomains = const [],
}) {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return AppData.fromInitialization(
    remoteData: {
      'name': 'Test',
      'type': envType,
      'main_domain': domains.isNotEmpty ? domains.first : 'https://$hostname',
      'domains': domains,
      'app_domains': appDomains,
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': hostname,
      'href': 'https://$hostname',
      'port': null,
      'device': 'test-device',
    },
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (this.isEmpty) {
      return null;
    }
    return first;
  }
}
