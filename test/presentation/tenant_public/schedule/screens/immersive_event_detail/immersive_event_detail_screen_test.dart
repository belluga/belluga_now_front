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
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
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
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
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

  testWidgets(
      'event detail shows pending invite actions for selected occurrence',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    invitesRepository.pendingInvitesStreamValue.addValue([
      _buildInviteForEvent(
        id: 'invite-current-occurrence',
        eventId: '507f1f77bcf86cd799439011',
        occurrenceId: 'occurrence-selected',
        eventDateTime: DateTime(2026, 3, 16, 9),
      ),
      _buildInviteForEvent(
        id: 'invite-other-occurrence',
        eventId: '507f1f77bcf86cd799439011',
        occurrenceId: 'occurrence-other',
        eventDateTime: DateTime(2026, 3, 15, 20),
      ),
    ]);
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                occurrences: [
                  _buildOccurrence(
                    id: 'occurrence-selected',
                    start: DateTime(2026, 3, 16, 9),
                    isSelected: true,
                  ),
                  _buildOccurrence(
                    id: 'occurrence-other',
                    start: DateTime(2026, 3, 15, 20),
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

    expect(find.text('Agora não'), findsOneWidget);
    expect(find.text('Bóora!'), findsOneWidget);
    expect(find.text('16/03 às 09:00'), findsOneWidget);
    expect(find.text('15/03 às 20:00'), findsNothing);
  });

  testWidgets('event detail hero renders explicit schedule range with às',
      (tester) async {
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
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
                endDateTime: DateTime(2026, 3, 15, 22),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('20:00 às'), findsOneWidget);
    expect(find.textContaining('20:00 -'), findsNothing);
  });

  testWidgets(
      'event detail share action generates invite code for the selected occurrence',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final sharedTexts = <String?>[];
    final sharedSubjects = <String?>[];
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
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
                occurrences: [
                  _buildOccurrence(
                    id: 'occurrence-selected',
                    start: DateTime(2026, 3, 16, 9),
                    isSelected: true,
                  ),
                ],
              ),
              shareLauncher: (params) async {
                sharedTexts.add(params.text);
                sharedSubjects.add(params.subject);
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('immersiveShareAction')));
    await tester.pumpAndSettle();

    expect(invitesRepository.createShareCodeCalls, 1);
    expect(
      invitesRepository.lastCreateShareEventId,
      '507f1f77bcf86cd799439011',
    );
    expect(
      invitesRepository.lastCreateShareOccurrenceId,
      'occurrence-selected',
    );
    expect(sharedSubjects, ['Convite Belluga Now']);
    expect(sharedTexts.single, contains('https://tenant.test/invite?code=CODE123'));
  });

  testWidgets(
      'event detail share action stays bounded while share code generation is in flight',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository()
      ..createShareCodeCompleter = Completer<InviteShareCodeResult>();
    var shareLauncherCalls = 0;
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
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
                    id: 'occurrence-selected',
                    start: DateTime(2026, 3, 16, 9),
                    isSelected: true,
                  ),
                ],
              ),
              shareLauncher: (_) async {
                shareLauncherCalls += 1;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('immersiveShareAction')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('immersiveShareAction')));
    await tester.pump();

    expect(invitesRepository.createShareCodeCalls, 1);
    expect(find.byKey(const Key('immersiveShareActionLoading')), findsOneWidget);
    expect(shareLauncherCalls, 0);

    invitesRepository.createShareCodeCompleter!.complete(
      buildInviteShareCodeResult(
        code: 'CODE123',
        eventId: '507f1f77bcf86cd799439011',
        occurrenceId: 'occurrence-selected',
      ),
    );
    await tester.pumpAndSettle();

    expect(shareLauncherCalls, 1);
    expect(find.byKey(const Key('immersiveShareActionLoading')), findsNothing);
  });

  testWidgets(
      'event detail renders pending invite actions from share-code session context',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    invitesRepository.setShareCodeSessionContext(
      code: invitesRepoString(
        'SHARE-ABC',
        defaultValue: '',
        isRequired: true,
      ),
      invite: _buildInviteForEvent(
        id: 'session-preview',
        eventId: '507f1f77bcf86cd799439011',
        occurrenceId: 'occurrence-selected',
        eventDateTime: DateTime(2026, 3, 16, 9),
      ),
    );
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                occurrences: [
                  _buildOccurrence(
                    id: 'occurrence-selected',
                    start: DateTime(2026, 3, 16, 9),
                    isSelected: true,
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

    expect(find.text('Agora não'), findsOneWidget);
    expect(find.text('Bóora!'), findsOneWidget);
    expect(find.text('16/03 às 09:00'), findsOneWidget);
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

  testWidgets('anonymous user can favorite linked profile in event detail',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final accountProfilesRepository = _FakeAccountProfilesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: false),
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
                linkedProfiles: [
                  _buildLinkedAccountProfile(
                    id: 'artist-1',
                    displayName: 'Ananda Torres',
                    profileType: 'artist',
                    slug: 'ananda-torres',
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

    final favoriteButton =
        find.byKey(const Key('linkedProfileFavoriteButton_artist-1'));
    expect(favoriteButton, findsOneWidget);

    final iconButton = tester.widget<IconButton>(favoriteButton);
    expect(iconButton.onPressed, isNotNull);
    iconButton.onPressed?.call();
    await tester.pumpAndSettle();

    expect(accountProfilesRepository.toggleFavoriteCalls, 1);
    expect(router.lastReplacedPath, isNull);
    expect(_takeAllExceptions(tester), isEmpty);
  });

  testWidgets(
      'event hero compacts many linked profiles and opens first profile type tab',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
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
    final linkedProfiles = List<EventLinkedAccountProfile>.generate(
      4,
      (index) {
        final position = index + 1;
        return _buildLinkedAccountProfile(
          id: 'artist-$position',
          displayName: 'Artista $position',
          profileType: 'artist',
          slug: 'artista-$position',
        );
      },
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(linkedProfiles: linkedProfiles),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-2')),
      findsNothing,
    );
    expect(find.byKey(const Key('eventHeroMoreProfilesChip')), findsOneWidget);
    expect(find.text('e mais 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('eventHeroMoreProfilesChip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveTabSelected_1')), findsOneWidget);
  });

  testWidgets(
      'event hero compact chip opens first available profile type tab when first profile is untyped',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
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
    final linkedProfiles = [
      _buildLinkedAccountProfile(
        id: 'untagged-1',
        displayName: 'Perfil sem tipo',
        profileType: '',
        slug: 'perfil-sem-tipo',
      ),
      ...List<EventLinkedAccountProfile>.generate(
        3,
        (index) {
          final position = index + 1;
          return _buildLinkedAccountProfile(
            id: 'artist-$position',
            displayName: 'Artista $position',
            profileType: 'artist',
            slug: 'artista-$position',
          );
        },
      ),
    ];

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(linkedProfiles: linkedProfiles),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('eventHeroCounterpartChip_untagged-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-1')),
      findsNothing,
    );
    expect(find.byKey(const Key('eventHeroMoreProfilesChip')), findsOneWidget);
    expect(find.text('e mais 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('eventHeroMoreProfilesChip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveTabSelected_1')), findsOneWidget);
  });

  testWidgets(
      'event hero keeps three linked profiles expanded and opens first profile type tab',
      (tester) async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    GetIt.I.registerSingleton<ImmersiveEventDetailController>(
      ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
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
    final linkedProfiles = List<EventLinkedAccountProfile>.generate(
      3,
      (index) {
        final position = index + 1;
        return _buildLinkedAccountProfile(
          id: 'artist-$position',
          displayName: 'Artista $position',
          profileType: 'artist',
          slug: 'artista-$position',
        );
      },
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(linkedProfiles: linkedProfiles),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventHeroCounterpartChip_artist-3')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('eventHeroMoreProfilesChip')), findsNothing);

    await tester.tap(
      find.byKey(const Key('eventHeroCounterpartChip_artist-1')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveTabSelected_1')), findsOneWidget);
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

  testWidgets('event detail programming selector highlights current occurrence',
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
                    programmingCount: 1,
                  ),
                ],
                programmingItems: [
                  _buildProgrammingItem(
                    time: '17:00',
                    title: 'Show da data atual',
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

    expect(find.text('Datas'), findsNothing);
    expect(find.text('Programação'), findsWidgets);
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    final firstDateCard = find.byKey(const Key('eventDateCard_occ-1'));
    final secondDateCard = find.byKey(const Key('eventDateCard_occ-2'));

    expect(firstDateCard, findsOneWidget);
    expect(secondDateCard, findsOneWidget);
    expect(
      tester.getSize(firstDateCard).width,
      greaterThanOrEqualTo(132),
    );
    expect(
      find.descendant(
        of: firstDateCard,
        matching: find.text('15/03'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: firstDateCard,
        matching: find.text('Domingo'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: secondDateCard,
        matching: find.text('16/03'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: secondDateCard,
        matching: find.text('Segunda'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: secondDateCard,
        matching: find.text('20:00'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('eventDateCurrentBadge_occ-2')),
      findsNothing,
    );
    expect(find.text('Atual'), findsNothing);
    expect(find.text('Show da data atual'), findsOneWidget);

    await tester.ensureVisible(firstDateCard);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('immersiveSwipeSurface')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(firstDateCard);
    await tester.pump();

    expect(
      router.lastReplacedPath,
      '/agenda/evento/evento-de-teste?occurrence=occ-1&tab=programming',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('eventDateCurrentBadge_occ-1')),
      findsNothing,
    );
    expect(find.text('Show da data atual'), findsOneWidget);
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
      avatarUrl: 'https://example.com/avatar.png',
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

    expect(
      find.byKey(const Key('eventProgrammingItem_0_17:00')),
      findsOneWidget,
    );
    expect(find.text('17:00'), findsOneWidget);
    expect(find.text('Coral XYZ'), findsWidgets);
    expect(
      find.byKey(const Key('eventProgrammingProfile_artist-1')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('eventProgrammingProfile_artist-1')),
        matching: find.byType(BellugaNetworkImage),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'event detail programming centers the selected occurrence when there is room',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1600);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

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

    final occurrences = List<EventOccurrenceOption>.generate(
      10,
      (index) => _buildOccurrence(
        id: 'occ-$index',
        start: DateTime(2026, 3, 15 + index, 18),
        end: DateTime(2026, 3, 15 + index, 22),
        isSelected: index == 5,
        programmingCount: 1,
      ),
      growable: false,
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
                occurrences: occurrences,
                programmingItems: [
                  _buildProgrammingItem(
                    time: '18:00',
                    title: 'Faixa ativa',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    final selectedCard = find.byKey(const Key('eventDateCard_occ-5'));
    expect(selectedCard, findsOneWidget);

    final selectedCenter = tester.getCenter(selectedCard);
    expect(selectedCenter.dx, greaterThan(320));
    expect(selectedCenter.dx, lessThan(580));
  });

  testWidgets(
    'event detail programming recenters the newly selected occurrence after tap',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      var selectedOccurrenceId = 'occ-1';
      List<EventOccurrenceOption> buildOccurrences() {
        return List<EventOccurrenceOption>.generate(
          10,
          (index) => _buildOccurrence(
            id: 'occ-$index',
            start: DateTime(2026, 3, 15 + index, 18),
            end: DateTime(2026, 3, 15 + index, 22),
            isSelected: selectedOccurrenceId == 'occ-$index',
            programmingCount: 0,
          ),
          growable: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: EventProgrammingSection(
                  items: const <EventProgrammingItem>[],
                  occurrences: buildOccurrences(),
                  onOccurrenceTap: (occurrence) {
                    setState(() {
                      selectedOccurrenceId = occurrence.occurrenceId;
                    });
                  },
                  onLocationTap: (_) {},
                  profileTypeRegistry: null,
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('eventDateCard_occ-5')));
      await tester.pumpAndSettle();

      final selectedCard = find.byKey(const Key('eventDateCard_occ-5'));
      expect(selectedCard, findsOneWidget);

      final selectedCenter = tester.getCenter(selectedCard);
      expect(selectedCenter.dx, greaterThan(320));
      expect(selectedCenter.dx, lessThan(580));
    },
  );

  testWidgets(
    'event detail programming centers a selected occurrence only once when the same target rebuilds twice',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      var selectedOccurrenceId = 'occ-1';
      var centerAnimationStarts = 0;

      List<EventOccurrenceOption> buildOccurrences() {
        return List<EventOccurrenceOption>.generate(
          10,
          (index) => _buildOccurrence(
            id: 'occ-$index',
            start: DateTime(2026, 3, 15 + index, 18),
            end: DateTime(2026, 3, 15 + index, 22),
            isSelected: selectedOccurrenceId == 'occ-$index',
            programmingCount: 0,
          ),
          growable: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: EventProgrammingSection(
                  items: const <EventProgrammingItem>[],
                  occurrences: buildOccurrences(),
                  onOccurrenceTap: (occurrence) {
                    setState(() {
                      selectedOccurrenceId = occurrence.occurrenceId;
                    });
                    Future<void>.microtask(() {
                      setState(() {
                        selectedOccurrenceId = occurrence.occurrenceId;
                      });
                    });
                  },
                  onLocationTap: (_) {},
                  profileTypeRegistry: null,
                  debugOnOccurrenceCenterAnimationStart: () {
                    centerAnimationStarts += 1;
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      centerAnimationStarts = 0;

      await tester.tap(find.byKey(const Key('eventDateCard_occ-5')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(centerAnimationStarts, 1);
    },
  );

  testWidgets(
    'event detail programming does not replay a second centering animation when the selector state is recreated after tap',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      var selectedOccurrenceId = 'occ-1';
      var selectorEpoch = 0;
      var centerAnimationStarts = 0;

      List<EventOccurrenceOption> buildOccurrences() {
        return List<EventOccurrenceOption>.generate(
          10,
          (index) => _buildOccurrence(
            id: 'occ-$index',
            start: DateTime(2026, 3, 15 + index, 18),
            end: DateTime(2026, 3, 15 + index, 22),
            isSelected: selectedOccurrenceId == 'occ-$index',
            programmingCount: 0,
          ),
          growable: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: KeyedSubtree(
                  key: ValueKey('selector-$selectorEpoch'),
                  child: EventProgrammingSection(
                    items: const <EventProgrammingItem>[],
                    occurrences: buildOccurrences(),
                    onOccurrenceTap: (occurrence) {
                      setState(() {
                        selectedOccurrenceId = occurrence.occurrenceId;
                      });
                      Future<void>.microtask(() {
                        setState(() {
                          selectorEpoch += 1;
                        });
                      });
                    },
                    onLocationTap: (_) {},
                    profileTypeRegistry: null,
                    debugOnOccurrenceCenterAnimationStart: () {
                      centerAnimationStarts += 1;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      centerAnimationStarts = 0;

      await tester.tap(find.byKey(const Key('eventDateCard_occ-5')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(centerAnimationStarts, 1);
    },
  );

  testWidgets('event detail programming renders large schedules progressively',
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
    final programmingItems = List<EventProgrammingItem>.generate(
      30,
      (index) => _buildProgrammingItem(
        time: 'T$index',
        title: 'Programação $index',
      ),
      growable: false,
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(programmingItems: programmingItems),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(find.text('Programação 0'), findsOneWidget);
    expect(find.text('Programação 23'), findsOneWidget);
    expect(find.text('Programação 24'), findsNothing);
    expect(
      find.byKey(const Key('eventProgrammingShowMoreButton')),
      findsOneWidget,
    );

    final showMoreButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('eventProgrammingShowMoreButton')),
    );
    showMoreButton.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Programação 24'), findsOneWidget);
    expect(find.text('Programação 29'), findsOneWidget);
    expect(
      find.byKey(const Key('eventProgrammingShowMoreButton')),
      findsNothing,
    );
  });

  testWidgets(
      'event detail programming caps profile fanout and supports duplicate times',
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
    final profiles = List<EventLinkedAccountProfile>.generate(
      24,
      (index) => _buildLinkedAccountProfile(
        id: 'artist-$index',
        displayName: 'Artista $index',
        profileType: 'artist',
        slug: 'artist-$index',
        avatarUrl: 'https://example.com/avatar-$index.png',
      ),
      growable: false,
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
                    title: 'Palco principal',
                    linkedProfiles: profiles,
                  ),
                  _buildProgrammingItem(
                    time: '17:00',
                    title: 'Palco alternativo',
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
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('eventProgrammingItem_0_17:00')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventProgrammingItem_1_17:00')),
      findsOneWidget,
    );
    expect(find.text('Palco principal'), findsOneWidget);
    expect(find.text('Palco alternativo'), findsOneWidget);
    expect(
      find.byKey(const Key('eventProgrammingProfilesOverflow_0')),
      findsOneWidget,
    );
    expect(find.text('e mais 20'), findsOneWidget);
    expect(find.byKey(const Key('eventProgrammingProfile_artist-0')),
        findsOneWidget);
    expect(find.byKey(const Key('eventProgrammingProfile_artist-3')),
        findsOneWidget);
    expect(find.byKey(const Key('eventProgrammingProfile_artist-4')),
        findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('eventProgrammingItem_0_17:00')),
        matching: find.byType(BellugaNetworkImage),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets(
      'event detail programming profiles-only item does not derive a title from participant',
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('eventProgrammingProfile_artist-1')),
      findsOneWidget,
    );
    expect(find.text('Coral XYZ'), findsOneWidget);
    expect(find.text('Atividade'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('eventProgrammingProfile_artist-1')),
        matching: find.byIcon(Icons.person_outline),
      ),
      findsOneWidget,
    );
  });

  testWidgets('event detail programming title-only card centers content',
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
                programmingItems: [
                  _buildProgrammingItem(
                    time: '17:00',
                    title: 'Abertura da noite',
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    final rowFinder = find.descendant(
      of: find.byKey(const Key('eventProgrammingItem_0_17:00')),
      matching: find.byWidgetPredicate((widget) => widget is Row),
    );
    final row = tester.widget<Row>(rowFinder.first);

    expect(row.crossAxisAlignment, CrossAxisAlignment.center);
  });

  testWidgets('event detail programming profile chips ellipsize long labels',
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
    const longProfileName =
        'Coletivo Cultural de Performance Instrumental do Centro Historico';
    final profile = _buildLinkedAccountProfile(
      id: 'artist-1',
      displayName: longProfileName,
      profileType: 'artist',
      slug: 'coletivo-cultural',
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    final chipText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('eventProgrammingProfile_artist-1')),
        matching: find.text(longProfileName),
      ),
    );

    expect(chipText.maxLines, 1);
    expect(chipText.overflow, TextOverflow.ellipsis);
  });

  testWidgets(
      'single-occurrence event detail keeps Programação tab without date selector',
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
      route: _FakeRouteMatch(
        fullPath: '/agenda/evento/evento-de-teste',
        queryParams: const {'tab': 'programming'},
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                occurrences: [
                  _buildOccurrence(
                    id: 'occ-1',
                    start: DateTime(2026, 3, 15, 20),
                    isSelected: true,
                    programmingCount: 1,
                    programmingItems: [
                      _buildProgrammingItem(
                        time: '19:00',
                        title: 'Abertura da noite',
                      ),
                    ],
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
    await tester.pumpAndSettle();

    expect(find.text('Programação'), findsWidgets);
    expect(find.byKey(const Key('immersiveTabSelected_1')), findsOneWidget);
    expect(
        find.byKey(const Key('eventProgrammingItem_0_19:00')), findsOneWidget);
    expect(find.byKey(const Key('eventDateCard_occ-1')), findsNothing);
    expect(find.text('Atual'), findsNothing);
  });

  testWidgets('event detail programming location opens map POI route',
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
    final locationProfile = _buildLinkedAccountProfile(
      id: 'venue-2',
      displayName: 'Palco Praia',
      profileType: 'venue',
      slug: 'palco-praia',
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
                    time: '13:00',
                    title: 'Apresentação no palco',
                    locationProfile: locationProfile,
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('eventProgrammingLocation_venue-2')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('eventProgrammingLocation_venue-2')),
        matching: find.text('Palco Praia'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('eventProgrammingLocation_venue-2')));
    await tester.pump();

    expect(router.lastPushedPath, '/mapa?poi=account_profile%3Avenue-2');
  });

  testWidgets('event detail programming tab replaces dates tab with selector',
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
                    programmingCount: 0,
                  ),
                  _buildOccurrence(
                    id: 'occ-2',
                    start: DateTime(2026, 3, 16, 20),
                    isSelected: true,
                    programmingCount: 1,
                  ),
                ],
                programmingItems: [
                  _buildProgrammingItem(
                    time: '17:00',
                    title: 'Abertura',
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

    expect(find.text('Datas'), findsNothing);
    expect(find.text('Programação'), findsWidgets);
    await tester.tap(find.byKey(const Key('immersiveTabLabel_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventDateCard_occ-1')), findsOneWidget);
    expect(find.byKey(const Key('eventDateCard_occ-2')), findsOneWidget);
    expect(
        find.byKey(const Key('eventProgrammingItem_0_17:00')), findsOneWidget);

    await tester.tap(find.byKey(const Key('eventDateCard_occ-1')));
    await tester.pump();

    expect(router.lastReplacedPath, isNull);
    expect(router.lastNavigatedRoute, isA<ImmersiveEventDetailRoute>());
    final route = router.lastNavigatedRoute! as ImmersiveEventDetailRoute;
    expect(route.rawPathParams['slug'], 'evento-de-teste');
    expect(route.rawQueryParams['occurrence'], 'occ-1');
    expect(route.rawQueryParams['tab'], 'programming');
  });

  testWidgets(
    'event detail programming occurrence tap emits one selected-occurrence update even when route state rebuilds',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      GetIt.I.registerSingleton<ImmersiveEventDetailController>(
        ImmersiveEventDetailController(
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          authRepository: _FakeAuthRepository(authorized: true),
        ),
      );

      final emittedOccurrenceIds = <String?>[];
      final subscription = invitesRepository.immersiveSelectedEventStreamValue
          .stream
          .listen((event) {
        emittedOccurrenceIds.add(event?.selectedOccurrenceId?.trim());
      });
      addTearDown(subscription.cancel);

      final router = _RecordingStackRouter();
      final routeData = RouteData(
        route: _FakeRouteMatch(
          fullPath: '/agenda/evento/evento-de-teste',
          queryParams: const {'tab': 'programming'},
        ),
        router: router,
        stackKey: const ValueKey('stack'),
        pendingChildren: const [],
        type: const RouteType.material(),
      );

      var selectedOccurrenceId = 'occ-1';

      EventModel buildEvent() {
        return _buildEvent(
          occurrences: List<EventOccurrenceOption>.generate(
            9,
            (index) => _buildOccurrence(
              id: 'occ-$index',
              start: DateTime(2026, 3, 15 + index, 18),
              end: DateTime(2026, 3, 15 + index, 22),
              isSelected: selectedOccurrenceId == 'occ-$index',
              programmingCount: 1,
            ),
            growable: false,
          ),
          programmingItems: [
            _buildProgrammingItem(
              time: '18:00',
              title: 'Faixa ativa',
            ),
          ],
        );
      }

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            router.onNavigateRoute = (route) {
              final occurrenceId = route.queryParams.optString('occurrence');
              if (occurrenceId == null || occurrenceId.isEmpty) {
                return;
              }
              setState(() {
                selectedOccurrenceId = occurrenceId;
              });
            };

            return StackRouterScope(
              controller: router,
              stateHash: 0,
              child: MaterialApp(
                home: RouteDataScope(
                  routeData: routeData,
                  child: ImmersiveEventDetailScreen(
                    event: buildEvent(),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      emittedOccurrenceIds.clear();

      await tester.tap(find.byKey(const Key('eventDateCard_occ-5')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        emittedOccurrenceIds.where((occurrenceId) => occurrenceId == 'occ-5'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'event detail programming keeps later occurrences visible after route rebuilds on a phone-width rail',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(411, 1200);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

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
        route: _FakeRouteMatch(
          fullPath: '/agenda/evento/evento-de-teste',
          queryParams: const {'tab': 'programming'},
        ),
        router: router,
        stackKey: const ValueKey('stack'),
        pendingChildren: const [],
        type: const RouteType.material(),
      );

      var selectedOccurrenceId = 'occ-0';

      EventModel buildEvent() {
        return _buildEvent(
          occurrences: List<EventOccurrenceOption>.generate(
            9,
            (index) => _buildOccurrence(
              id: 'occ-$index',
              start: DateTime(2026, 3, 15 + index, 18),
              end: DateTime(2026, 3, 15 + index, 22),
              isSelected: selectedOccurrenceId == 'occ-$index',
              programmingCount: 1,
            ),
            growable: false,
          ),
          programmingItems: [
            _buildProgrammingItem(
              time: '18:00',
              title: 'Faixa ativa',
            ),
          ],
        );
      }

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            router.onNavigateRoute = (route) {
              final occurrenceId = route.queryParams.optString('occurrence');
              if (occurrenceId == null || occurrenceId.isEmpty) {
                return;
              }
              setState(() {
                selectedOccurrenceId = occurrenceId;
              });
            };

            return StackRouterScope(
              controller: router,
              stateHash: 0,
              child: MaterialApp(
                home: RouteDataScope(
                  routeData: routeData,
                  child: ImmersiveEventDetailScreen(
                    event: buildEvent(),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      final viewportFinder =
          find.byKey(const Key('eventProgrammingDateSelectorViewport'));
      final selectorListFinder =
          find.byKey(const Key('eventProgrammingDateSelectorList'));
      final verticalScrollable = find.byType(SingleChildScrollView).first;

      Future<void> tapAndValidate(int index) async {
        final occurrenceId = 'occ-$index';
        final cardFinder = find.byKey(Key('eventDateCard_$occurrenceId'));
        await tester.dragUntilVisible(
          viewportFinder,
          verticalScrollable,
          const Offset(0, -220),
          maxIteration: 10,
          continuous: true,
        );
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          cardFinder,
          selectorListFinder,
          const Offset(-180, 0),
          maxIteration: 20,
          continuous: true,
        );
        final card = tester.widget<InkWell>(cardFinder);
        expect(card.onTap, isNotNull);
        card.onTap!.call();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(selectedOccurrenceId, occurrenceId);

        final viewportRect = tester.getRect(viewportFinder);
        final selectedRect = tester.getRect(cardFinder);

        expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 1));
        expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 1));
      }

      for (var index = 1; index <= 8; index += 1) {
        await tapAndValidate(index);
      }
    },
  );

  testWidgets(
      'event detail programming tab shows empty state when selected date has no items',
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
                    isSelected: true,
                    programmingCount: 0,
                  ),
                  _buildOccurrence(
                    id: 'occ-2',
                    start: DateTime(2026, 3, 16, 20),
                    programmingCount: 2,
                  ),
                ],
                programmingItems: const [],
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

    expect(find.byKey(const Key('eventDateCard_occ-1')), findsOneWidget);
    expect(find.byKey(const Key('eventDateCard_occ-2')), findsOneWidget);
    expect(
      find.text('Esta data ainda não tem programação cadastrada.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'event detail refreshes selected occurrence when route model changes',
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
      route: _FakeRouteMatch(
        fullPath: '/agenda/evento/evento-de-teste',
        queryParams: const {'tab': 'programming'},
      ),
      router: router,
      stackKey: const ValueKey('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    Widget buildScreen(EventModel event) {
      return StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: ImmersiveEventDetailScreen(event: event),
          ),
        ),
      );
    }

    EventModel buildEventForOccurrence(String selectedOccurrenceId) {
      final selectedFirst = selectedOccurrenceId == 'occ-1';
      return _buildEvent(
        occurrences: [
          _buildOccurrence(
            id: 'occ-1',
            start: DateTime(2026, 3, 15, 20),
            isSelected: selectedFirst,
            programmingCount: 0,
          ),
          _buildOccurrence(
            id: 'occ-2',
            start: DateTime(2026, 3, 16, 20),
            isSelected: !selectedFirst,
            programmingCount: 1,
          ),
        ],
        programmingItems: selectedFirst
            ? const []
            : [
                _buildProgrammingItem(
                  time: '17:00',
                  title: 'Show da data atual',
                ),
              ],
      );
    }

    await tester.pumpWidget(buildScreen(buildEventForOccurrence('occ-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Show da data atual'), findsOneWidget);
    expect(
      find.byKey(const Key('eventDateCard_occ-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventDateCurrentBadge_occ-2')),
      findsNothing,
    );

    await tester.pumpWidget(buildScreen(buildEventForOccurrence('occ-1')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('eventDateCard_occ-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('eventDateCurrentBadge_occ-1')),
      findsNothing,
    );
    expect(
      find.text('Esta data ainda não tem programação cadastrada.'),
      findsOneWidget,
    );
    expect(find.text('Show da data atual'), findsNothing);
  });

  testWidgets('event detail tab=programming falls back to Sobre when empty',
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
      route: _FakeRouteMatch(
        fullPath: '/agenda/evento/evento-de-teste',
        queryParams: const {'tab': 'programming'},
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
            child: ImmersiveEventDetailScreen(
              event: _buildEvent(
                programmingItems: const [],
                occurrences: const [],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Programação'), findsNothing);
    expect(find.text('Sobre'), findsWidgets);
    expect(find.byKey(const Key('immersiveTabSelected_0')), findsOneWidget);
  });

  testWidgets('event detail Como Chegar aggregates and dedupes destinations',
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
    final duplicatedVenueLocation = _buildLinkedAccountProfile(
      id: '507f1f77bcf86cd799439099',
      displayName: 'Carvoeiro',
      profileType: 'venue',
      slug: 'carvoeiro',
    );
    final programmingLocation = _buildLinkedAccountProfile(
      id: 'venue-2',
      displayName: 'Palco Central',
      profileType: 'venue',
      slug: 'palco-central',
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
                programmingItems: [
                  _buildProgrammingItem(
                    time: '10:00',
                    title: 'Recepção',
                    locationProfile: duplicatedVenueLocation,
                  ),
                  _buildProgrammingItem(
                    time: '11:00',
                    title: 'Abertura',
                    locationProfile: programmingLocation,
                  ),
                  _buildProgrammingItem(
                    time: '17:00',
                    title: 'Show',
                    locationProfile: programmingLocation,
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_2')));
    await tester.pumpAndSettle();

    expect(find.text('Outros endereços relacionados'), findsOneWidget);
    expect(find.text('Local da programação'), findsNothing);
    expect(
      find.byKey(
        const Key(
            'eventLocationDestination_account_profile:507f1f77bcf86cd799439099'),
      ),
      findsNothing,
    );
    final programmingDestination = find.byKey(
      const Key('eventLocationDestination_account_profile:venue-2'),
    );
    expect(programmingDestination, findsOneWidget);
    expect(
      find.descendant(
        of: programmingDestination,
        matching: find.text('Palco Central'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(programmingDestination);
    await tester.pumpAndSettle();
    await tester.tap(programmingDestination);
    await tester.pump();

    expect(router.lastPushedPath, '/mapa?poi=account_profile%3Avenue-2');
  });

  testWidgets(
      'event detail Como Chegar hides related addresses heading when only main venue exists',
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
    final duplicatedVenueLocation = _buildLinkedAccountProfile(
      id: '507f1f77bcf86cd799439099',
      displayName: 'Carvoeiro',
      profileType: 'venue',
      slug: 'carvoeiro',
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
                programmingItems: [
                  _buildProgrammingItem(
                    time: '10:00',
                    title: 'Recepção',
                    locationProfile: duplicatedVenueLocation,
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

    await tester.tap(find.byKey(const Key('immersiveTabLabel_2')));
    await tester.pumpAndSettle();

    expect(find.text('Outros endereços relacionados'), findsNothing);
    expect(find.text('Local da programação'), findsNothing);
    expect(
      find.byKey(
        const Key(
            'eventLocationDestination_account_profile:507f1f77bcf86cd799439099'),
      ),
      findsNothing,
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
  PageRouteInfo? lastNavigatedRoute;
  void Function(PageRouteInfo route)? onNavigateRoute;
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
  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    lastNavigatedRoute = route;
    onNavigateRoute?.call(route);
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
      confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  int confirmCalls = 0;

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    confirmCalls += 1;
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {}

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int acceptInviteCalls = 0;
  int createShareCodeCalls = 0;
  final List<String> acceptedShareCodes = <String>[];
  String? lastCreateShareEventId;
  String? lastCreateShareOccurrenceId;
  String? lastCreateShareAccountProfileId;
  Completer<InviteShareCodeResult>? createShareCodeCompleter;

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
    acceptedShareCodes.add(code.value);
    clearShareCodeSessionContext(code: code);
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
    createShareCodeCalls += 1;
    lastCreateShareEventId = eventId.value;
    lastCreateShareOccurrenceId = occurrenceId?.value;
    lastCreateShareAccountProfileId = accountProfileId?.value;
    final completer = createShareCodeCompleter;
    if (completer != null) {
      return completer.future;
    }
    return buildInviteShareCodeResult(
      code: 'CODE123',
      eventId: eventId.value,
      occurrenceId: occurrenceId?.value ?? 'occurrence-1',
    );
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
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
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
  DateTime? endDateTime,
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
    dateTimeEnd: endDateTime == null
        ? null
        : (DateTimeValue(isRequired: true)
          ..parse(endDateTime.toIso8601String())),
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
  List<EventProgrammingItem> programmingItems = const [],
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
    programmingItems: programmingItems,
  );
}

EventProgrammingItem _buildProgrammingItem({
  required String time,
  String? title,
  List<EventLinkedAccountProfile> linkedProfiles = const [],
  EventLinkedAccountProfile? locationProfile,
}) {
  return EventProgrammingItem(
    timeValue: EventProgrammingTimeValue(time),
    titleValue:
        title == null ? null : EventLinkedAccountProfileTextValue(title),
    linkedAccountProfiles: linkedProfiles,
    locationProfile: locationProfile,
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
  String occurrenceId = '507f1f77bcf86cd799439012',
  DateTime? eventDateTime,
}) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: eventId,
    eventName: 'Evento $id',
    eventDateTime: eventDateTime ?? DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/$id.png',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite $id',
    tags: const ['show'],
    occurrenceId: occurrenceId,
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
