import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_publication_settings.dart';
import 'package:belluga_now/domain/app_data/value_object/app_publication_store_url_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('modal renders Android-only publication target', (tester) async {
    _registerPromotionController(
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
      publicationSettings: _publicationSettings(
        androidEnabled: true,
        iosEnabled: false,
      ),
    );

    await _openModal(tester);

    expect(find.byKey(const Key('app_promotion_modal')), findsOneWidget);
    expect(find.byKey(const Key('app_promotion_modal_body')), findsOneWidget);
    expect(find.text('Bóora! fica melhor no app'), findsOneWidget);
    final brandSize = tester.getSize(
      find.byKey(const Key('app_promotion_brand_icon')),
    );
    expect(brandSize.width, lessThan(120));
    expect(brandSize.height, lessThan(120));
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsNothing,
    );
  });

  testWidgets('modal renders contextual action copy when provided', (
    tester,
  ) async {
    _registerPromotionController(
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.android,
      publicationSettings: _publicationSettings(
        androidEnabled: true,
        iosEnabled: false,
      ),
    );

    await _openModal(
      tester,
      title: 'Confirme presença pelo app',
      supportingText:
          'Use o app para confirmar sua presença e acompanhar esse evento.',
    );

    expect(find.text('Confirme presença pelo app'), findsOneWidget);
    expect(
      find.text(
        'Use o app para confirmar sua presença e acompanhar esse evento.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bóora! fica melhor no app'), findsNothing);
  });

  testWidgets('modal renders iOS-only publication target', (tester) async {
    _registerPromotionController(
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.android,
      publicationSettings: _publicationSettings(
        androidEnabled: false,
        iosEnabled: true,
      ),
    );

    await _openModal(tester);

    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsNothing,
    );
  });

  testWidgets('modal renders both stores when both targets are active', (
    tester,
  ) async {
    _registerPromotionController(
      preferredStorePlatformResolver: () => null,
      publicationSettings: _publicationSettings(
        androidEnabled: true,
        iosEnabled: true,
      ),
    );

    await _openModal(tester);

    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsOneWidget,
    );
  });

  testWidgets(
    'modal keeps inferred preferred platform without explicit config',
    (tester) async {
      _registerPromotionController(
        preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
        publicationSettings: AppPublicationSettings.empty(),
      );

      await _openModal(tester);

      expect(
        find.byKey(const Key('app_promotion_store_badge_ios')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('app_promotion_store_badge_android')),
        findsNothing,
      );
    },
  );

  testWidgets('modal renders preparation copy when no store target is active', (
    tester,
  ) async {
    _registerPromotionController(
      preferredStorePlatformResolver: () => null,
      publicationSettings: _publicationSettings(
        androidEnabled: false,
        iosEnabled: false,
      ),
    );

    await _openModal(tester);

    expect(find.text('App em preparação'), findsOneWidget);
    expect(
      find.text('A publicação nas lojas ainda não está ativa.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsNothing,
    );
  });
}

Future<void> _openModal(
  WidgetTester tester, {
  String? title,
  String? supportingText,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppPromotionModal.show(
              context,
              redirectPath: '/parceiro/qa-discovery-tag-longa',
              title: title,
              supportingText: supportingText,
            ),
            child: const Text('Open modal'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open modal'));
  await tester.pumpAndSettle();
}

void _registerPromotionController({
  required AppPromotionStorePlatformResolver preferredStorePlatformResolver,
  required AppPublicationSettings publicationSettings,
}) {
  final repository = _FakeAppDataRepository(
    appName: 'Bóora!',
    mainDomain: Uri.parse('https://tenant.example'),
    iconLightUrl: Uri.parse('https://tenant.example/icon-light.png'),
    iconDarkUrl: Uri.parse('https://tenant.example/icon-dark.png'),
    publicationSettings: publicationSettings,
  );
  GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
  GetIt.I.registerSingleton<AppPromotionScreenController>(
    AppPromotionScreenController(
      appDataRepository: repository,
      preferredStorePlatformResolver: preferredStorePlatformResolver,
    ),
  );
}

AppPublicationSettings _publicationSettings({
  required bool androidEnabled,
  required bool iosEnabled,
}) {
  return AppPublicationSettings(
    hasExplicitConfigValue: _publicationBool(true),
    android: AppPublicationPlatformSettings(
      enabledValue: _publicationBool(androidEnabled),
      storeUrlValue: _publicationStoreUrl(
        androidEnabled
            ? 'https://play.google.com/store/apps/details?id=app'
            : null,
      ),
    ),
    ios: AppPublicationPlatformSettings(
      enabledValue: _publicationBool(iosEnabled),
      storeUrlValue: _publicationStoreUrl(
        iosEnabled ? 'https://apps.apple.com/br/app/id123' : null,
      ),
    ),
  );
}

DomainBooleanValue _publicationBool(bool raw) {
  final value = DomainBooleanValue();
  value.parse(raw.toString());
  return value;
}

AppPublicationStoreUrlValue _publicationStoreUrl(String? raw) {
  final value = AppPublicationStoreUrlValue();
  value.parse(raw);
  return value;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    required String appName,
    required Uri mainDomain,
    required Uri iconLightUrl,
    required Uri iconDarkUrl,
    required AppPublicationSettings publicationSettings,
  }) : _appData = _FakeAppData(
         appName: appName,
         mainDomain: mainDomain,
         iconLightUrl: iconLightUrl,
         iconDarkUrl: iconDarkUrl,
         publicationSettings: publicationSettings,
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
    required this._publicationSettings,
  }) : _mainDomainValue = DomainValue(defaultValue: mainDomain),
       _nameValue = EnvironmentNameValue()..parse(appName),
       _mainIconLightUrl = IconUrlValue(defaultValue: iconLightUrl),
       _mainIconDarkUrl = IconUrlValue(defaultValue: iconDarkUrl);

  final DomainValue _mainDomainValue;
  final EnvironmentNameValue _nameValue;
  final IconUrlValue _mainIconLightUrl;
  final IconUrlValue _mainIconDarkUrl;
  final AppPublicationSettings _publicationSettings;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;

  @override
  EnvironmentNameValue get nameValue => _nameValue;

  @override
  IconUrlValue get mainIconLightUrl => _mainIconLightUrl;

  @override
  IconUrlValue get mainIconDarkUrl => _mainIconDarkUrl;

  @override
  AppPublicationSettings get publicationSettings => _publicationSettings;
}
