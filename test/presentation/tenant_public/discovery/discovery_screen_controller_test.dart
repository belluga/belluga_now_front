import 'package:auto_route/auto_route.dart';
import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/discovery_screen.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_chips.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('available discovery types include only favoritable profile types',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('a'), type: 'artist', name: 'Artist'),
            _profile(id: _mongoId('b'), type: 'curator', name: 'Curator'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.type, 'artist');
    expect(repository.allAccountProfilesStreamValue.value, hasLength(2));
    controller.onDispose();
  });

  test('toggle favorite requires authentication for anonymous users', () async {
    final artist = _profile(id: _mongoId('c'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: false),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.requiresAuthentication);
    expect(repository.toggleCalls, isEmpty);
    controller.onDispose();
  });

  test('discovery loads additional pages with loadNextPage', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('d'), type: 'artist', name: 'First'),
          ],
          hasMore: true,
        ),
        2: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('e'), type: 'artist', name: 'Second'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.hasMoreStreamValue.value, isTrue);

    await controller.loadNextPage();
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));
    expect(controller.hasMoreStreamValue.value, isFalse);
    controller.onDispose();
  });

  test(
      'discovery re-entry keeps shared schedule stream alive and pagination healthy',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('re1'), type: 'artist', name: 'First'),
          ],
          hasMore: true,
        ),
        2: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('re2'), type: 'artist', name: 'Second'),
          ],
          hasMore: false,
        ),
      },
    );
    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('re-live'),
          slug: 're-live',
          title: 'Reentry Live',
          artistName: 'Reentry Artist',
        ),
      ],
    );

    final firstController = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );
    await firstController.init();
    firstController.onDispose();

    final secondController = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );
    await secondController.init();
    expect(secondController.filteredPartnersStreamValue.value, hasLength(1));

    await secondController.loadNextPage();

    expect(secondController.filteredPartnersStreamValue.value, hasLength(2));
    expect(secondController.isPageLoadingStreamValue.value, isFalse);
    secondController.onDispose();
  });

  test(
      'discovery re-entry with cached page does not raise fullscreen loading again',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('re-cache-1'), type: 'artist', name: 'First'),
          ],
          hasMore: false,
        ),
      },
    );

    final firstController = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    await firstController.init();
    firstController.onDispose();

    final secondController = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    final loadingTransitions = <bool>[];
    final subscription = secondController.isLoadingStreamValue.stream.listen(
      loadingTransitions.add,
    );

    await secondController.init();

    expect(secondController.filteredPartnersStreamValue.value, hasLength(1));
    expect(loadingTransitions, isNot(contains(true)));

    await subscription.cancel();
    secondController.onDispose();
  });

  test(
      'discovery nearby section uses dedicated near source and preserves backend order',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(
              id: _mongoId('re-nearby-cache-1'),
              type: 'artist',
              name: 'First',
            ),
            _profile(
              id: _mongoId('re-nearby-cache-2'),
              type: 'curator',
              name: 'Curator',
            ),
          ],
          hasMore: false,
        ),
      },
      nearbyProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _mongoId('re-nearby-remote-1'),
          name: 'Nearest Nearby',
          slug: 'nearest-nearby',
          type: 'artist',
          distanceMeters: 120,
        ),
        buildAccountProfileModelFromPrimitives(
          id: _mongoId('re-nearby-remote-2'),
          name: 'Second Nearby',
          slug: 'second-nearby',
          type: 'artist',
          distanceMeters: 480,
        ),
      ],
    );

    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(repository.nearbyFetchCalls, 1);
    expect(controller.nearbyStreamValue.value, hasLength(2));
    expect(
      controller.nearbyStreamValue.value
          .map((profile) => profile.name)
          .toList(),
      ['Nearest Nearby', 'Second Nearby'],
    );
    controller.onDispose();
  });

  test('discovery nearby section falls back to independent repository request',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: const <int, PagedAccountProfilesResult>{},
      nearbyProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _mongoId('d2'),
          name: 'Nearby Venue',
          slug: 'nearby-venue',
          type: 'artist',
          distanceMeters: 320,
        ),
      ],
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await repository.syncDiscoveryNearbyAccountProfiles();

    expect(repository.nearbyFetchCalls, 1);
    expect(controller.nearbyStreamValue.value, hasLength(1));
    expect(controller.nearbyStreamValue.value.first.name, 'Nearby Venue');
    expect(controller.nearbyStreamValue.value.first.distanceMeters, 320);
    controller.onDispose();
  });

  test('back consumption resets active filter state only', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('back-1'), type: 'artist', name: 'Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.toggleSearch();
    controller.setSearchQuery('artist');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final consumed = controller.consumeBackNavigationIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(consumed, isTrue);
    expect(controller.searchQueryStreamValue.value, isEmpty);
    expect(controller.selectedTypeFilterStreamValue.value, isNull);
    expect(controller.isSearchingStreamValue.value, isFalse);
    controller.onDispose();
  });

  test('back consumption returns false when no filter state is active',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('back-2'), type: 'artist', name: 'Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.toggleSearch();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final consumed = controller.consumeBackNavigationIfNeeded();

    expect(consumed, isFalse);
    expect(controller.isSearchingStreamValue.value, isTrue);
    controller.onDispose();
  });

  test('back consumption resets selected category filter without popping',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('back-3'), type: 'artist', name: 'Artist'),
            _profile(id: _mongoId('back-4'), type: 'venue', name: 'Venue'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.setTypeFilter('artist');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final consumed = controller.consumeBackNavigationIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(consumed, isTrue);
    expect(controller.selectedTypeFilterStreamValue.value, isNull);
    expect(controller.isSearchingStreamValue.value, isFalse);
    controller.onDispose();
  });

  test('discovery live-now section loads real event page with live_now_only',
      () async {
    final preferredRadiusMeters = 9200.0;
    final locationRepository = _FakeUserLocationRepository(
      userCoordinate: _coordinate(
        latitude: -20.671339,
        longitude: -40.495395,
      ),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(),
      maxRadiusMeters: preferredRadiusMeters,
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      locationRepository,
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      appDataRepository,
    );

    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('l1'), type: 'artist', name: 'Grid Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('evt-live'),
          slug: 'evento-live',
          title: 'Evento ao vivo',
          artistName: 'Artista Live',
        ),
      ],
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );

    await controller.init();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(scheduleRepository.liveNowFetchCalls, 1);
    expect(scheduleRepository.lastLiveNowRequest, isNotNull);
    expect(scheduleRepository.lastLiveNowRequest!.originLat,
        closeTo(-20.671339, 0.000001));
    expect(scheduleRepository.lastLiveNowRequest!.originLng,
        closeTo(-40.495395, 0.000001));
    expect(scheduleRepository.lastLiveNowRequest!.maxDistanceMeters,
        closeTo(preferredRadiusMeters, 0.000001));
    expect(controller.liveNowEventsStreamValue.value, hasLength(1));
    expect(controller.liveNowEventsStreamValue.value.first.slug, 'evento-live');
    expect(
      controller.liveNowEventsStreamValue.value.first.artists.first.displayName,
      'Artista Live',
    );
    controller.onDispose();
  });

  test(
      'discovery live-now reloads when user location arrives during first live-now fetch',
      () async {
    final locationRepository = _FakeUserLocationRepository();
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(),
      maxRadiusMeters: 9200.0,
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      locationRepository,
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      appDataRepository,
    );

    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('lr1'), type: 'artist', name: 'Grid Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('evt-live-race'),
          slug: 'evento-live-race',
          title: 'Evento ao vivo corrida',
          artistName: 'Artista Corrida',
        ),
      ],
      requireOriginForLiveNow: true,
      liveNowFetchDelay: const Duration(milliseconds: 80),
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );

    await controller.init();
    await scheduleRepository.waitUntilFirstLiveNowFetchStarts();

    locationRepository.userLocationStreamValue.addValue(
      _coordinate(
        latitude: -20.671339,
        longitude: -40.495395,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 220));

    expect(scheduleRepository.liveNowFetchCalls, 2);
    expect(scheduleRepository.lastLiveNowRequest, isNotNull);
    expect(
      scheduleRepository.lastLiveNowRequest!.originLat,
      closeTo(-20.671339, 0.000001),
    );
    expect(
      scheduleRepository.lastLiveNowRequest!.originLng,
      closeTo(-40.495395, 0.000001),
    );
    expect(controller.liveNowEventsStreamValue.value, hasLength(1));
    expect(controller.liveNowEventsStreamValue.value.first.slug,
        'evento-live-race');
    controller.onDispose();
  });

  test(
      'discovery live-now resolves ScheduleRepositoryContract registered after controller construction',
      () async {
    final locationRepository = _FakeUserLocationRepository(
      userCoordinate: _coordinate(
        latitude: -20.671339,
        longitude: -40.495395,
      ),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(),
      maxRadiusMeters: 9200.0,
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      locationRepository,
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      appDataRepository,
    );

    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: <AccountProfileModel>[],
          hasMore: false,
        ),
      },
    );

    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('evt-live-late'),
          slug: 'evento-live-late',
          title: 'Evento ao vivo tardio',
          artistName: 'Artista Tardio',
          thumbUrl: null,
        ),
      ],
    );
    GetIt.I.registerSingleton<ScheduleRepositoryContract>(
      scheduleRepository,
    );

    await controller.init();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(scheduleRepository.liveNowFetchCalls, 1);
    expect(controller.liveNowEventsStreamValue.value, hasLength(1));
    expect(controller.liveNowEventsStreamValue.value.first.slug,
        'evento-live-late');
    controller.onDispose();
  });

  testWidgets(
      'DiscoveryScreen renders "Tocando agora" when live-now stream contains events',
      (tester) async {
    final locationRepository = _FakeUserLocationRepository(
      userCoordinate: _coordinate(
        latitude: -20.671339,
        longitude: -40.495395,
      ),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(),
      maxRadiusMeters: 9200.0,
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      locationRepository,
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      appDataRepository,
    );

    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: <AccountProfileModel>[],
          hasMore: false,
        ),
      },
    );
    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('evt-live-ui'),
          slug: 'evento-live-ui',
          title: 'Evento ao vivo UI',
          artistName: 'Artista UI',
          thumbUrl: null,
        ),
      ],
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Tocando agora'), findsOneWidget);
    expect(find.text('Artista UI'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });

  testWidgets('DiscoveryFilterChips uses the shared bordered chip styling',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryFilterChips(
            selectedType: 'artist',
            availableTypes: const ['artist', 'venue'],
            onSelectType: (_) {},
            labelForType: (type) => type,
          ),
        ),
      ),
    );

    final selectedChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'artist'),
    );
    final unselectedChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Todos'),
    );

    expect(selectedChip.selectedColor, isNotNull);
    expect(selectedChip.backgroundColor, isNotNull);
    expect(selectedChip.side, isNotNull);
    expect(selectedChip.shape, isNotNull);
    expect(unselectedChip.selectedColor, isNotNull);
    expect(unselectedChip.backgroundColor, isNotNull);
    expect(unselectedChip.side, isNotNull);
    expect(unselectedChip.shape, isNotNull);
  });

  testWidgets(
      'DiscoveryScreen shows search action in Descubra header only in idle state',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(
                id: _mongoId('ui-search-1'), type: 'artist', name: 'Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.search),
      ),
      findsNothing,
    );
    expect(find.text('Descubra'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });

  testWidgets(
      'DiscoveryScreen back clears active filters before removing the route',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('ui-back-1'), type: 'artist', name: 'Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter();
    router.canPopResult = true;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'artist');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoveryScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.byType(DiscoveryScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Descubra'), findsOneWidget);
    expect(router.canPopCallCount, 0);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, isEmpty);

    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets(
      'DiscoveryScreen back falls back to TenantHomeRoute when there is no prior stack entry',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(
              id: _mongoId('ui-back-fallback-1'),
              type: 'artist',
              name: 'Artist',
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter();
    router.canPopResult = false;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(router.replaceAllRoutes.single, hasLength(1));
    expect(
        router.replaceAllRoutes.single.single.routeName, TenantHomeRoute.name);
  });

  testWidgets(
      'DiscoveryScreen visible back button clears active search before removing the route',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(
              id: _mongoId('ui-back-button-1'),
              type: 'artist',
              name: 'Artist',
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter()..canPopResult = true;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'artist');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-safe-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Descubra'), findsOneWidget);
    expect(router.canPopCallCount, 0);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-safe-back-button')),
    );
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets(
      'DiscoveryScreen visible back button falls back to TenantHomeRoute when root-opened',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(
              id: _mongoId('ui-back-button-fallback-1'),
              type: 'artist',
              name: 'Artist',
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );
    GetIt.I.registerSingleton<DiscoveryScreenController>(controller);

    final router = _RecordingStackRouter()..canPopResult = false;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/descobrir'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const DiscoveryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-safe-back-button')),
    );
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(router.replaceAllRoutes.single, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      TenantHomeRoute.name,
    );
  });

  test(
      'discovery search keeps backend matches even when local name/tags do not match',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            buildAccountProfileModelFromPrimitives(
              id: _mongoId('f'),
              name: 'Resultado remoto',
              slug: 'slug-exato-remoto',
              type: 'artist',
              tags: const <String>[],
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.setSearchQuery('slug-exato-remoto');
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(deadline)) {
      final latestQuery = repository.pageRequests.isEmpty
          ? null
          : repository.pageRequests.last.query;
      final partners = controller.filteredPartnersStreamValue.value;
      if (latestQuery == 'slug-exato-remoto' && partners.length == 1) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.slug,
        'slug-exato-remoto');
    expect(repository.pageRequests.last.query, 'slug-exato-remoto');
    controller.onDispose();
  });

  test('discovery selecting "Todos" resets to unfiltered list', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('t1'), type: 'artist', name: 'Artist One'),
            _profile(id: _mongoId('t2'), type: 'venue', name: 'Venue One'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));

    controller.setTypeFilter('artist');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.type, 'artist');

    controller.setTypeFilter(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));
    expect(repository.pageRequests.last.typeFilter, isNull);
    controller.onDispose();
  });

  test(
      'discovery stops loading and keeps favoritable chips when first page fails',
      () async {
    final repository = _FailingAccountProfilesRepository();
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, isEmpty);
    controller.onDispose();
  });

  test('discovery still loads first page when repository init fails', () async {
    final repository = _InitFailingAccountProfilesRepository(
      firstPage: pagedAccountProfilesResultFromRaw(
        profiles: [
          _profile(id: _mongoId('h'), type: 'artist', name: 'Recovered'),
        ],
        hasMore: false,
      ),
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(
        controller.filteredPartnersStreamValue.value.first.name, 'Recovered');
    expect(repository.fetchPageCalls, 1);
    controller.onDispose();
  });

  test('toggle favorite persists mutation for identified users', () async {
    final artist = _profile(id: _mongoId('g'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = _buildDiscoveryController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.toggled);
    await Future<void>.delayed(Duration.zero);
    expect(repository.toggleCalls, [artist.id]);
    expect(controller.favoriteIdsStreamValue.value.contains(artist.id), isTrue);
    controller.onDispose();
  });
}

DiscoveryScreenController _buildDiscoveryController({
  required AccountProfilesRepositoryContract accountProfilesRepository,
  required AuthRepositoryContract authRepository,
  ScheduleRepositoryContract? scheduleRepository,
}) {
  if (!GetIt.I.isRegistered<AppDataRepositoryContract>()) {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        appData: _buildAppData(),
        maxRadiusMeters: _buildAppData().mapRadiusDefaultMeters,
      ),
    );
  }
  if (!GetIt.I.isRegistered<LocationOriginServiceContract>()) {
    GetIt.I.registerSingleton<LocationOriginServiceContract>(
      LocationOriginService(
        appDataRepository: GetIt.I.get<AppDataRepositoryContract>(),
        userLocationRepository:
            GetIt.I.isRegistered<UserLocationRepositoryContract>()
                ? GetIt.I.get<UserLocationRepositoryContract>()
                : null,
      ),
    );
  }
  return DiscoveryScreenController(
    accountProfilesRepository: accountProfilesRepository,
    authRepository: authRepository,
    scheduleRepository: scheduleRepository,
    locationOriginService: GetIt.I.get<LocationOriginServiceContract>(),
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes = [];

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async {
    popCallCount += 1;
    return canPopResult;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllRoutes.add(List<PageRouteInfo<dynamic>>.from(routes));
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.fullPath,
    Map<String, dynamic> queryParams = const {},
  }) : _queryParams = Parameters(queryParams);

  @override
  final String fullPath;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    required this.pages,
    this.nearbyProfiles = const <AccountProfileModel>[],
  });

  final Map<int, PagedAccountProfilesResult> pages;
  final List<AccountProfileModel> nearbyProfiles;
  final List<String> toggleCalls = <String>[];
  final List<_PageRequest> pageRequests = <_PageRequest>[];
  final Map<String, AccountProfileModel> _bySlug =
      <String, AccountProfileModel>{};
  int nearbyFetchCalls = 0;

  @override
  Future<void> init() async {
    favoriteAccountProfileIdsStreamValue
        .addValue(<AccountProfilesRepositoryContractPrimString>{});
    final all = _allProfiles();
    allAccountProfilesStreamValue.addValue(all);
    for (final profile in all) {
      _bySlug[profile.slug] = profile;
    }
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final pageValue = page.value;
    final pageSizeValue = pageSize.value;
    final normalizedQueryInput = query?.value;
    final normalizedTypeInput = typeFilter?.value;
    pageRequests.add(
      _PageRequest(
        page: pageValue,
        pageSize: pageSizeValue,
        query: normalizedQueryInput?.trim(),
        typeFilter: normalizedTypeInput?.trim(),
      ),
    );
    var result = pages[pageValue] ??
        pagedAccountProfilesResultFromRaw(
          profiles: const <AccountProfileModel>[],
          hasMore: false,
        );

    var profiles = result.profiles;
    final normalizedType = normalizedTypeInput?.trim();
    if (normalizedType != null && normalizedType.isNotEmpty) {
      profiles = profiles
          .where((profile) => profile.type == normalizedType)
          .toList(growable: false);
    }

    final normalizedQuery = normalizedQueryInput?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      profiles = profiles.where((profile) {
        return profile.name.toLowerCase().contains(normalizedQuery) ||
            profile.slug.toLowerCase().contains(normalizedQuery) ||
            profile.tags.any(
              (tag) => tag.value.toLowerCase().contains(normalizedQuery),
            );
      }).toList(growable: false);
    }

    result = pagedAccountProfilesResultFromRaw(
      profiles: profiles,
      hasMore: result.hasMore,
    );

    return result;
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return _bySlug[slug.value];
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async {
    nearbyFetchCalls += 1;
    final source = nearbyProfiles.isEmpty ? _allProfiles() : nearbyProfiles;
    return source.take(pageSize?.value ?? 10).toList(growable: false);
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    toggleCalls.add(accountProfileId.value);
    final current = Set<AccountProfilesRepositoryContractPrimString>.from(
      favoriteAccountProfileIdsStreamValue.value,
    );
    current.removeWhere((id) => id.value == accountProfileId.value);
    final wasPresent = favoriteAccountProfileIdsStreamValue.value
        .any((id) => id.value == accountProfileId.value);
    if (!wasPresent) {
      current.add(
        AccountProfilesRepositoryContractPrimString.fromRaw(
          accountProfileId.value,
          defaultValue: accountProfileId.value,
          isRequired: true,
        ),
      );
    }
    favoriteAccountProfileIdsStreamValue.addValue(current);
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      favoriteAccountProfileIdsStreamValue.value
          .any((id) => id.value == accountProfileId.value),
      defaultValue: false,
      isRequired: true,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    final ids = favoriteAccountProfileIdsStreamValue.value;
    return allAccountProfilesStreamValue.value
        .where((profile) => ids.any((id) => id.value == profile.id))
        .toList(growable: false);
  }

  List<AccountProfileModel> _allProfiles() {
    return pages.values
        .expand((entry) => entry.profiles)
        .toList(growable: false);
  }
}

