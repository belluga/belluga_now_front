import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeFavoriteRepository implements FavoriteRepositoryContract {
  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async =>
      <FavoriteResume>[];
}

class _FakeAccountProfilesRepository implements AccountProfilesRepositoryContract {
  @override
  final StreamValue<List<AccountProfileModel>> allAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);

  @override
  final StreamValue<Set<String>> favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> init() async {}

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async =>
      <AccountProfileModel>[];

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async =>
      <AccountProfileModel>[];

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async =>
      null;

  @override
  Future<void> toggleFavorite(String accountProfileId) async {}

  @override
  bool isFavorite(String accountProfileId) => false;

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() =>
      <AccountProfileModel>[];
}

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async =>
      <VenueEventResume>[];

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async =>
      throw UnimplementedError();

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<EventModel>> getAllEvents() async => throw UnimplementedError();

  @override
  Future<EventModel?> getEventBySlug(String slug) async =>
      throw UnimplementedError();

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      throw UnimplementedError();

  @override
  Stream<EventDeltaModel> watchEventsStream({
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream.empty();
}

class _FakeAppData extends Fake implements AppData {
  @override
  EnvironmentNameValue get nameValue =>
      EnvironmentNameValue()..parse('Test App');

  @override
  IconUrlValue get mainIconLightUrl =>
      IconUrlValue()..parse('http://example.com/icon.png');

  @override
  MainColorValue get mainColor =>
      MainColorValue()..parse('#000000');
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository()
      : _appData = _FakeAppData(),
        themeModeStreamValue = StreamValue<ThemeMode?>(
          defaultValue: ThemeMode.light,
        ),
        maxRadiusMetersStreamValue =
            StreamValue<double>(defaultValue: 5000);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  final StreamValue<double> maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => 5000;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastRoutes;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastRoutes = routes;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('Emitting navigation target triggers route change',
      (tester) async {
    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      partnersRepository: _FakeAccountProfilesRepository(),
      scheduleRepository: _FakeScheduleRepository(),
      appDataRepository: _FakeAppDataRepository(),
    );
    controller.favoritesStreamValue.addValue(<FavoriteResume>[]);

    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: Scaffold(
            body: FavoritesSectionBuilder(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();

    controller.navigationTargetStreamValue.addValue(
      const FavoriteNavigationSearch(query: 'pizza'),
    );
    await tester.pump();

    expect(router.replaceAllCalled, isTrue);
    expect(router.lastRoutes?.first, isA<EventSearchRoute>());
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

  Stream<List<int>> get stream => Stream<List<int>>.value(_imageBytes);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
