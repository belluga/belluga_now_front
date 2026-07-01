import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_target_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_occurrence_id_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_public_detail_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_target_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/profile_type_definitions.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_chip.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeFavoriteRepository extends FavoriteRepositoryContract {
  _FakeFavoriteRepository({
    this.favoriteResumes = const <FavoriteResume>[],
    this.failuresBeforeSuccess = 0,
  });

  final List<FavoriteResume> favoriteResumes;
  int failuresBeforeSuccess;

  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw StateError('favorite resumes unavailable');
    }
    return favoriteResumes;
  }
}

class _FakeAppData extends Fake implements AppData {
  @override
  EnvironmentNameValue get nameValue =>
      EnvironmentNameValue()..parse('Test App');

  @override
  IconUrlValue get mainIconLightUrl =>
      IconUrlValue()..parse('http://example.com/icon.png');

  @override
  MainColorValue get mainColor => MainColorValue()..parse('#000000');

  @override
  ProfileTypeRegistry get profileTypeRegistry =>
      ProfileTypeRegistry(types: ProfileTypeDefinitions());
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository()
    : _appData = _FakeAppData(),
      themeModeStreamValue = StreamValue<ThemeMode?>(
        defaultValue: ThemeMode.light,
      ),
      maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(5000, defaultValue: 5000),
      );

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
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(5000, defaultValue: 5000);

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastRoutes;
  int pushCalls = 0;
  PageRouteInfo<dynamic>? lastPushedRoute;
  String? lastPushedPath;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastRoutes = routes;
  }

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    pushCalls += 1;
    lastPushedRoute = route;
    return null;
  }

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastPushedPath = path;
    return null;
  }
}

const double _avatarFrameSize = 72;

ThemeData _testTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF006D77),
    brightness: Brightness.light,
  ),
);