class _FailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  @override
  Future<void> init() async {
    allAccountProfilesStreamValue.addValue(const <AccountProfileModel>[]);
    favoriteAccountProfileIdsStreamValue
        .addValue(<AccountProfilesRepositoryContractPrimString>{});
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    throw Exception('forced discovery page failure');
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
      isRequired: true,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _InitFailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  _InitFailingAccountProfilesRepository({
    required this.firstPage,
  });

  final PagedAccountProfilesResult firstPage;
  int fetchPageCalls = 0;

  @override
  Future<void> init() async {
    throw Exception('forced repository init failure');
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    fetchPageCalls += 1;
    if (page.value != 1) {
      return pagedAccountProfilesResultFromRaw(
        profiles: const <AccountProfileModel>[],
        hasMore: false,
      );
    }
    return firstPage;
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async {
    return firstPage.profiles
        .take(pageSize?.value ?? 10)
        .toList(growable: false);
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
      isRequired: true,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.isAuthorizedValue,
  });

  final bool isAuthorizedValue;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => 'token';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => isAuthorizedValue;

  @override
  bool get isAuthorized => isAuthorizedValue;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _FakeDiscoveryScheduleRepository extends ScheduleRepositoryContract {
  _FakeDiscoveryScheduleRepository({
    required this.liveNowEvents,
    this.requireOriginForLiveNow = false,
    this.liveNowFetchDelay = Duration.zero,
  });

  final List<EventModel> liveNowEvents;
  final bool requireOriginForLiveNow;
  final Duration liveNowFetchDelay;
  int liveNowFetchCalls = 0;
  _LiveNowRequest? lastLiveNowRequest;
  HomeAgendaCacheSnapshot? _cacheSnapshot;
  final Completer<void> _firstLiveNowFetchStarted = Completer<void>();

  Future<void> waitUntilFirstLiveNowFetchStarts() =>
      _firstLiveNowFetchStarted.future;

  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final snapshot = _cacheSnapshot;
    if (snapshot == null) {
      return null;
    }
    if (snapshot.showPastOnly != showPastOnly.value) {
      return null;
    }
    if (snapshot.searchQuery != searchQuery.value) {
      return null;
    }
    if (snapshot.confirmedOnly != confirmedOnly.value) {
      return null;
    }
    return snapshot;
  }

  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    _cacheSnapshot = snapshot;
    homeAgendaStreamValue.addValue(snapshot);
  }

  void clearHomeAgendaCache() {
    _cacheSnapshot = null;
    homeAgendaStreamValue.addValue(null);
  }

  @override
  Future<HomeAgendaCacheSnapshot> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<HomeAgendaCacheSnapshot?> loadNextHomeAgendaPage({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async {
    return null;
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    if (liveNowOnly?.value ?? false) {
      liveNowFetchCalls += 1;
      if (!_firstLiveNowFetchStarted.isCompleted) {
        _firstLiveNowFetchStarted.complete();
      }
      lastLiveNowRequest = _LiveNowRequest(
        page: page.value,
        pageSize: pageSize.value,
        showPastOnly: showPastOnly.value,
        originLat: originLat?.value,
        originLng: originLng?.value,
        maxDistanceMeters: maxDistanceMeters?.value,
      );
      if (liveNowFetchDelay > Duration.zero) {
        await Future<void>.delayed(liveNowFetchDelay);
      }
      final hasOrigin = originLat != null && originLng != null;
      final events = requireOriginForLiveNow && !hasOrigin
          ? const <EventModel>[]
          : liveNowEvents.take(pageSize.value).toList(growable: false);
      return pagedEventsResultFromRaw(
        events: events,
        hasMore: false,
      );
    }
    return pagedEventsResultFromRaw(
      events: const <EventModel>[],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return const Stream<EventDeltaModel>.empty();
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return watchEventsStream(
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
      lastEventId: lastEventId,
      showPastOnly: showPastOnly,
    ).map((delta) {
      onDelta(delta);
    });
  }
}

class _LiveNowRequest {
  const _LiveNowRequest({
    required this.page,
    required this.pageSize,
    required this.showPastOnly,
    required this.originLat,
    required this.originLng,
    required this.maxDistanceMeters,
  });

  final int page;
  final int pageSize;
  final bool showPastOnly;
  final double? originLat;
  final double? originLng;
  final double? maxDistanceMeters;
}

class _PageRequest {
  const _PageRequest({
    required this.page,
    required this.pageSize,
    required this.query,
    required this.typeFilter,
  });

  final int page;
  final int pageSize;
  final String? query;
  final String? typeFilter;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    required AppData appData,
    required double maxRadiusMeters,
  })  : _appData = appData,
        _maxRadiusMeters = maxRadiusMeters {
    maxRadiusMetersStreamValue.addValue(
      DistanceInMetersValue.fromRaw(
        maxRadiusMeters,
        defaultValue: maxRadiusMeters,
      ),
    );
  }

  final AppData _appData;
  double _maxRadiusMeters;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.system);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(0, defaultValue: 0),
  );

  @override
  DistanceInMetersValue get maxRadiusMeters => DistanceInMetersValue.fromRaw(
        _maxRadiusMeters,
        defaultValue: _maxRadiusMeters,
      );

  @override
  bool get hasPersistedMaxRadiusPreference => true;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMeters = meters.value;
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  _FakeUserLocationRepository({
    CityCoordinate? userCoordinate,
    CityCoordinate? lastKnownCoordinate,
  }) {
    userLocationStreamValue.addValue(userCoordinate);
    lastKnownLocationStreamValue.addValue(lastKnownCoordinate);
  }

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {
    lastKnownAddressStreamValue.addValue(address?.value);
  }

  @override
  Future<bool> warmUpIfPermitted() async {
    return userLocationStreamValue.value != null ||
        lastKnownLocationStreamValue.value != null;
  }

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async {
    return warmUpIfPermitted();
  }

  @override
  Future<String?> resolveUserLocation() async {
    return null;
  }

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async {
    return true;
  }

  @override
  Future<void> stopTracking() async {}
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
      {
        'type': 'curator',
        'label': 'Curator',
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': false,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

CityCoordinate _coordinate({
  required double latitude,
  required double longitude,
}) {
  return CityCoordinate(
    latitudeValue: LatitudeValue()..parse(latitude.toString()),
    longitudeValue: LongitudeValue()..parse(longitude.toString()),
  );
}

AccountProfileModel _profile({
  required String id,
  required String type,
  required String name,
}) {
  return buildAccountProfileModelFromPrimitives(
    id: id,
    name: name,
    slug: '$name-$type'.toLowerCase().replaceAll(' ', '-'),
    type: type,
  );
}

EventModel _event({
  required String id,
  required String slug,
  required String title,
  required String artistName,
  String? thumbUrl = 'https://tenant.test/live.jpg',
}) {
  return EventDTO.fromJson({
    'event_id': id,
    'slug': slug,
    'type': {
      'id': 'type-live',
      'name': 'Show',
      'slug': 'show',
      'description': 'Show',
      'icon': null,
      'color': null,
    },
    'title': title,
    'content': 'Conteudo',
    'location': 'Local',
    'date_time_start': DateTime.now().toIso8601String(),
    'date_time_end':
        DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'artists': [
      {
        'id': _mongoId('artist-live'),
        'display_name': artistName,
        'avatar_url': null,
        'highlight': true,
        'genres': ['samba'],
      },
    ],
    if (thumbUrl != null)
      'thumb': {
        'type': 'image',
        'data': {'url': thumbUrl},
      },
  }).toDomain();
}

String _mongoId(String seed) {
  final base =
      seed.codeUnits.fold<int>(0, (acc, item) => acc + item).toRadixString(16);
  final repeated = List<String>.filled(24, base).join().substring(0, 24);
  return repeated;
}
