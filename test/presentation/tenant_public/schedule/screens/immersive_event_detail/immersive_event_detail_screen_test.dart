import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _TestHttpOverrides();
    await initializeDateFormatting('pt_BR');
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets(
      'anonymous confirm presence redirects to login without persisting attendance',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: false),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Confirmar Presença'), findsOneWidget);

    await tester.tap(find.textContaining('Confirmar Presença'));
    await tester.pump();

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: asyncExceptions.join('\n---\n'),
    );
    expect(userEventsRepository.confirmCalls, 0);
    expect(invitesRepository.acceptInviteCalls, 0);
    expect(
      router.lastReplacedPath,
      '/auth/login?redirect=%2Fagenda%2Fevento%2Fevento-de-teste',
    );
  });

  testWidgets('event detail shows pending invite actions for current event',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    invitesRepository.pendingInvitesStreamValue.addValue([
      _buildInviteForEvent(
        id: 'invite-current-event',
        eventId: '507f1f77bcf86cd799439011',
      ),
      _buildInviteForEvent(
        id: 'invite-other-event',
        eventId: '507f1f77bcf86cd799439012',
      ),
    ]);
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Agora não'), findsOneWidget);
    expect(find.text('Bóora!'), findsOneWidget);
  });

  testWidgets(
      'event detail visible back falls back to home when no history exists',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter()..canPopResult = false;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
        router.replaceAllRoutes.single.single.routeName, TenantHomeRoute.name);
  });

  testWidgets(
      'event detail system back falls back to home when no history exists',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter()..canPopResult = false;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
        router.replaceAllRoutes.single.single.routeName, TenantHomeRoute.name);
  });

  testWidgets(
      'event detail visible back returns to previous route when history exists',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter()..canPopResult = true;
    final routeData = RouteData(
      route: _FakeRouteMatch(
        name: ImmersiveEventDetailRoute.name,
        fullPath: '/agenda/evento/evento-de-teste',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.immersiveEventDetail,
        ),
      ),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets(
      'event detail system back returns to previous route when history exists',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter()..canPopResult = true;
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets('horizontal swipe moves immersive event detail to the next tab',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(event: _buildEvent()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('immersiveTabSelected_1')), findsNothing);

    final swipeSurface = tester.widget<GestureDetector>(
      find.byKey(const Key('immersiveSwipeSurface')),
    );
    swipeSurface.onHorizontalDragEnd?.call(
      DragEndDetails(
        velocity: const Velocity(pixelsPerSecond: Offset(-1000, 0)),
        primaryVelocity: -1000,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveTabSelected_1')), findsOneWidget);
  });

  testWidgets(
      'event detail replaces Line-up with dynamic profile category tabs and cards',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final accountProfilesRepository = _FakeAccountProfilesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
        accountProfilesRepository: accountProfilesRepository,
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                venue: _buildVenueResume(),
                linkedProfiles: [
                  _buildLinkedAccountProfile(
                    id: 'artist-1',
                    displayName: 'Ananda Torres',
                    profileType: 'artist',
                    slug: 'ananda-torres',
                    avatarUrl: 'https://example.com/ananda.png',
                    coverUrl: 'https://example.com/ananda-cover.png',
                    taxonomyTerms: [
                      _buildLinkedAccountProfileTaxonomyTerm(
                        type: 'genre',
                        value: 'samba',
                        name: 'Samba',
                      ),
                    ],
                  ),
                  _buildLinkedAccountProfile(
                    id: 'venue-1',
                    displayName: 'Carvoeiro',
                    profileType: 'restaurant',
                    slug: 'carvoeiro',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Line-up'), findsNothing);
    expect(find.text('Artists'), findsNWidgets(2));
    expect(find.byKey(const Key('immersiveTabLabel_1')), findsOneWidget);
    expect(find.text('Como Chegar'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(find.text('Ananda Torres'), findsWidgets);
    expect(find.text('Samba'), findsOneWidget);
    expect(
      find.byKey(const Key('linkedProfileFavoriteButton_artist-1')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const Key('linkedProfileCardTapTarget_artist-1')));
    await tester.pumpAndSettle();

    expect(router.lastPushedRoute, isA<PartnerDetailRoute>());
    expect(
      (router.lastPushedRoute! as PartnerDetailRoute).args!.slug,
      'ananda-torres',
    );

    await tester
        .tap(find.byKey(const Key('linkedProfileFavoriteButton_artist-1')));
    await tester.pumpAndSettle();
    expect(accountProfilesRepository.toggleFavoriteCalls, 1);
  });

  testWidgets(
      'event detail uses Sobre html content, Como Chegar naming, and hero summary metadata',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                venue: _buildVenueResume(),
                linkedProfiles: [
                  _buildLinkedAccountProfile(
                    id: 'artist-1',
                    displayName: 'Ananda Torres',
                    profileType: 'artist',
                    slug: 'ananda-torres',
                    avatarUrl: 'https://example.com/ananda.png',
                  ),
                ],
                contentHtml:
                    '<p><strong>Evento 🎉</strong> <u>aleatório</u> <a href="https://example.com">longe</a> <s>riscado</s></p>',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('O Rolê'), findsNothing);
    expect(find.text('O Local'), findsNothing);
    expect(find.text('Sobre'), findsWidgets);
    expect(find.text('Como Chegar'), findsNWidgets(2));
    expect(find.byType(Html), findsOneWidget);
    final htmlWidget = tester.widget<Html>(find.byType(Html));
    expect(htmlWidget.data, contains('<s>riscado</s>'));
    expect(htmlWidget.data, isNot(contains('<u>')));
    expect(htmlWidget.data, isNot(contains('<a')));
    expect(htmlWidget.data, contains('🎉'));
    expect(find.text('Show tipo'), findsOneWidget);
    expect(find.text('Ananda Torres'), findsWidgets);
    expect(find.textContaining('Carvoeiro'), findsWidgets);

    await tester.tap(find.byKey(const Key('immersiveTabLabel_2')));
    await tester.pumpAndSettle();

    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.text('Traçar rota'), findsNothing);
    expect(find.textContaining('Confirmar Presença'), findsOneWidget);
    expect(find.text('Ver perfil do local'), findsNothing);
  });

  testWidgets('event detail dates tab highlights current occurrence',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                occurrences: [
                  _buildOccurrence(
                    id: 'occ-1',
                    start: DateTime(2026, 3, 15, 20),
                    end: DateTime(2026, 3, 15, 22),
                  ),
                  _buildOccurrence(
                    id: 'occ-2',
                    start: DateTime(2026, 3, 16, 20),
                    end: DateTime(2026, 3, 16, 22),
                    isSelected: true,
                    hasLocationOverride: true,
                    programmingCount: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Datas'), findsWidgets);
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventDateCard_occ-1')), findsOneWidget);
    expect(find.byKey(const Key('eventDateCard_occ-2')), findsOneWidget);
    expect(
        find.byKey(const Key('eventDateCurrentBadge_occ-2')), findsOneWidget);
    expect(find.text('Atual'), findsOneWidget);
    expect(find.text('Local específico'), findsOneWidget);
    expect(find.text('1 item na programação'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('eventDateCard_occ-1')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('immersiveSwipeSurface')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('eventDateCard_occ-1')));
    await tester.pump();

    expect(
      router.lastReplacedPath,
      '/agenda/evento/evento-de-teste?occurrence=occ-1',
    );
  });

  testWidgets('event detail programming tab renders occurrence schedule',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );
    final profile = _buildLinkedAccountProfile(
      id: 'artist-1',
      displayName: 'Coral XYZ',
      profileType: 'artist',
      slug: 'coral-xyz',
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                programmingItems: [
                  _buildProgrammingItem(
                    time: '17:00',
                    linkedProfiles: [profile],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Programação'), findsWidgets);
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventProgrammingItem_17:00')), findsOneWidget);
    expect(find.text('17:00'), findsOneWidget);
    expect(find.text('Coral XYZ'), findsWidgets);
    expect(
      find.byKey(const Key('eventProgrammingProfile_artist-1')),
      findsOneWidget,
    );
  });

  testWidgets('event detail omits Sobre when content is effectively empty',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                venue: _buildVenueResume(),
                contentHtml: '<p>&nbsp;</p><p><br></p>',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sobre'), findsNothing);
    expect(find.text('Sem descrição disponível.'), findsNothing);
    expect(find.byType(Html), findsNothing);
    expect(find.text('Como Chegar'), findsNWidgets(2));
    expect(find.byKey(const Key('immersiveTabLabel_0')), findsOneWidget);
  });

  testWidgets(
      'event detail only promotes Como Chegar footer after confirmation',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      ),
    );

    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/agenda/evento/evento-de-teste'),
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                venue: _buildVenueResume(),
                isConfirmed: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')).last);
    await tester.pumpAndSettle();

    expect(find.text('Traçar rota'), findsOneWidget);
    expect(find.textContaining('Confirmar Presença'), findsNothing);
  });
}

