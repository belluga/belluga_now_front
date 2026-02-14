import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
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
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
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
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
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
