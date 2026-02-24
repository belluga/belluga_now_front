import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/tenant_home_screen.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/my_events_carousel_card.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:stream_value/core/stream_value.dart';

import 'tenant_home_screen_test.mocks.dart';

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

void main() {
  late MockTenantHomeController mockController;
  late MockTenantHomeAgendaController mockAgendaController;
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
    mockAgendaController = MockTenantHomeAgendaController();
    mockFavoritesController = _TestFavoritesSectionController();
    mockInvitesBannerController = MockInvitesBannerBuilderController();
    mockAppDataRepository = MockAppDataRepository();
    mockAppData = MockAppData();
    testScrollController = ScrollController();
    mockController = _TestTenantHomeController(mockAppData);

    GetIt.I.registerSingleton<TenantHomeController>(mockController);
    GetIt.I.registerSingleton<TenantHomeAgendaController>(mockAgendaController);
    GetIt.I.registerSingleton<FavoritesSectionController>(mockFavoritesController);
    GetIt.I.registerSingleton<InvitesBannerBuilderController>(mockInvitesBannerController);
    GetIt.I.registerSingleton<AppDataRepository>(mockAppDataRepository);
    GetIt.I.registerSingleton<AppData>(mockAppData);

    // Stub AppData
    mockito.when(mockAppDataRepository.appData).thenReturn(mockAppData);
    mockito.when(mockAppData.nameValue).thenReturn(EnvironmentNameValue()..parse('Test App'));
    mockito.when(mockAppData.mainColor).thenReturn(MainColorValue()..parse('#000000'));
    mockito.when(mockAppData.mainIconLightUrl).thenReturn(IconUrlValue()..parse('http://example.com/icon.png'));
    mockito
        .when(mockAppData.mainLogoLightUrl)
        .thenReturn(MainLogoUrlValue()..parse('http://example.com/logo-light.png'));
    mockito
        .when(mockAppData.mainLogoDarkUrl)
        .thenReturn(MainLogoUrlValue()..parse('http://example.com/logo-dark.png'));
    mockito.when(mockAppDataRepository.maxRadiusMetersStreamValue).thenReturn(StreamValue<double>(defaultValue: 5000));

    // Stub Home Controller
    mockito
        .when(mockFavoritesController.favoritesStreamValue)
        .thenReturn(StreamValue<List<FavoriteResume>?>(defaultValue: []));
    mockito.when(mockFavoritesController.init()).thenAnswer((_) async {});
    mockito.when(mockFavoritesController.buildPinnedFavorite()).thenReturn(
      FavoriteResume(
        titleValue: TitleValue()..parse('Pinned'),
        assetPathValue:
            AssetPathValue()..parse('assets/images/placeholder_avatar.png'),
        isPrimary: true,
      ),
    );
    mockito
        .when(mockInvitesBannerController.pendingInvitesStreamValue)
        .thenReturn(StreamValue<List<InviteModel>>(defaultValue: const []));

    // Stub Home Controller
    mockito.when(mockController.userAddressStreamValue).thenReturn(
      StreamValue<String?>(defaultValue: 'Rua Teste, 123'),
    );
    mockito
        .when(mockController.myEventsFilteredStreamValue)
        .thenReturn(StreamValue<List<VenueEventResume>>(defaultValue: []));
    mockito
        .when(mockController.scrollController)
        .thenReturn(testScrollController);
    
    // Callbacks
    mockito.when(mockController.distanceLabelForMyEvent(mockito.any)).thenReturn('1km');

    // Agenda controller stubs
    mockito.when(mockAgendaController.isInitialLoadingStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.isPageLoadingStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.showHistoryStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.searchActiveStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.inviteFilterStreamValue)
        .thenReturn(StreamValue(defaultValue: InviteFilter.none));
    mockito.when(mockAgendaController.radiusMetersStreamValue)
        .thenReturn(StreamValue<double>(defaultValue: 1000));
    mockito.when(mockAgendaController.maxRadiusMetersStreamValue)
        .thenReturn(StreamValue<double>(defaultValue: 5000));
    mockito.when(mockAgendaController.hasMoreStreamValue)
        .thenReturn(StreamValue<bool>(defaultValue: false));
    mockito.when(mockAgendaController.displayedEventsStreamValue)
        .thenReturn(StreamValue<List<EventModel>>(defaultValue: []));
    mockito.when(mockAgendaController.searchController)
        .thenReturn(TextEditingController());
    mockito.when(mockAgendaController.focusNode).thenReturn(FocusNode());
    mockito
        .when(mockAgendaController.init(startWithHistory: mockito.anyNamed('startWithHistory')))
        .thenAnswer((_) async {});
    mockito.when(mockAgendaController.setInviteFilter(mockito.any)).thenReturn(null);
    mockito.when(mockAgendaController.setSearchActive(mockito.any)).thenReturn(null);
    mockito.when(mockAgendaController.isEventConfirmed(mockito.any)).thenReturn(false);
    mockito.when(mockAgendaController.pendingInviteCount(mockito.any)).thenReturn(0);
    mockito.when(mockAgendaController.distanceLabelFor(mockito.any)).thenReturn('1km');
    mockito.when(mockAgendaController.loadNextPage()).thenAnswer((_) async {});
  });

  tearDown(() async {
    testScrollController.dispose();
    await GetIt.I.reset();
  });

  testWidgets('TenantHomeScreen renders correctly', (tester) async {
    final now = DateTime.now();
    final event = VenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      titleValue: TitleValue()..parse('Evento do Teste Longo'),
      imageUriValue:
          ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue:
          DateTimeValue(defaultValue: now.add(const Duration(hours: 2))),
      locationValue:
          DescriptionValue()..parse('Local do Evento Teste Longo'),
      artists: const [],
      tags: const [],
    );
    mockito.when(mockController.myEventsFilteredStreamValue).thenReturn(
          StreamValue<List<VenueEventResume>>(defaultValue: [event]),
        );
    final mockRouter = MockStackRouter();
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      StackRouterScope(
        controller: mockRouter,
        stateHash: 0,
        child: MaterialApp(
          home: TenantHomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify AppBar
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

    // Verify My Events Section
    expect(find.text('Meus Eventos'), findsOneWidget);

    // Verify Favorites Section
    expect(find.text('Seus Favoritos'), findsOneWidget);

  });

  testWidgets('taps My Events card and pushes detail route', (tester) async {
    final now = DateTime.now();
    final event = VenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      titleValue: TitleValue()..parse('Evento do Teste Longo'),
      imageUriValue:
          ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue:
          DateTimeValue(defaultValue: now.add(const Duration(hours: 2))),
      locationValue:
          DescriptionValue()..parse('Local do Evento Teste Longo'),
      artists: const [],
      tags: const [],
    );
    mockito.when(mockController.myEventsFilteredStreamValue).thenReturn(
          StreamValue<List<VenueEventResume>>(defaultValue: [event]),
        );

    final mockRouter = MockStackRouter();
    mockito.when(mockRouter.push(mockito.any)).thenAnswer((_) async => null);

    await tester.pumpWidget(
      StackRouterScope(
        controller: mockRouter,
        stateHash: 0,
        child: MaterialApp(
          home: TenantHomeScreen(),
        ),
      ),
    );

    await tester.pump();

    final cardFinder = find.byType(MyEventsCarouselCard);
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pump();

    mockito.verify(mockRouter.push(mockito.any)).called(1);
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
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
