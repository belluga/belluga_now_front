import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/app_promotion_screen.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  late _RecordingStackRouter router;
  late _FakeAppDataRepository appDataRepository;

  setUp(() async {
    await GetIt.I.reset();
    router = _RecordingStackRouter();
    appDataRepository = _FakeAppDataRepository(
      appName: 'Bóora!',
      mainDomain: Uri.parse('https://tenant.example'),
      iconLightUrl: Uri.parse('https://tenant.example/icon-light.png'),
      iconDarkUrl: Uri.parse('https://tenant.example/icon-dark.png'),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders runtime app name and branding icon', (tester) async {
    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(
        appDataRepository: appDataRepository,
        preferredStorePlatformResolver: () => null,
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        router: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bóora! fica melhor no app'), findsOneWidget);
    expect(find.byKey(const Key('app_promotion_brand_icon')), findsOneWidget);
    expect(find.byKey(const Key('app_promotion_close_button')), findsOneWidget);
    expect(find.byKey(const Key('app_promotion_dismiss_button')), findsOneWidget);
  });

  testWidgets('renders only App Store badge when iOS is inferred',
      (tester) async {
    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(
        appDataRepository: appDataRepository,
        preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        router: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsNothing,
    );
  });

  testWidgets('renders only Google Play badge when Android is inferred',
      (tester) async {
    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(
        appDataRepository: appDataRepository,
        preferredStorePlatformResolver: () =>
            AppPromotionStorePlatform.android,
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        router: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsOneWidget,
    );
  });

  testWidgets('renders App Store badge before Google Play badge on fallback',
      (tester) async {
    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(
        appDataRepository: appDataRepository,
        preferredStorePlatformResolver: () => null,
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        router: router,
      ),
    );

    await tester.pumpAndSettle();

    final iosFinder = find.byKey(const Key('app_promotion_store_badge_ios'));
    final androidFinder =
        find.byKey(const Key('app_promotion_store_badge_android'));

    expect(iosFinder, findsOneWidget);
    expect(androidFinder, findsOneWidget);

    final iosTopLeft = tester.getTopLeft(iosFinder);
    final androidTopLeft = tester.getTopLeft(androidFinder);

    expect(iosTopLeft.dy, lessThan(androidTopLeft.dy));
  });

  testWidgets(
      'keeps top close and bottom actions stable on constrained mobile viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 680));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    GetIt.I.registerSingleton<AppPromotionScreenController>(
      AppPromotionScreenController(
        appDataRepository: appDataRepository,
        preferredStorePlatformResolver: () => null,
      ),
    );

    await tester.pumpWidget(
      _buildWidget(
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final closeFinder = find.byKey(const Key('app_promotion_close_button'));
    final brandFinder = find.byKey(const Key('app_promotion_brand_icon'));
    final dismissFinder = find.byKey(const Key('app_promotion_dismiss_button'));
    final androidFinder =
        find.byKey(const Key('app_promotion_store_badge_android'));

    expect(closeFinder, findsOneWidget);
    expect(brandFinder, findsOneWidget);
    expect(dismissFinder, findsOneWidget);
    expect(androidFinder, findsOneWidget);

    final closeTopLeft = tester.getTopLeft(closeFinder);
    final brandTopLeft = tester.getTopLeft(brandFinder);
    final dismissTopLeft = tester.getTopLeft(dismissFinder);
    final androidTopLeft = tester.getTopLeft(androidFinder);

    expect(closeTopLeft.dy, lessThan(brandTopLeft.dy));
    expect(dismissTopLeft.dy, greaterThan(androidTopLeft.dy));
  });
}

Widget _buildWidget({
  required _RecordingStackRouter router,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: AppPromotionScreen(
        redirectPath: '/invite?code=CODE123',
      ),
    ),
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    required String appName,
    required Uri mainDomain,
    required Uri iconLightUrl,
    required Uri iconDarkUrl,
  }) : _appData = _FakeAppData(
          appName: appName,
          mainDomain: mainDomain,
          iconLightUrl: iconLightUrl,
          iconDarkUrl: iconDarkUrl,
        );

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
    required String appName,
    required Uri mainDomain,
    required Uri iconLightUrl,
    required Uri iconDarkUrl,
  })  : _mainDomainValue = DomainValue(defaultValue: mainDomain),
        _nameValue = EnvironmentNameValue()..parse(appName),
        _mainIconLightUrl = IconUrlValue(defaultValue: iconLightUrl),
        _mainIconDarkUrl = IconUrlValue(defaultValue: iconDarkUrl);

  final DomainValue _mainDomainValue;
  final EnvironmentNameValue _nameValue;
  final IconUrlValue _mainIconLightUrl;
  final IconUrlValue _mainIconDarkUrl;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;

  @override
  EnvironmentNameValue get nameValue => _nameValue;

  @override
  IconUrlValue get mainIconLightUrl => _mainIconLightUrl;

  @override
  IconUrlValue get mainIconDarkUrl => _mainIconDarkUrl;
}
