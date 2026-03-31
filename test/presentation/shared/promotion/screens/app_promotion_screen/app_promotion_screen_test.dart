import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/app_promotion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  late _RecordingStackRouter router;

  setUp(() async {
    await GetIt.I.reset();
    router = _RecordingStackRouter();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );
    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders App Store badge before Google Play badge',
      (tester) async {
    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const MaterialApp(
          home: AppPromotionScreen(
            redirectPath: '/invite?code=CODE123',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Baixe o app'), findsOneWidget);
    expect(
        find.byKey(const Key('app_promotion_store_badge_ios')), findsOneWidget);
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsOneWidget,
    );

    final iosTopLeft = tester.getTopLeft(
      find.byKey(const Key('app_promotion_store_badge_ios')),
    );
    final androidTopLeft = tester.getTopLeft(
      find.byKey(const Key('app_promotion_store_badge_android')),
    );

    expect(iosTopLeft.dy, lessThan(androidTopLeft.dy));
  });
}

class _RecordingStackRouter extends Mock implements StackRouter {}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({
    required Uri mainDomain,
  }) : _appData = _FakeAppData(mainDomain: mainDomain);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(1000, defaultValue: 1000),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.dark);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required Uri mainDomain,
  }) : _mainDomainValue = DomainValue(defaultValue: mainDomain);

  final DomainValue _mainDomainValue;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;
}
