import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders environment snapshot details', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsScreen()),
    );

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Snapshot do environment'), findsOneWidget);
    expect(find.text('Tenant Test'), findsOneWidget);
    expect(find.text('guarappari.test'), findsWidgets);
    expect(find.text('project-test'), findsOneWidget);
  });

  testWidgets('updates theme mode via segmented control', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsScreen()),
    );

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(repository.themeMode, ThemeMode.dark);
  });

  testWidgets('saves firebase settings via remote repository', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsScreen()),
    );

    final editProjectIdButton = find.byTooltip('Editar Project ID');
    final saveFirebaseButton = find.byKey(
      const ValueKey('tenant_admin_settings_save_firebase'),
    );

    await tester.scrollUntilVisible(
      editProjectIdButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(editProjectIdButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project ID'),
      'project-updated',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveFirebaseButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(saveFirebaseButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedFirebaseProjectId, 'project-updated');
  });

  testWidgets('saves branding settings via remote repository', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsScreen()),
    );

    final saveBrandingButton = find.byKey(
      const ValueKey('tenant_admin_settings_save_branding'),
    );

    await tester.scrollUntilVisible(
      saveBrandingButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(saveBrandingButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.lastBrandingInput, isNotNull);
    expect(settingsRepository.lastBrandingInput!.tenantName, 'Tenant Test');
    expect(
      settingsRepository.lastBrandingInput!.primarySeedColor,
      '#009688',
    );
    expect(
      settingsRepository.lastBrandingInput!.secondarySeedColor,
      '#673AB7',
    );
  });

  test('controller saves branding light logo upload using project asset bytes',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );
    final ingestionService = TenantAdminImageIngestionService(
      externalImageProxy: _FakeTenantAdminExternalImageProxy(),
    );
    await controller.init();

    final logoFile = File('assets/images/logo_horizontal.png');
    expect(logoFile.existsSync(), isTrue);
    final logoBytes = await logoFile.readAsBytes();
    expect(logoBytes, isNotEmpty);
    final upload = await ingestionService.buildUpload(
      XFile.fromData(
        logoBytes,
        mimeType: 'image/png',
        name: 'logo_horizontal.png',
      ),
      slot: TenantAdminImageSlot.lightLogo,
    );
    expect(upload, isNotNull);
    expect(upload!.bytes, isNotEmpty);
    expect(upload.mimeType, 'image/png');
    expect(upload.fileName, endsWith('.png'));
    expect(upload.bytes.take(8).toList(),
        equals([137, 80, 78, 71, 13, 10, 26, 10]));

    await controller.saveBranding(
      lightLogoUpload: upload,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      pwaIconUpload: null,
    );

    final savedUpload = settingsRepository.lastBrandingInput?.lightLogoUpload;
    expect(savedUpload, isNotNull);
    expect(savedUpload!.bytes, isNotEmpty);
    expect(savedUpload.mimeType, 'image/png');
    expect(savedUpload.fileName, endsWith('.png'));
    expect(savedUpload.bytes.take(8).toList(),
        equals([137, 80, 78, 71, 13, 10, 26, 10]));
    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/logo-light.png'),
        contains('v='),
      ),
    );

    controller.onDispose();
  });

  test(
      'controller uses selected tenant domain for branding preview url in landlord mode',
      () async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://belluga.app'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final tenantScope = _FakeTenantScope('guarappari.test');
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
      tenantScope: tenantScope,
    );

    await controller.init();
    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      'https://guarappari.test/logo-light.png',
    );

    await controller.saveBranding(
      lightLogoUpload: null,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      pwaIconUpload: null,
    );

    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/logo-light.png'),
        contains('v='),
      ),
    );
    controller.onDispose();
  });
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'settings-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeModeStreamValue.addValue(mode);
  }
}

class _FakeTenantAdminSettingsRepository
    implements TenantAdminSettingsRepositoryContract {
  String? updatedFirebaseProjectId;
  TenantAdminBrandingUpdateInput? lastBrandingInput;

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required String type,
  }) async {
    return const TenantAdminTelemetrySettingsSnapshot(
      integrations: [],
      availableEvents: ['app_opened'],
    );
  }

  @override
  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings() async {
    return const TenantAdminFirebaseSettings(
      apiKey: 'apikey',
      appId: 'appid',
      projectId: 'project-test',
      messagingSenderId: 'sender',
      storageBucket: 'bucket',
    );
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings() async {
    return const TenantAdminTelemetrySettingsSnapshot(
      integrations: [],
      availableEvents: ['app_opened'],
    );
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  }) async {
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: [integration],
      availableEvents: const ['app_opened'],
    );
  }

  @override
  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  }) async {
    updatedFirebaseProjectId = settings.projectId;
    return settings;
  }

  @override
  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  }) async {
    return settings;
  }

  @override
  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  }) async {
    lastBrandingInput = input;
    return TenantAdminBrandingSettings(
      tenantName: input.tenantName,
      brightnessDefault: input.brightnessDefault,
      primarySeedColor: input.primarySeedColor,
      secondarySeedColor: input.secondarySeedColor,
      lightLogoUrl: 'https://guarappari.test/storage/light-logo.png',
      darkLogoUrl: 'https://guarappari.test/storage/dark-logo.png',
      lightIconUrl: 'https://guarappari.test/storage/light-icon.png',
      darkIconUrl: 'https://guarappari.test/storage/dark-icon.png',
      pwaIconUrl: 'https://guarappari.test/storage/pwa-icon.png',
    );
  }
}

class _FakeTenantAdminExternalImageProxy
    implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({
    required String imageUrl,
  }) async {
    return Uint8List(0);
  }
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain) {
    _selectedTenantDomainStreamValue.addValue(initialDomain);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => 'https://example.test/admin/api';

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

AppData _buildAppData({
  String mainDomain = 'https://guarappari.test',
}) {
  const remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'profile_types': [],
    'domains': ['https://guarappari.test', 'https://belluga.app'],
    'app_domains': ['com.guarappari.app'],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#673AB7',
    },
    'main_color': '#009688',
    'tenant_id': 'tenant-1',
    'telemetry': {
      'trackers': [],
    },
    'telemetry_context': {'location_freshness_minutes': 5},
    'firebase': {
      'apiKey': 'apikey',
      'appId': 'appid',
      'projectId': 'project-test',
      'messagingSenderId': 'sender',
      'storageBucket': 'bucket',
    },
    'push': {
      'enabled': true,
      'types': ['event'],
      'throttles': {'max_per_hour': 20},
    },
  };

  final fullRemoteData = {
    ...remoteData,
    'main_domain': mainDomain,
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'guarappari.test',
    'href': 'https://guarappari.test',
    'port': null,
    'device': 'test-device',
  };

  return AppData.fromInitialization(
    remoteData: fullRemoteData,
    localInfo: localInfo,
  );
}