Widget _favoritesHarness({
  required FavoritesSectionController controller,
  required StackRouter router,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: FavoritesSectionView(controller: controller)),
    ),
  );
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

  testWidgets(
    'full favorite chip tap pushes canonical event path when active event exists',
    (tester) async {
      final favoriteItem = FavoriteResume(
        titleValue: TitleValue()..parse('Pizza Place'),
        assetPathValue: AssetPathValue()
          ..parse('assets/images/placeholder_avatar.png'),
        eventTargetPathValue: FavoriteEventTargetPathValue(
          '/agenda/evento/pizza-place?occurrence=occ-live',
        ),
        liveNowEventOccurrenceIdValue: FavoriteEventOccurrenceIdValue(
          'occ-live',
        ),
      );

      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [favoriteItem],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      final chipFinder = find
          .bySemanticsLabel('Pizza Place, TOCANDO AGORA')
          .first;
      final chipRect = tester.getRect(chipFinder);
      await tester.tapAt(Offset(chipRect.center.dx, chipRect.top + 18));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(router.replaceAllCalled, isFalse);
      expect(router.pushCalls, 0);
      expect(router.lastPushedRoute, isNull);
      expect(
        router.lastPushedPath,
        '/agenda/evento/pizza-place?occurrence=occ-live',
      );
    },
  );

  testWidgets(
    'path-based favorite tap preserves stack and pushes canonical path',
    (tester) async {
      final favoriteItem = FavoriteResume(
        titleValue: TitleValue()..parse('Du Jorge'),
        assetPathValue: AssetPathValue()
          ..parse('assets/images/placeholder_avatar.png'),
        targetTypeValue: FavoriteTargetTypeValue()..parse('account_profile'),
        canOpenPublicDetailValue: DomainBooleanValue(
          defaultValue: true,
          isRequired: false,
        )..parse('true'),
        publicDetailPathValue: FavoritePublicDetailPathValue(
          '/parceiro/du-jorge',
        ),
      );

      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [favoriteItem],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      await tester.tap(find.text('Du Jorge').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(router.replaceAllCalled, isFalse);
      expect(router.pushCalls, 0);
      expect(router.lastPushedRoute, isNull);
      expect(router.lastPushedPath, '/parceiro/du-jorge');
    },
  );

  testWidgets(
    'first true favorite with a stale upcoming timestamp still pushes its canonical profile path',
    (tester) async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [
            FavoriteResume(
              titleValue: TitleValue()..parse('Yuri Dias'),
              assetPathValue: AssetPathValue()
                ..parse('assets/images/placeholder_avatar.png'),
              targetTypeValue: FavoriteTargetTypeValue()
                ..parse('account_profile'),
              canOpenPublicDetailValue: DomainBooleanValue(
                defaultValue: true,
                isRequired: false,
              )..parse('true'),
              publicDetailPathValue: FavoritePublicDetailPathValue(
                '/parceiro/yuri-dias',
              ),
              nextEventOccurrenceAtValue: DomainOptionalDateTimeValue(
                defaultValue: DateTime.utc(2026, 6, 21, 16),
              )..parse(DateTime.utc(2026, 6, 21, 16).toIso8601String()),
            ),
            FavoriteResume(
              titleValue: TitleValue()..parse('Later Favorite'),
              assetPathValue: AssetPathValue()
                ..parse('assets/images/placeholder_avatar.png'),
              targetTypeValue: FavoriteTargetTypeValue()
                ..parse('account_profile'),
              canOpenPublicDetailValue: DomainBooleanValue(
                defaultValue: true,
                isRequired: false,
              )..parse('true'),
              publicDetailPathValue: FavoritePublicDetailPathValue(
                '/parceiro/later-favorite',
              ),
            ),
          ],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      await tester.tap(find.text('Yuri Dias').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(router.replaceAllCalled, isFalse);
      expect(router.pushCalls, 0);
      expect(router.lastPushedRoute, isNull);
      expect(router.lastPushedPath, '/parceiro/yuri-dias');
    },
  );

  testWidgets(
    'favorites view leaves spinner after bounded initial retry exhaustion',
    (tester) async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(failuresBeforeSuccess: 3),
        appDataRepository: _FakeAppDataRepository(),
      );
      final router = _RecordingStackRouter();
      final initFuture = controller.init();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await initFuture;
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'favorites view preserves backend order and renders distinct event halos',
    (tester) async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [
            _favoriteResume(
              title: 'Ao Vivo',
              liveNowEventOccurrenceId: 'occ-live',
            ),
            _favoriteResume(
              title: 'Tem Evento',
              nextEventOccurrenceAt: DateTime(2026, 4, 4, 20),
            ),
            _favoriteResume(title: 'Sem Evento'),
          ],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      final chips = tester
          .widgetList<FavoriteChip>(find.byType(FavoriteChip))
          .toList();

      expect(chips.map((chip) => chip.title).toList(), [
        'Test App',
        'Ao Vivo',
        'Tem Evento',
        'Sem Evento',
        'Procurar',
      ]);
      expect(chips[1].haloState, FavoriteChipHaloState.liveNow);
      expect(chips[2].haloState, FavoriteChipHaloState.upcoming);
      expect(chips[3].haloState, FavoriteChipHaloState.none);
      expect(find.bySemanticsLabel('Ao Vivo, TOCANDO AGORA'), findsOneWidget);
      expect(find.bySemanticsLabel('Tem Evento, TEM EVENTO'), findsOneWidget);
      expect(find.bySemanticsLabel('Sem Evento'), findsOneWidget);
    },
  );

  testWidgets(
    'favorites view uses accent-family upcoming halo and stronger live halo',
    (tester) async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [
            _favoriteResume(
              title: 'Ao Vivo',
              liveNowEventOccurrenceId: 'occ-live',
            ),
            _favoriteResume(
              title: 'Tem Evento',
              nextEventOccurrenceAt: DateTime(2026, 4, 4, 20),
            ),
          ],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();
      final colorScheme = _testTheme().colorScheme;

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      final liveDecoration = _haloDecorationFor(
        tester,
        'Ao Vivo, TOCANDO AGORA',
      );
      final upcomingDecoration = _haloDecorationFor(
        tester,
        'Tem Evento, TEM EVENTO',
      );
      final liveBorder = liveDecoration.border! as Border;
      final upcomingBorder = upcomingDecoration.border! as Border;
      final liveShadow = liveDecoration.boxShadow!.single;
      final upcomingShadow = upcomingDecoration.boxShadow!.single;

      expect(liveDecoration.color, colorScheme.primary.withValues(alpha: 0.12));
      expect(
        upcomingDecoration.color,
        colorScheme.secondary.withValues(alpha: 0.10),
      );
      expect(liveBorder.top.color, colorScheme.primary.withValues(alpha: 0.95));
      expect(
        upcomingBorder.top.color,
        colorScheme.secondary.withValues(alpha: 0.88),
      );
      expect(liveBorder.top.width, 2.2);
      expect(upcomingBorder.top.width, 1.5);
      expect(liveShadow.color, colorScheme.primary.withValues(alpha: 0.30));
      expect(
        upcomingShadow.color,
        colorScheme.secondary.withValues(alpha: 0.18),
      );
      expect(liveShadow.blurRadius, 16);
      expect(upcomingShadow.blurRadius, 10);
      expect(liveShadow.spreadRadius, 1.5);
      expect(upcomingShadow.spreadRadius, 0.4);
      expect(liveBorder.top.width, greaterThan(upcomingBorder.top.width));
      expect(liveShadow.blurRadius, greaterThan(upcomingShadow.blurRadius));
      expect(liveShadow.spreadRadius, greaterThan(upcomingShadow.spreadRadius));
    },
  );

  testWidgets(
    'favorites view keeps mixed-row frames and label baselines aligned across live upcoming and no-halo chips',
    (tester) async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(
          favoriteResumes: [
            _favoriteResume(
              title: 'Ao Vivo',
              liveNowEventOccurrenceId: 'occ-live',
            ),
            _favoriteResume(
              title: 'Tem Evento',
              nextEventOccurrenceAt: DateTime(2026, 4, 4, 20),
            ),
            _favoriteResume(title: 'Sem Evento'),
          ],
        ),
        appDataRepository: _FakeAppDataRepository(),
      );
      await controller.init();

      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _favoritesHarness(controller: controller, router: router),
      );
      await tester.pump();

      final liveFrameRect = _avatarFrameRectFor(
        tester,
        'Ao Vivo, TOCANDO AGORA',
      );
      final upcomingFrameRect = _avatarFrameRectFor(
        tester,
        'Tem Evento, TEM EVENTO',
      );
      final noEventFrameRect = _avatarFrameRectFor(tester, 'Sem Evento');
      final liveLabelTop = tester.getTopLeft(find.text('Ao Vivo')).dy;
      final upcomingLabelTop = tester.getTopLeft(find.text('Tem Evento')).dy;
      final noEventLabelTop = tester.getTopLeft(find.text('Sem Evento')).dy;

      expect(liveFrameRect.size, noEventFrameRect.size);
      expect(upcomingFrameRect.size, noEventFrameRect.size);
      expect(
        (liveFrameRect.center.dy - noEventFrameRect.center.dy).abs(),
        lessThan(0.1),
      );
      expect(
        (upcomingFrameRect.center.dy - noEventFrameRect.center.dy).abs(),
        lessThan(0.1),
      );
      expect((liveLabelTop - noEventLabelTop).abs(), lessThan(0.1));
      expect((upcomingLabelTop - noEventLabelTop).abs(), lessThan(0.1));
    },
  );
}

