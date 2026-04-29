import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/models/home_location_status_state.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/tenant_home_screen.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/models/tenant_home_agenda_display_state.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/my_events_carousel_card.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/section_header.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:stream_value/core/stream_value.dart';

import 'tenant_home_screen_test.mocks.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

@GenerateNiceMocks([
  MockSpec<TenantHomeController>(),
  MockSpec<TenantHomeAgendaController>(),
  MockSpec<FavoritesSectionController>(),
  MockSpec<InvitesBannerBuilderController>(),
  MockSpec<StackRouter>(),
  MockSpec<AppDataRepository>(),
  MockSpec<AppData>(),
])
class _TestTenantHomeController extends MockTenantHomeController {
  _TestTenantHomeController(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;
}

class _TestFavoritesSectionController extends MockFavoritesSectionController {
  _TestFavoritesSectionController()
      : _navigationTargetStreamValue =
            StreamValue<FavoriteNavigationTarget?>(defaultValue: null);

  final StreamValue<FavoriteNavigationTarget?> _navigationTargetStreamValue;

  @override
  StreamValue<FavoriteNavigationTarget?> get navigationTargetStreamValue =>
      _navigationTargetStreamValue;
}

class _TestTenantHomeAgendaController extends MockTenantHomeAgendaController {
  _TestTenantHomeAgendaController()
      : _authUserStreamValue = StreamValue<UserContract?>(defaultValue: null),
        _isRadiusActionCompactStreamValue =
            StreamValue<bool>(defaultValue: false),
        _isRadiusRefreshLoadingStreamValue =
            StreamValue<bool>(defaultValue: false),
        _discoveryFilterCatalogStreamValue =
            StreamValue<DiscoveryFilterCatalog>(
          defaultValue: const DiscoveryFilterCatalog(surface: 'home.events'),
        ),
        _discoveryFilterSelectionStreamValue =
            StreamValue<DiscoveryFilterSelection>(
          defaultValue: const DiscoveryFilterSelection(),
        ),
        _isDiscoveryFilterCatalogLoadingStreamValue =
            StreamValue<bool>(defaultValue: false),
        _isDiscoveryFilterPanelVisibleStreamValue =
            StreamValue<bool>(defaultValue: false);

  final StreamValue<UserContract?> _authUserStreamValue;
  final StreamValue<bool> _isRadiusActionCompactStreamValue;
  final StreamValue<bool> _isRadiusRefreshLoadingStreamValue;
  final StreamValue<DiscoveryFilterCatalog> _discoveryFilterCatalogStreamValue;
  final StreamValue<DiscoveryFilterSelection>
      _discoveryFilterSelectionStreamValue;
  final StreamValue<bool> _isDiscoveryFilterCatalogLoadingStreamValue;
  final StreamValue<bool> _isDiscoveryFilterPanelVisibleStreamValue;

  @override
  StreamValue<UserContract?>? get authUserStreamValue => _authUserStreamValue;

  @override
  StreamValue<bool> get isRadiusRefreshLoadingStreamValue =>
      _isRadiusRefreshLoadingStreamValue;

  @override
  StreamValue<bool> get isRadiusActionCompactStreamValue =>
      _isRadiusActionCompactStreamValue;

  @override
  StreamValue<DiscoveryFilterCatalog> get discoveryFilterCatalogStreamValue =>
      _discoveryFilterCatalogStreamValue;

  @override
  StreamValue<DiscoveryFilterSelection>
      get discoveryFilterSelectionStreamValue =>
          _discoveryFilterSelectionStreamValue;

  @override
  StreamValue<bool> get isDiscoveryFilterCatalogLoadingStreamValue =>
      _isDiscoveryFilterCatalogLoadingStreamValue;

  @override
  StreamValue<bool> get isDiscoveryFilterPanelVisibleStreamValue =>
      _isDiscoveryFilterPanelVisibleStreamValue;

  @override
  DiscoveryFilterPolicy get discoveryFilterPolicy =>
      const DiscoveryFilterPolicy(
        primarySelectionMode: DiscoveryFilterSelectionMode.multiple,
        taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
        primaryLayoutMode: DiscoveryFilterLayoutMode.row,
        taxonomyLayoutMode: DiscoveryFilterLayoutMode.wrap,
      );

  @override
  void setRadiusActionCompactState(bool isCompact) {
    if (_isRadiusActionCompactStreamValue.value == isCompact) {
      return;
    }
    _isRadiusActionCompactStreamValue.addValue(isCompact);
  }