class _RecordingStackRouter extends Mock implements StackRouter {
  String? lastPushedPath;
  String? lastReplacedPath;
  PageRouteInfo? lastPushedRoute;
  bool canPopResult = true;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes = [];

  @override
  RootStackRouter get root =>
      _FakeRootStackRouter('/agenda/evento/evento-de-teste');

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastPushedPath = path;
    return null;
  }

  @override
  Future<T?> replacePath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastReplacedPath = path;
    return null;
  }

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    lastPushedRoute = route;
    return null;
  }

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopResult;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCallCount += 1;
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

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    String? name,
    required this.fullPath,
    Map<String, dynamic>? meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
    Map<String, dynamic> queryParams = const {},
  })  : name = name ?? ImmersiveEventDetailRoute.name,
        meta = meta ??
            canonicalRouteMeta(
              family: CanonicalRouteFamily.immersiveEventDetail,
            ),
        pageRouteInfo = pageRouteInfo ?? EventSearchRoute(),
        _queryParams = Parameters(queryParams);

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  int confirmCalls = 0;

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {
    confirmCalls += 1;
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int acceptInviteCalls = 0;
  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    acceptInviteCalls += 1;
    return buildInviteAcceptResult(
      inviteId: inviteId.value,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
      InvitesRepositoryContractPrimString code) async {
    acceptInviteCalls += 1;
    return buildInviteAcceptResult(
      inviteId: 'mock-${code.value}',
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    return buildInviteShareCodeResult(code: 'CODE123', eventId: eventId.value);
  }

  @override
  Future<InviteDeclineResult> declineInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    return buildInviteDeclineResult(
      inviteId: inviteId.value,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize}) async {
    return const <InviteModel>[];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return buildInviteRuntimeSettings(
      tenantId: null,
      limits: {},
      cooldowns: {},
      overQuotaMessage: null,
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventId) async {
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<void> sendInvites(
      InvitesRepositoryContractPrimString eventId, InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthorized => authorized;

  @override
  bool get isUserLoggedIn => authorized;

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}

  @override
  String get userToken => authorized ? 'token' : '';
}

AppData _buildAppData() {
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': [
        {
          'type': 'artist',
          'label': 'Artist',
          'labels': {
            'singular': 'Artist',
            'plural': 'Artists',
          },
          'visual': {
            'mode': 'icon',
            'icon': 'music_note',
            'color': '#FF3355',
            'icon_color': '#FFFFFF',
          },
          'capabilities': {'has_events': true, 'is_favoritable': true},
        },
        {
          'type': 'restaurant',
          'label': 'Restaurant',
          'labels': {
            'singular': 'Restaurant',
            'plural': 'Restaurants',
          },
          'visual': {
            'mode': 'icon',
            'icon': 'restaurant',
            'color': '#3355FF',
            'icon_color': '#FFFFFF',
          },
          'capabilities': {
            'is_poi_enabled': true,
            'is_favoritable': true,
          },
        },
      ],
      'theme_data_settings': const {
        'primary_seed_color': '#FFFFFF',
        'secondary_seed_color': '#3355FF',
      },
    },
    localInfo: {
      'platformType': 'mobile',
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'device': 'test-device',
    },
  );
}

