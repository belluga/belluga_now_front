import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
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

LandlordTenantOption _tenantOption({
  required String id,
  required String name,
  required String mainDomain,
}) {
  return landlordTenantOptionFromRaw(
    id: id,
    name: name,
    mainDomain: mainDomain,
  );
}

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
        domains: ['https://belluga.space'],
      ),
    );
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordAuthRepository: _FakeLandlordAuthRepository(),
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

  testWidgets(
      'tenant selection on app keeps in-app scope without domain redirect',
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
        domains: ['https://belluga.space'],
      ),
    );

    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordAuthRepository: _FakeLandlordAuthRepository(),
      landlordTenantsRepository: _FixedLandlordTenantsRepository(
        [
          _tenantOption(
            id: 'tenant-guarappari',
            name: 'Guarappari',
            mainDomain: 'https://guarappari.belluga.space',
          ),
        ],
      ),
      selectedTenantRepository: _FakeSelectedTenantRepository(
        suppressSelectionStreamUpdates: true,
      ),
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

    expect(launchedUrls, isEmpty);
    expect(controller.selectedTenantDomain, 'https://guarappari.belluga.space');
  });

  test('tenant environment auto-selects current host on init', () {
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'tenant',
        hostname: 'guarappari.belluga.space',
        domains: [
          'https://guarappari.belluga.space',
          'https://belluga.space',
        ],
      ),
    );
    final selectedTenantRepository = _FakeSelectedTenantRepository();
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordAuthRepository: _FakeLandlordAuthRepository(),
      landlordTenantsRepository: _PendingLandlordTenantsRepository(),
      selectedTenantRepository: selectedTenantRepository,
    );

    controller.init();

    expect(
      selectedTenantRepository.selectedTenantDomain,
      'guarappari.belluga.space',
    );
  });

  testWidgets(
      'tenant environment without local landlord session shows admin auth gate',
      (tester) async {
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'tenant',
        hostname: 'guarapari.belluga.space',
        domains: ['https://guarapari.belluga.space'],
      ),
    );
    final controller = TenantAdminShellController(
      adminModeRepository: _FakeAdminModeRepository(),
      appDataRepository: appDataRepository,
      landlordAuthRepository:
          _FakeLandlordAuthRepository(hasValidSession: false),
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

    expect(find.text('Tenant admin login'), findsOneWidget);
    expect(find.text('Entrar como Admin'), findsOneWidget);
  });

  test('fails fast when landlord auth repository is missing', () {
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        envType: 'landlord',
        hostname: 'belluga.space',
        domains: ['https://belluga.space'],
      ),
    );

    expect(
      () => TenantAdminShellController(
        adminModeRepository: _FakeAdminModeRepository(),
        appDataRepository: appDataRepository,
        landlordTenantsRepository: _PendingLandlordTenantsRepository(),
        selectedTenantRepository: _FakeSelectedTenantRepository(),
      ),
      throwsA(anything),
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
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(defaultValue: DistanceInMetersValue.fromRaw(1000, defaultValue: 1000));

  @override
  DistanceInMetersValue get maxRadiusMeters => DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}
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

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({this.hasValidSession = true});

  @override
  final bool hasValidSession;

  @override
  String get token => hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

  @override
  Future<void> logout() async {}
}

class _FakeSelectedTenantRepository
    implements TenantAdminSelectedTenantRepositoryContract {
  _FakeSelectedTenantRepository({
    this.suppressSelectionStreamUpdates = false,
  });

  final bool suppressSelectionStreamUpdates;
  final StreamValue<List<LandlordTenantOption>> _availableTenantsStreamValue =
      StreamValue<List<LandlordTenantOption>>(defaultValue: []);
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<LandlordTenantOption?> _selectedTenantStreamValue =
      StreamValue<LandlordTenantOption?>(defaultValue: null);
  String? _selectedTenantDomainValue;
  LandlordTenantOption? _selectedTenantValue;

  @override
  List<LandlordTenantOption> get availableTenants =>
      _availableTenantsStreamValue.value;

  @override
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue =>
      _availableTenantsStreamValue;

  @override
  String? get selectedTenantDomain =>
      _selectedTenantDomainValue ?? _selectedTenantDomainStreamValue.value;

  @override
  LandlordTenantOption? get selectedTenant =>
      _selectedTenantValue ?? _selectedTenantStreamValue.value;

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
    _selectedTenantDomainValue = null;
    _selectedTenantValue = null;
    if (!suppressSelectionStreamUpdates) {
      _selectedTenantDomainStreamValue.addValue(null);
      _selectedTenantStreamValue.addValue(null);
    }
  }

  @override
  void selectTenant(LandlordTenantOption tenant) {
    _selectedTenantDomainValue = tenant.mainDomain.trim();
    _selectedTenantValue = tenant;
    if (!suppressSelectionStreamUpdates) {
      _selectedTenantDomainStreamValue.addValue(tenant.mainDomain.trim());
      _selectedTenantStreamValue.addValue(tenant);
    }
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainValue = (tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim();
    _selectedTenantValue = availableTenants.where((tenant) {
      return tenant.mainDomain.trim() ==
          (tenantDomain is String
                  ? tenantDomain
                  : (tenantDomain as dynamic).value as String)
              .trim();
    }).firstOrNull;
    if (!suppressSelectionStreamUpdates) {
      _selectedTenantDomainStreamValue.addValue((tenantDomain is String
              ? tenantDomain
              : (tenantDomain as dynamic).value as String)
          .trim());
      _selectedTenantStreamValue.addValue(
        _selectedTenantValue,
      );
    }
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
  return buildAppDataFromInitialization(
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