  @override
  bool get shouldShowInviteFilterAction => true;
}

class _RecordingBackRouter extends Fake implements StackRouter {
  _RecordingBackRouter({
    required this.canPopResult,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  bool canPopResult;
  final GlobalKey<NavigatorState> _navigatorKey;
  int canPopCallCount = 0;
  int popCallCount = 0;

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  RootStackRouter get root => _FakeRootStackRouter('/');

  @override
  bool canPop({
    bool? ignoreChildRoutes,
    bool? ignoreParentRoutes,
    bool? ignorePagelessRoutes,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCallCount += 1;
    final navigatorState = _navigatorKey.currentState;
    if (navigatorState != null && navigatorState.canPop()) {
      navigatorState.pop<T>(result);
    }
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

void _stubMockRouterRoot(MockStackRouter router, {String currentPath = '/'}) {
  mockito.when(router.root).thenReturn(_FakeRootStackRouter(currentPath));
}

Widget _buildRoutedTenantHomeApp(
  StackRouter router, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final routeData = RouteData(
    route: RouteMatch(
      config: AutoRoute(
        page: TenantHomeRoute.page,
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantHome,
        ),
      ),
      segments: const <String>[],
      stringMatch: '/',
      key: const ValueKey<String>('tenant-home'),
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: RouteDataScope(
        routeData: routeData,
        child: const TenantHomeScreen(),
      ),
    ),
  );
}

void main() {
  late MockTenantHomeController mockController;
  late _TestTenantHomeAgendaController mockAgendaController;
  late MockFavoritesSectionController mockFavoritesController;
  late MockInvitesBannerBuilderController mockInvitesBannerController;
  late MockAppDataRepository mockAppDataRepository;
  late MockAppData mockAppData;
  late ScrollController testScrollController;

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    mockito.resetMockitoState();
    await GetIt.I.reset();
    mockAgendaController = _TestTenantHomeAgendaController();
    mockFavoritesController = _TestFavoritesSectionController();
    mockInvitesBannerController = MockInvitesBannerBuilderController();
    mockAppDataRepository = MockAppDataRepository();
    mockAppData = MockAppData();
    testScrollController = ScrollController();
    mockController = _TestTenantHomeController(mockAppData);

    GetIt.I.registerSingleton<TenantHomeController>(mockController);
    GetIt.I.registerSingleton<TenantHomeAgendaController>(mockAgendaController);
    GetIt.I
        .registerSingleton<FavoritesSectionController>(mockFavoritesController);
    GetIt.I.registerSingleton<InvitesBannerBuilderController>(
        mockInvitesBannerController);
    GetIt.I.registerSingleton<AppDataRepository>(mockAppDataRepository);
    GetIt.I.registerSingleton<AppData>(mockAppData);

    // Stub AppData
    mockito.when(mockAppDataRepository.appData).thenReturn(mockAppData);
    mockito
        .when(mockAppData.nameValue)
        .thenReturn(EnvironmentNameValue()..parse('Test App'));
    mockito
        .when(mockAppData.mainColor)
        .thenReturn(MainColorValue()..parse('#000000'));
    mockito
        .when(mockAppData.mainIconLightUrl)
        .thenReturn(IconUrlValue()..parse('http://example.com/icon.png'));
    mockito.when(mockAppData.mainLogoLightUrl).thenReturn(
        MainLogoUrlValue()..parse('http://example.com/logo-light.png'));
    mockito.when(mockAppData.mainLogoDarkUrl).thenReturn(
        MainLogoUrlValue()..parse('http://example.com/logo-dark.png'));
    mockito.when(mockAppDataRepository.maxRadiusMetersStreamValue).thenReturn(
          StreamValue<DistanceInMetersValue>(
            defaultValue:
                DistanceInMetersValue.fromRaw(5000, defaultValue: 5000),
          ),
        );

    // Stub Home Controller
    mockito
        .when(mockFavoritesController.favoritesStreamValue)
        .thenReturn(StreamValue<List<FavoriteResume>?>(defaultValue: []));
    mockito.when(mockFavoritesController.init()).thenAnswer((_) async {});
    mockito.when(mockFavoritesController.buildPinnedFavorite()).thenReturn(
          FavoriteResume(
            titleValue: TitleValue()..parse('Pinned'),
            assetPathValue: AssetPathValue()
              ..parse('assets/images/placeholder_avatar.png'),
            isPrimaryValue: FavoritePrimaryFlagValue()..parse('true'),
          ),
        );
    mockito
        .when(mockInvitesBannerController.pendingInvitesStreamValue)
        .thenReturn(StreamValue<List<InviteModel>>(defaultValue: const []));

    // Stub Home Controller
    mockito.when(mockController.homeLocationStatusStreamValue).thenReturn(
          StreamValue<HomeLocationStatusState?>(
            defaultValue: const HomeLocationStatusState(
              statusText: 'Usando sua localização.',
              dialogTitle: 'Usando sua localização',
              dialogMessage: 'Dialogo teste',
            ),
          ),
        );
    mockito
        .when(mockController.myEventsFilteredStreamValue)
        .thenReturn(StreamValue<List<VenueEventResume>>(defaultValue: []));
    mockito
        .when(mockController.scrollController)
        .thenReturn(testScrollController);

    // Callbacks
    mockito
        .when(mockController.distanceLabelForMyEvent(mockito.any))
        .thenReturn('1km');

    // Agenda controller stubs
    mockito
        .when(mockAgendaController.isInitialLoadingStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito
        .when(mockAgendaController.initialLoadingLabelStreamValue)
        .thenReturn(StreamValue<String>(defaultValue: ''));
    mockito
        .when(mockAgendaController.isPageLoadingStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito
        .when(mockAgendaController.showHistoryStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito
        .when(mockAgendaController.searchActiveStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito
        .when(mockAgendaController.inviteFilterStreamValue)
        .thenReturn(StreamValue(defaultValue: InviteFilter.none));
    mockito
        .when(mockAgendaController.radiusMetersStreamValue)
        .thenReturn(StreamValue<double>(defaultValue: 1000));
    mockito
        .when(mockAgendaController.maxRadiusMetersStreamValue)
        .thenReturn(StreamValue<double>(defaultValue: 5000));
    mockito
        .when(mockAgendaController.hasMoreStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.displayStateStreamValue).thenReturn(
          StreamValue<TenantHomeAgendaDisplayState?>(
            defaultValue: TenantHomeAgendaDisplayState(events: []),
          ),
        );
    mockito
        .when(mockAgendaController.searchController)
        .thenReturn(TextEditingController());
    mockito.when(mockAgendaController.focusNode).thenReturn(FocusNode());
    mockito
        .when(mockAgendaController.init(
            startWithHistory: mockito.anyNamed('startWithHistory')))
        .thenAnswer((_) async {});
    mockito
        .when(mockAgendaController.setInviteFilter(mockito.any))
        .thenReturn(null);
    mockito
        .when(mockAgendaController.setSearchActive(mockito.any))
        .thenReturn(null);
    mockito
        .when(mockAgendaController.isOccurrenceConfirmed(mockito.any))
        .thenReturn(false);
    mockito
        .when(mockAgendaController.pendingInviteCount(mockito.any))
        .thenReturn(0);
    mockito
        .when(mockAgendaController.distanceLabelFor(mockito.any))
        .thenReturn('1km');
    mockito.when(mockAgendaController.loadNextPage()).thenAnswer((_) async {});
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    testScrollController.dispose();
    await GetIt.I.reset();
  });

  testWidgets('TenantHomeScreen renders correctly', (tester) async {
    final now = DateTime.now();
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      title: 'Evento do Teste Longo',
      imageUri: Uri.parse('http://example.com/img.jpg'),
      startDateTime: now.add(const Duration(hours: 2)),
      location: 'Local do Evento Teste Longo',
    );
    mockito.when(mockController.myEventsFilteredStreamValue).thenReturn(
          StreamValue<List<VenueEventResume>>(defaultValue: [event]),
        );
    final mockRouter = MockStackRouter();
    _stubMockRouterRoot(mockRouter);
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(mockRouter),
    );
    await tester.pump();

    // Verify AppBar
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.text('Usando sua localização.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Verify My Events Section
    expect(find.text('Meus Eventos'), findsOneWidget);

    // Verify Favorites Section
    expect(find.text('Seus Favoritos'), findsOneWidget);
    final favoritesHeader = find.ancestor(
      of: find.text('Seus Favoritos'),
      matching: find.byType(SectionHeader),
    );
    expect(
      find.descendant(
        of: favoritesHeader,
        matching: find.byIcon(Icons.arrow_forward),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'tenant home agenda header compacts radius action from agenda controller stream',
      (tester) async {
    final mockRouter = MockStackRouter();
    _stubMockRouterRoot(mockRouter);
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(mockRouter),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('agenda-radius-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('agenda-radius-compact')),
      findsNothing,
    );

    mockAgendaController.setRadiusActionCompactState(true);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('agenda-radius-compact')),
      findsOneWidget,
    );

    mockAgendaController.setRadiusActionCompactState(false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('agenda-radius-expanded')),
      findsOneWidget,
    );
  });

  testWidgets('taps My Events card and pushes detail route', (tester) async {
    final now = DateTime.now();
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      title: 'Evento do Teste Longo',
      imageUri: Uri.parse('http://example.com/img.jpg'),
      startDateTime: now.add(const Duration(hours: 2)),
      location: 'Local do Evento Teste Longo',
      selectedOccurrenceId: 'occ-home-2',
    );
    mockito.when(mockController.myEventsFilteredStreamValue).thenReturn(
          StreamValue<List<VenueEventResume>>(defaultValue: [event]),
        );

    final mockRouter = MockStackRouter();
    _stubMockRouterRoot(mockRouter);
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(mockRouter),
    );

    await tester.pump();

    final cardFinder = find.byType(MyEventsCarouselCard);
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pump();

    final pushedRoute = mockito
        .verify(mockRouter.push(mockito.captureAny))
        .captured
        .single as ImmersiveEventDetailRoute;
    expect(pushedRoute.args?.eventSlug, 'event-1');
    expect(pushedRoute.args?.occurrenceId, 'occ-home-2');
    expect(pushedRoute.rawQueryParams, {'occurrence': 'occ-home-2'});
  });

  testWidgets('renders pending invites banner when pending invites exist',
      (tester) async {
    final pendingInviteStream = StreamValue<List<InviteModel>>(
      defaultValue: [
        buildInviteModelFromPrimitives(
          id: 'pending-1',
          eventId: 'event-pending-1',
          eventName: 'Evento pendente',
          eventDateTime: DateTime(2026, 3, 16, 20),
          eventImageUrl: 'http://example.com/pending.jpg',
          location: 'Guarapari',
          hostName: 'Host',
          message: 'Convite pendente',
          tags: const ['music'],
          inviterName: 'Convidador',
        ),
      ],
    );
    mockito
        .when(mockInvitesBannerController.pendingInvitesStreamValue)
        .thenReturn(pendingInviteStream);

    final mockRouter = MockStackRouter();
    _stubMockRouterRoot(mockRouter);
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(mockRouter),
    );
    await tester.pump();

    expect(find.text('Voce tem 1 convites pendentes'), findsOneWidget);
  });

  testWidgets('tapping home location status opens explanatory dialog',
      (tester) async {
    mockito.when(mockController.homeLocationStatusStreamValue).thenReturn(
          StreamValue<HomeLocationStatusState?>(
            defaultValue: const HomeLocationStatusState(
              statusText: 'Usando localização fixa.',
              dialogTitle: 'Usando localização fixa',
              dialogMessage: 'Explicação da localização fixa.',
            ),
          ),
        );

    final mockRouter = MockStackRouter();
    _stubMockRouterRoot(mockRouter);
    mockito.when(mockRouter.maybePop()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(mockRouter),
    );
    await tester.pump();

    await tester.tap(find.text('Usando localização fixa.'));
    await tester.pumpAndSettle();

    expect(find.text('Usando localização fixa'), findsOneWidget);
    expect(find.text('Explicação da localização fixa.'), findsOneWidget);
  });

  testWidgets(
      'tenant home system back consumes scroll position before pop or exit',
      (tester) async {
    final router = _RecordingBackRouter(canPopResult: false);

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(router),
    );
    await tester.pumpAndSettle();

    testScrollController.jumpTo(120);
    await tester.pump();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(testScrollController.offset, 0);
    expect(router.canPopCallCount, 0);
    expect(router.popCallCount, 0);
    expect(find.text('Sair do app?'), findsNothing);
  });

  testWidgets(
      'tenant home system back opens exit confirmation when root-opened without history',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _RecordingBackRouter(
      canPopResult: false,
      navigatorKey: navigatorKey,
    );

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(router, navigatorKey: navigatorKey),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(find.text('Sair do app?'), findsOneWidget);
    expect(find.text('Deseja fechar o aplicativo agora?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do app?'), findsNothing);
  });

  testWidgets('tenant home exit confirmation delegates to SystemNavigator.pop',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _RecordingBackRouter(
      canPopResult: false,
      navigatorKey: navigatorKey,
    );
    var systemPopCallCount = 0;

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(router, navigatorKey: navigatorKey),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Sair'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemPopCallCount += 1;
        }
        return null;
      },
    );

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(systemPopCallCount, 1);
  });

  testWidgets('tenant home system back pops when previous history exists',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _RecordingBackRouter(
      canPopResult: true,
      navigatorKey: navigatorKey,
    );

    await tester.pumpWidget(
      _buildRoutedTenantHomeApp(router, navigatorKey: navigatorKey),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(find.text('Sair do app?'), findsNothing);
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  static final List<int> _transparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  _TestHttpClientRequest(this._imageBytes);

  final List<int> _imageBytes;

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse(_imageBytes);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpClientResponse(this._imageBytes);

  final List<int> _imageBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_imageBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
