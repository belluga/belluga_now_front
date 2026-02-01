import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/landlord_home_screen.dart';
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

  testWidgets('shows admin banner and badge in landlord mode', (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: true),
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(
      LandlordHomeScreenController(),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LandlordHomeScreen(),
      ),
    );

    expect(find.text('Modo Admin ativo'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Admin'), findsOneWidget);
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
