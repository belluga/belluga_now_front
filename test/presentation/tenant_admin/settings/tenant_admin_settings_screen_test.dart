import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_screen.dart';
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

  testWidgets('renders environment snapshot details', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerFactory<TenantAdminSettingsController>(
      () => TenantAdminSettingsController(),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TenantAdminSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

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
    GetIt.I.registerFactory<TenantAdminSettingsController>(
      () => TenantAdminSettingsController(),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TenantAdminSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

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
    GetIt.I.registerFactory<TenantAdminSettingsController>(
      () => TenantAdminSettingsController(),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TenantAdminSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

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
}

AppData _buildAppData() {
  const remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://guarappari.test',
    'profile_types': [],
    'domains': ['https://guarappari.test'],
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

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'guarappari.test',
    'href': 'https://guarappari.test',
    'port': null,
    'device': 'test-device',
  };

  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}