BoxDecoration _haloDecorationFor(WidgetTester tester, String semanticsLabel) {
  final chipFinder = find.ancestor(
    of: find.bySemanticsLabel(semanticsLabel),
    matching: find.byType(FavoriteChip),
  );
  final haloFinder = find.descendant(
    of: chipFinder,
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    ),
  );
  return tester.widget<Container>(haloFinder.first).decoration!
      as BoxDecoration;
}

Rect _avatarFrameRectFor(WidgetTester tester, String semanticsLabel) {
  final chipFinder = find.ancestor(
    of: find.bySemanticsLabel(semanticsLabel),
    matching: find.byType(FavoriteChip),
  );
  final frameFinder = find.descendant(
    of: chipFinder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.width == _avatarFrameSize &&
          widget.height == _avatarFrameSize,
    ),
  );
  return tester.getRect(frameFinder.first);
}

FavoriteResume _favoriteResume({
  required String title,
  DateTime? nextEventOccurrenceAt,
  String? liveNowEventOccurrenceId,
}) {
  return FavoriteResume(
    titleValue: TitleValue()..parse(title),
    assetPathValue: AssetPathValue()
      ..parse('assets/images/placeholder_avatar.png'),
    nextEventOccurrenceAtValue: DomainOptionalDateTimeValue(
      defaultValue: nextEventOccurrenceAt,
    )..parse(nextEventOccurrenceAt?.toIso8601String()),
    liveNowEventOccurrenceIdValue: liveNowEventOccurrenceId == null
        ? null
        : FavoriteEventOccurrenceIdValue(liveNowEventOccurrenceId),
  );
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

  Stream<List<int>> get stream => Stream<List<int>>.value(_imageBytes);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
