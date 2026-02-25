import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/landlord_home_screen.dart';
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

  testWidgets('shows landing + tenants + login CTA when not authenticated',
      (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: false),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: false),
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        domains: ['tenant-one.example.com', 'tenant-two.example.com'],
      ),
    );
    final controller = LandlordHomeScreenController(
      adminModeRepository: GetIt.I.get<AdminModeRepositoryContract>(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
      appDataRepository: GetIt.I.get<AppDataRepositoryContract>(),
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: LandlordHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bóora! Control Center'), findsOneWidget);
    expect(find.text('tenant-one.example.com'), findsOneWidget);
    expect(find.text('tenant-two.example.com'), findsOneWidget);
    expect(find.text('Entrar como Admin'), findsOneWidget);
    expect(find.text('Acessar área admin'), findsNothing);
  });

  testWidgets('shows admin CTA when landlord session and mode are active',
      (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: true),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        domains: ['tenant-one.example.com'],
      ),
    );
    final controller = LandlordHomeScreenController(
      adminModeRepository: GetIt.I.get<AdminModeRepositoryContract>(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
      appDataRepository: GetIt.I.get<AppDataRepositoryContract>(),
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: LandlordHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acessar área admin'), findsOneWidget);
    expect(find.text('Entrar como Admin'), findsNothing);
  });
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  _FakeAdminModeRepository({required this.isLandlordMode});

  @override
  final bool isLandlordMode;

  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: mode);

  @override
  AdminMode get mode => isLandlordMode ? AdminMode.landlord : AdminMode.user;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {}

  @override
  Future<void> setUserMode() async {}
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required this.hasValidSession});

  @override
  final bool hasValidSession;

  @override
  String get token => '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required List<String> domains,
  }) : _domains = domains
            .map(
              (domain) =>
                  DomainValue()..parse(_normalizeDomainValueInput(domain)),
            )
            .toList(growable: false);

  final List<DomainValue> _domains;

  @override
  List<DomainValue> get domains => _domains;

  @override
  List<AppDomainValue>? get appDomains => const [];

  @override
  String get hostname => 'landlord.example.com';

  static String _normalizeDomainValueInput(String domain) {
    if (domain.contains('://')) {
      return domain;
    }
    return 'https://$domain';
  }
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({required List<String> domains})
      : _appData = _FakeAppData(domains: domains);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}
}