PartnerResume _buildVenueResume() {
  return PartnerResume(
    idValue: MongoIDValue()..parse('507f1f77bcf86cd799439099'),
    nameValue: InvitePartnerNameValue()..parse('Carvoeiro'),
    slugValue: SlugValue()..parse('carvoeiro'),
    type: InviteAccountProfileType.mercadoProducer,
    logoImageValue: InvitePartnerLogoImageValue()
      ..parse('https://example.com/carvoeiro-logo.png'),
  );
}

EventLinkedAccountProfile _buildLinkedAccountProfile({
  required String id,
  required String displayName,
  required String profileType,
  required String slug,
  String? avatarUrl,
  String? coverUrl,
  String? partyType,
  List<EventLinkedAccountProfileTaxonomyTerm> taxonomyTerms = const [],
}) {
  final taxonomyTermsGroup = EventLinkedAccountProfileTaxonomyTerms();
  for (final term in taxonomyTerms) {
    taxonomyTermsGroup.addTerm(
      typeValue: term.typeValue,
      valueValue: term.valueValue,
      nameValue: term.nameValue,
    );
  }

  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: SlugValue()..parse(slug),
    avatarUrlValue: _thumbUriValueOrNull(avatarUrl),
    coverUrlValue: _thumbUriValueOrNull(coverUrl),
    partyTypeValue: partyType == null
        ? null
        : EventLinkedAccountProfileTextValue(partyType),
    taxonomyTerms: taxonomyTermsGroup,
  );
}

EventLinkedAccountProfileTaxonomyTerm _buildLinkedAccountProfileTaxonomyTerm({
  required String type,
  required String value,
  String name = '',
}) {
  return EventLinkedAccountProfileTaxonomyTerm(
    typeValue: AccountProfileTagValue(type),
    valueValue: AccountProfileTagValue(value),
    nameValue: AccountProfileTagValue(name),
  );
}

ThumbUriValue? _thumbUriValueOrNull(String? rawUrl) {
  final normalized = rawUrl?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return ThumbUriValue(defaultValue: Uri.parse(normalized), isRequired: true)
    ..parse(normalized);
}

