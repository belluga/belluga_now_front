import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_capture_request.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_mobile_platform.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/services/promotion_lead_capture_service_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/app_promotion_screen.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_experience.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_tester_waitlist_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  late _RecordingStackRouter router;
  late _FakeAppDataRepository appDataRepository;
  late _FakePromotionLeadCaptureService leadCaptureService;

  setUp(() async {
    await GetIt.I.reset();
    router = _RecordingStackRouter();
    appDataRepository = _FakeAppDataRepository(
      appName: 'Bóora!',
      mainDomain: Uri.parse('https://tenant.example'),
      iconLightUrl: Uri.parse('https://tenant.example/icon-light.png'),
      iconDarkUrl: Uri.parse('https://tenant.example/icon-dark.png'),
    );
    leadCaptureService = _FakePromotionLeadCaptureService();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders tester waitlist by default with proper field keyboards',
      (tester) async {
    _registerControllers(
      experience: AppPromotionExperience.testerWaitlist,
      preferredStorePlatformResolver: () => null,
      appDataRepository: appDataRepository,
      leadCaptureService: leadCaptureService,
    );

    await tester.pumpWidget(_buildWidget(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Teste o Bóora! antes do lançamento'), findsOneWidget);
    expect(
      find.byKey(const Key('app_promotion_waitlist_email_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_waitlist_whatsapp_field')),
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

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('app_promotion_waitlist_email_field')),
    );
    final whatsappField = tester.widget<TextField>(
      find.byKey(const Key('app_promotion_waitlist_whatsapp_field')),
    );

    expect(emailField.keyboardType, TextInputType.emailAddress);
    expect(whatsappField.keyboardType, TextInputType.phone);
  });

  testWidgets('submits tester waitlist lead and shows success state',
      (tester) async {
    _registerControllers(
      experience: AppPromotionExperience.testerWaitlist,
      preferredStorePlatformResolver: () => null,
      appDataRepository: appDataRepository,
      leadCaptureService: leadCaptureService,
    );

    await tester.pumpWidget(_buildWidget(router: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('app_promotion_waitlist_email_field')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('app_promotion_waitlist_whatsapp_field')),
      '27999999999',
    );
    await tester.ensureVisible(
      find.byKey(const Key('app_promotion_waitlist_platform_android')),
    );
    await tester.tap(
      find.byKey(const Key('app_promotion_waitlist_platform_android')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('app_promotion_waitlist_submit_button')),
    );
    await tester.tap(
      find.byKey(const Key('app_promotion_waitlist_submit_button')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final captured = leadCaptureService.lastRequest;
    expect(captured, isNotNull);
    expect(captured!.appName, 'Bóora!');
    expect(captured.email, 'tester@example.com');
    expect(captured.whatsapp, '27999999999');
    expect(captured.mobilePlatform, PromotionLeadMobilePlatform.android);
    expect(
      find.byKey(const Key('app_promotion_waitlist_success')),
      findsOneWidget,
    );
  });

  testWidgets('shows the underlying submission error on screen', (tester) async {
    leadCaptureService.errorToThrow =
        StateError('Promotion lead capture failed with status 521');

    _registerControllers(
      experience: AppPromotionExperience.testerWaitlist,
      preferredStorePlatformResolver: () => null,
      appDataRepository: appDataRepository,
      leadCaptureService: leadCaptureService,
    );

    await tester.pumpWidget(_buildWidget(router: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('app_promotion_waitlist_email_field')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('app_promotion_waitlist_whatsapp_field')),
      '27999999999',
    );
    await tester.ensureVisible(
      find.byKey(const Key('app_promotion_waitlist_platform_android')),
    );
    await tester.tap(
      find.byKey(const Key('app_promotion_waitlist_platform_android')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('app_promotion_waitlist_submit_button')),
    );
    await tester.tap(
      find.byKey(const Key('app_promotion_waitlist_submit_button')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('app_promotion_waitlist_error')),
      findsOneWidget,
    );
    expect(
      find.textContaining('status 521'),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders only App Store badge when iOS is inferred in app download override',
      (tester) async {
    _registerControllers(
      experience: AppPromotionExperience.appDownload,
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
      appDataRepository: appDataRepository,
      leadCaptureService: leadCaptureService,
    );

    await tester.pumpWidget(_buildWidget(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Bóora! fica melhor no app'), findsOneWidget);
    expect(
      find.byKey(const Key('app_promotion_store_badge_ios')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('app_promotion_waitlist_email_field')),
      findsNothing,
    );
  });
}

void _registerControllers({
  required AppPromotionExperience experience,
  required AppPromotionStorePlatformResolver preferredStorePlatformResolver,
  required _FakeAppDataRepository appDataRepository,
  required _FakePromotionLeadCaptureService leadCaptureService,
}) {
  GetIt.I.registerSingleton<AppPromotionScreenController>(
    AppPromotionScreenController(
      appDataRepository: appDataRepository,
      preferredStorePlatformResolver: preferredStorePlatformResolver,
      experienceResolver: () => experience,
    ),
  );
  GetIt.I.registerSingleton<AppPromotionTesterWaitlistController>(
    AppPromotionTesterWaitlistController(
      appDataRepository: appDataRepository,
      leadCaptureService: leadCaptureService,
    ),
  );
}

Widget _buildWidget({
  required _RecordingStackRouter router,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: const MaterialApp(
      home: AppPromotionScreen(
        redirectPath: '/invite?code=CODE123',
      ),
    ),
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {}

class _FakePromotionLeadCaptureService
    implements PromotionLeadCaptureServiceContract {
  PromotionLeadCaptureRequest? lastRequest;
  Object? errorToThrow;

  @override
  Future<void> submitTesterWaitlistLead(
    PromotionLeadCaptureRequest request,
  ) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    lastRequest = request;
  }
}

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