EventModel _buildEvent({
  PartnerResume? venue,
  List<EventLinkedAccountProfile> linkedProfiles = const [],
  List<EventOccurrenceOption> occurrences = const [],
  List<EventProgrammingItem> programmingItems = const [],
  String? contentHtml,
  bool isConfirmed = false,
}) {
  return eventModelFromRaw(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    slugValue: SlugValue()..parse('evento-de-teste'),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('show'),
      name: TitleValue()..parse('Show tipo'),
      slug: SlugValue()..parse('show'),
      description: DescriptionValue()..parse('Descricao longa do tipo.'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: Colors.blue)..parse('#3366FF'),
    ),
    title: TitleValue()..parse('Evento de Teste'),
    content: HTMLContentValue()
      ..set(contentHtml ?? 'Descricao longa do evento para teste.'),
    location: DescriptionValue()..parse('Local muito legal para teste.'),
    venue: venue,
    thumb: ThumbModel(
      thumbUri: ThumbUriValue(
        defaultValue: Uri.parse('https://example.com/event.png'),
      )..parse('https://example.com/event.png'),
      thumbType: ThumbTypeValue(defaultValue: ThumbTypes.image)
        ..parse(ThumbTypes.image.name),
    ),
    dateTimeStart: DateTimeValue(isRequired: true)
      ..parse(DateTime(2026, 3, 15, 20).toIso8601String()),
    dateTimeEnd: null,
    artists: const [],
    linkedAccountProfiles: linkedProfiles,
    occurrences: occurrences,
    programmingItems: programmingItems,
    coordinate: null,
    tags: const <String>['show'],
    isConfirmedValue: EventIsConfirmedValue()..parse(isConfirmed.toString()),
    confirmedAt: null,
    receivedInvites: null,
    sentInvites: null,
    friendsGoing: null,
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
}

EventOccurrenceOption _buildOccurrence({
  required String id,
  required DateTime start,
  DateTime? end,
  bool isSelected = false,
  bool hasLocationOverride = false,
  int programmingCount = 0,
}) {
  final endValue = DomainOptionalDateTimeValue()..parse(end?.toIso8601String());
  return EventOccurrenceOption(
    occurrenceIdValue: EventLinkedAccountProfileTextValue(id),
    occurrenceSlugValue: EventLinkedAccountProfileTextValue('$id-slug'),
    dateTimeStartValue: DateTimeValue(isRequired: true)
      ..parse(start.toIso8601String()),
    dateTimeEndValue: endValue,
    isSelectedValue: EventOccurrenceFlagValue()..parse(isSelected.toString()),
    hasLocationOverrideValue: EventOccurrenceFlagValue()
      ..parse(hasLocationOverride.toString()),
    programmingCountValue: EventProgrammingCountValue()
      ..parse(programmingCount.toString()),
  );
}

EventProgrammingItem _buildProgrammingItem({
  required String time,
  String? title,
  List<EventLinkedAccountProfile> linkedProfiles = const [],
}) {
  return EventProgrammingItem(
    timeValue: EventProgrammingTimeValue(time),
    titleValue:
        title == null ? null : EventLinkedAccountProfileTextValue(title),
    linkedAccountProfiles: linkedProfiles,
  );
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.system);

  @override
  ThemeMode get themeMode => ThemeMode.system;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue(defaultValue: 5000),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue(defaultValue: 5000);

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({Set<String> favoriteIds = const <String>{}}) {
    favoriteAccountProfileIdsStreamValue.addValue(
      favoriteIds
          .map(AccountProfilesRepositoryContractPrimString.fromRaw)
          .toSet(),
    );
  }

  int initCalls = 0;
  int toggleFavoriteCalls = 0;

  @override
  Future<void> init() async {
    initCalls += 1;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return pagedAccountProfilesResultFromRaw(
      profiles: const <AccountProfileModel>[],
      hasMore: false,
    );
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
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    toggleFavoriteCalls += 1;
    final currentIds = favoriteAccountProfileIdsStreamValue.value
        .map((entry) => entry.value)
        .toSet();
    if (currentIds.contains(accountProfileId.value)) {
      currentIds.remove(accountProfileId.value);
    } else {
      currentIds.add(accountProfileId.value);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      currentIds
          .map(AccountProfilesRepositoryContractPrimString.fromRaw)
          .toSet(),
    );
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      favoriteAccountProfileIdsStreamValue.value.any(
        (entry) => entry.value == accountProfileId.value,
      ),
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

InviteModel _buildInviteForEvent({
  required String id,
  required String eventId,
}) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: eventId,
    eventName: 'Evento $id',
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/$id.png',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite $id',
    tags: const ['show'],
    inviterName: 'Convidador',
  );
}

List<Object> _takeAllExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    exceptions.add(error!);
  }
  return exceptions;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
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

  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
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
  int get contentLength => _imageBytes.length;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_imageBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
