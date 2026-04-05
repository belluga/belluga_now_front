import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset(dispose: false);
    GetIt.I.registerSingleton<AppData>(_buildAppData());
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('shows loading state while controller is loading',
      (tester) async {
    final controller = _LoadingAccountProfileDetailController(
      accountProfilesRepository: _FakeAccountProfilesRepository(),
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );

    expect(find.byKey(const Key('accountProfileLoadingState')), findsOneWidget);
  });

  testWidgets('shows empty state when controller resolves no profile',
      (tester) async {
    final controller = _EmptyAccountProfileDetailController(
      accountProfilesRepository: _FakeAccountProfilesRepository(),
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileEmptyState')), findsOneWidget);
  });

  testWidgets('shows error state when controller emits a screen-level error',
      (tester) async {
    final controller = _ErrorAccountProfileDetailController(
      accountProfilesRepository: _FakeAccountProfilesRepository(),
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileErrorState')), findsOneWidget);
    expect(find.text('Falha ao preparar o perfil'), findsOneWidget);
  });

  testWidgets(
      'hero uses type visuals as left avatar fallback when no avatar exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatarFinder = find.byKey(const Key('accountProfileHeroTypeAvatar'));
    expect(avatarFinder, findsOneWidget);
    expect(find.byKey(const Key('accountProfileHeroIdentityAvatar')),
        findsNothing);
    expect(
      find.descendant(
        of: avatarFinder,
        matching: find.byIcon(Icons.music_note),
      ),
      findsOneWidget,
    );
    expect(find.text('Artista'), findsNothing);

    final avatarContainer = tester.widget<Container>(
      find.descendant(
        of: avatarFinder,
        matching: find.byType(Container),
      ),
    );
    final decoration = avatarContainer.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, const Color(0xFF7E22CE));
  });

  testWidgets('hero renders avatar with type badge overlay when avatar exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: buildAccountProfileModelFromPrimitives(
            id: '507f1f77bcf86cd799439015',
            name: 'Ananda Torres',
            slug: 'ananda-torres',
            type: 'artist',
            avatarUrl: 'https://tenant.test/avatar.png',
            coverUrl: 'https://tenant.test/cover.png',
            tags: const ['brasilidades'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileHeroIdentityAvatar')),
        findsOneWidget);
    expect(find.byKey(const Key('accountProfileHeroTypeAvatar')),
        findsOneWidget);
  });

  testWidgets(
      'hero uses type visuals as avatar fallback when only cover exists and no avatar is present',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: buildAccountProfileModelFromPrimitives(
            id: '507f1f77bcf86cd799439016',
            name: 'Casa Marracini',
            slug: 'casa-marracini',
            type: 'restaurant',
            coverUrl: 'https://tenant.test/cover.png',
            tags: const ['italiano'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileHeroIdentityAvatar')),
        findsNothing);
    expect(find.byKey(const Key('accountProfileHeroTypeAvatar')),
        findsOneWidget);
  });

  testWidgets(
      'artist profile uses favorite CTA in agenda when profile is not favorited',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acontecendo Agora'), findsOneWidget);
    expect(find.text('Próximos Eventos'), findsWidgets);
    expect(find.text('Favoritar'), findsOneWidget);
    expect(find.text('Ver detalhes do evento'), findsNothing);
  });

  testWidgets('artist profile hides agenda CTA after profile is already favorited',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      initialFavoriteIds: const {'507f1f77bcf86cd799439011'},
    );
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favoritar'), findsNothing);
    expect(find.text('Ver detalhes do evento'), findsNothing);
  });

  testWidgets(
      'renders directions section and route CTA for restaurant with POI coordinates',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Como Chegar'), findsWidgets);
    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.text('752 m de você'), findsWidgets);
    expect(find.text('Traçar rota'), findsOneWidget);
    expect(find.text('Seguir'), findsNothing);
    expect(find.byKey(const Key('accountProfileLocationTile')), findsOneWidget);
    expect(find.byKey(const Key('accountProfileLocationDistanceBadge')),
        findsOneWidget);
    expect(find.byKey(const Key('accountProfileRouteFooterButton')),
        findsOneWidget);
    expect(find.byKey(const Key('accountProfileEmbeddedMapPreview')),
        findsOneWidget);
  });

  testWidgets(
      'restaurant profile shows Agenda tab when upcoming events exist even if legacy capability is false',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantWithAgendaProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Próximos Eventos'), findsOneWidget);
    expect(find.text('Como Chegar'), findsWidgets);
  });

  testWidgets(
      'venue-host agenda highlights counterpart artists and renders venue line separately',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantWithAgendaProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headline = tester.widget<Text>(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439131',
        ),
      ),
    );
    expect(headline.data, 'Chef Table Experience');
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaCardCounterparts_507f1f77bcf86cd799439131',
          ),
        ),
        matching: find.text('Marco Aurélio'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaCardCounterparts_507f1f77bcf86cd799439131',
          ),
        ),
        matching: find.text('Casa Marracini'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const Key('accountProfileAgendaCardVenue_507f1f77bcf86cd799439131'),
      ),
      findsOneWidget,
    );
    expect(find.text('Casa Marracini (752 m)'), findsOneWidget);
  });

  testWidgets(
      'artist-host agenda excludes the current host and venue from counterpart chips',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistHostAwareProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headline = tester.widget<Text>(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439141',
        ),
      ),
    );
    expect(headline.data, 'Jazz na Orla');
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaCardCounterparts_507f1f77bcf86cd799439141',
          ),
        ),
        matching: find.text('Casa Marracini'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaCardCounterparts_507f1f77bcf86cd799439141',
          ),
        ),
        matching: find.text('DJ Lua'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('accountProfileAgendaCardVenue_507f1f77bcf86cd799439141'),
      ),
      findsOneWidget,
    );
    expect(find.text('Casa Marracini'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaCardCounterparts_507f1f77bcf86cd799439141',
          ),
        ),
        matching: find.text('Marco Aurélio'),
      ),
      findsNothing,
    );
  });

  testWidgets('favorite action stays in app bar overlay after hero collapses',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileFavoriteAction')), findsOneWidget);

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    final collapsedTitle = tester.widget<Text>(
      find.byKey(const Key('immersiveCollapsedTitle')),
    );
    final sliverAppBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    final collapsedTitleCenter = tester.getCenter(
      find.byKey(const Key('immersiveCollapsedTitle')),
    );
    final navigationToolbarRect = tester.getRect(find.byType(NavigationToolbar));
    final toolbarCenterY = navigationToolbarRect.center.dy;

    expect(find.byKey(const Key('accountProfileFavoriteAction')), findsOneWidget);
    expect(find.byKey(const Key('accountProfileCollapsedIdentitySurface')),
        findsNothing);
    expect(find.byKey(const Key('immersiveCollapsedTitle')),
        findsOneWidget);
    expect(find.text('Cafe de la Musique'), findsWidgets);
    expect(collapsedTitle.maxLines, 2);
    expect(collapsedTitle.overflow, TextOverflow.ellipsis);
    expect(sliverAppBar.toolbarHeight, 72);
    expect((collapsedTitleCenter.dy - toolbarCenterY).abs(), lessThanOrEqualTo(8));
  });

  testWidgets('live agenda highlight navigates to the highlighted event',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(
        const Key(
          'accountProfileAgendaLiveCard_507f1f77bcf86cd799439121',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key(
          'accountProfileAgendaLiveCard_507f1f77bcf86cd799439121',
        ),
      ),
    );
    await tester.pump();

    expect(router.lastPushedPath, '/agenda/evento/jazz-na-orla');
  });

  testWidgets(
      'live agenda highlight uses event type eyebrow, expanded schedule, counterpart chips and venue line',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    final liveEvent = _buildArtistAgendaEvents().first;
    final expectedSchedule =
        '${DateFormat.E().format(liveEvent.startDateTime).toUpperCase()}, '
        '${liveEvent.startDateTime.day.toString().padLeft(2, '0')} • ${liveEvent.startDateTime.timeLabel} - '
        '${DateFormat.E().format((liveEvent.endDateTime ?? liveEvent.startDateTime.add(const Duration(hours: 3)))).toUpperCase()}, '
        '${(liveEvent.endDateTime ?? liveEvent.startDateTime.add(const Duration(hours: 3))).day.toString().padLeft(2, '0')} • '
        '${(liveEvent.endDateTime ?? liveEvent.startDateTime.add(const Duration(hours: 3))).timeLabel}';

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(
        find.byKey(
          const Key(
            'accountProfileAgendaLiveEyebrow_507f1f77bcf86cd799439121',
          ),
        ),
      ).data,
      'Show',
    );
    expect(
      tester.widget<Text>(
        find.descendant(
          of: find.byKey(
            const Key(
              'accountProfileAgendaLiveSchedule_507f1f77bcf86cd799439121',
            ),
          ),
          matching: find.byType(Text),
        ),
      ).data,
      expectedSchedule,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaLiveCounterparts_507f1f77bcf86cd799439121',
          ),
        ),
        matching: find.text('Marco Aurélio'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('accountProfileAgendaLiveVenue_507f1f77bcf86cd799439121'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('accountProfileAgendaLiveVenue_507f1f77bcf86cd799439121'),
        ),
        matching: find.text('Cafe de la Musique'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('future-only agenda does not render Acontecendo Agora section',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantWithAgendaProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acontecendo Agora'), findsNothing);
    expect(find.text('Próximos Eventos'), findsOneWidget);
  });

  testWidgets(
      'live-only agenda renders the occurrence only in Acontecendo Agora',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistLiveOnlyProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acontecendo Agora'), findsOneWidget);
    expect(find.text('Próximos Eventos'), findsNothing);
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaLiveCard_507f1f77bcf86cd799439121',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439121',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'live agenda keeps only distinct future occurrences in Próximos Eventos',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acontecendo Agora'), findsOneWidget);
    expect(find.text('Próximos Eventos'), findsOneWidget);
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaLiveCard_507f1f77bcf86cd799439121',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439121',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439122',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders account profile tabs in fixed MVP order',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildVenueFullProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_0'))).data,
      'Sobre',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_1'))).data,
      'Agenda',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_2'))).data,
      'Como Chegar',
    );
  });

  testWidgets('removes social metrics from the account profile MVP surface',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(BooraIcons.invite_solid), findsNothing);
    expect(find.text('87'), findsNothing);
  });

  testWidgets('horizontal swipe moves account profile tabs to the next section',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildVenueFullProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets('tapping location tile opens in-app map focused on account profile poi',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tileGesture = tester.widget<GestureDetector>(
      find.byKey(const Key('accountProfileLocationTile')),
    );
    tileGesture.onTap?.call();
    await tester.pump();

    expect(
      router.lastPushedPath,
      '/mapa?poi=account_profile%3A507f1f77bcf86cd799439012',
    );
  });

  testWidgets('tapping route footer delegates to shared directions chooser',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    final chooser = _RecordingDirectionsAppChooser();
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
          directionsAppChooser: chooser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountProfileRouteFooterButton')));
    await tester.pump();

    expect(chooser.presentCallCount, 1);
    expect(chooser.lastTarget?.destinationName, 'Casa Marracini');
    expect(chooser.lastTarget?.latitude, closeTo(-20.7389, 0.00001));
    expect(chooser.lastTarget?.longitude, closeTo(-40.8212, 0.00001));
  });

  testWidgets('renders fallback section when no tabs are available',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildMinimalProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('accountProfileNoSectionsFallback')),
      findsOneWidget,
    );
    expect(find.text('Mais sobre este perfil'), findsOneWidget);
  });

  testWidgets('renders bio only once and without raw html tags',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfileDetailScreen(
          accountProfile: _buildVenueWithBioProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manifesto Singular'), findsOneWidget);
    expect(find.text('Texto de apoio da casa'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
    expect(find.textContaining('<strong>'), findsNothing);
  });
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(fullPath: '/parceiro/teste'),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RouteDataScope(
        routeData: routeData,
        child: child,
      ),
    ),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  String? lastPushedPath;
  String? lastReplacedPath;

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

class _RecordingDirectionsAppChooser implements DirectionsAppChooserContract {
  int presentCallCount = 0;
  DirectionsLaunchTarget? lastTarget;

  @override
  Future<List<DirectionsAppChoice>> loadOptions({
    required DirectionsLaunchTarget target,
  }) async =>
      const <DirectionsAppChoice>[];

  @override
  Future<void> present(
    BuildContext context, {
    required DirectionsLaunchTarget target,
    ValueChanged<String>? onStatusMessage,
  }) async {
    presentCallCount += 1;
    lastTarget = target;
  }
}

class _LoadingAccountProfileDetailController
    extends AccountProfileDetailController {
  _LoadingAccountProfileDetailController({
    required super.accountProfilesRepository,
  }) {
    isLoadingStreamValue.addValue(true);
  }

  @override
  Future<void> loadResolvedAccountProfile(
      AccountProfileModel accountProfile) async {}
}

class _EmptyAccountProfileDetailController
    extends AccountProfileDetailController {
  _EmptyAccountProfileDetailController({
    required super.accountProfilesRepository,
  });

  @override
  Future<void> loadResolvedAccountProfile(
      AccountProfileModel accountProfile) async {
    accountProfileStreamValue.addValue(null);
    profileConfigStreamValue.addValue(null);
  }
}

class _ErrorAccountProfileDetailController
    extends AccountProfileDetailController {
  _ErrorAccountProfileDetailController({
    required super.accountProfilesRepository,
  });

  @override
  Future<void> loadResolvedAccountProfile(
      AccountProfileModel accountProfile) async {
    errorMessageStreamValue.addValue('Falha ao preparar o perfil');
  }
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    Set<String> initialFavoriteIds = const <String>{},
  }) : _favoriteIds = Set<String>.from(initialFavoriteIds) {
    favoriteAccountProfileIdsStreamValue.addValue(
      _favoriteIds
          .map(
            (id) => AccountProfilesRepositoryContractPrimString.fromRaw(id),
          )
          .toSet(),
    );
  }

  final Set<String> _favoriteIds;
  final List<AccountProfileModel> _profiles = <AccountProfileModel>[];

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    return pagedAccountProfilesResultFromRaw(
      profiles: _profiles,
      hasMore: false,
    );
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    for (final profile in _profiles) {
      if (profile.slug == slug.value) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async =>
      _profiles;

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    if (_favoriteIds.contains(accountProfileId.value)) {
      _favoriteIds.remove(accountProfileId.value);
    } else {
      _favoriteIds.add(accountProfileId.value);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      _favoriteIds
          .map(
            (id) => AccountProfilesRepositoryContractPrimString.fromRaw(id),
          )
          .toSet(),
    );
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      _favoriteIds.contains(accountProfileId.value),
      defaultValue: false,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() => const [];
}

AccountProfileModel _buildArtistProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439011',
    name: 'Cafe de la Musique',
    slug: 'cafe-de-la-musique',
    type: 'artist',
    tags: const ['Sunset Premium', 'Praia', 'Guarapari'],
    agendaEvents: _buildArtistAgendaEvents(),
    isVerified: true,
    acceptedInvites: 87,
  );
}

AccountProfileModel _buildArtistLiveOnlyProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439011',
    name: 'Cafe de la Musique',
    slug: 'cafe-de-la-musique',
    type: 'artist',
    tags: const ['Sunset Premium', 'Praia', 'Guarapari'],
    agendaEvents: [_buildArtistAgendaEvents().first],
    isVerified: true,
    acceptedInvites: 87,
  );
}

AccountProfileModel _buildRestaurantProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439012',
    name: 'Casa Marracini',
    slug: 'casa-marracini',
    type: 'restaurant',
    coverUrl: 'https://example.com/casa-marracini-cover.jpg',
    distanceMeters: 752,
    locationLat: -20.7389,
    locationLng: -40.8212,
    agendaEvents: const [],
  );
}

AccountProfileModel _buildRestaurantWithAgendaProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439015',
    name: 'Casa Marracini',
    slug: 'casa-marracini-agenda',
    type: 'restaurant',
    coverUrl: 'https://example.com/casa-marracini-cover.jpg',
    distanceMeters: 752,
    locationLat: -20.7389,
    locationLng: -40.8212,
    agendaEvents: _buildRestaurantAgendaEvents(),
  );
}

AccountProfileModel _buildMinimalProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439013',
    name: 'Perfil Sem Seções',
    slug: 'perfil-sem-secoes',
    type: 'artist',
  );
}

AccountProfileModel _buildVenueWithBioProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439014',
    name: 'Ponta da Fruta',
    slug: 'ponta-da-fruta',
    type: 'venue',
    bio:
        '<p><strong>Manifesto Singular</strong></p><p>Texto de apoio da casa</p>',
  );
}

AccountProfileModel _buildVenueFullProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439055',
    name: 'Ponta da Fruta',
    slug: 'ponta-da-fruta',
    type: 'venue',
    bio: '<p>Experiência costeira com agenda ativa.</p>',
    locationLat: -20.7532,
    locationLng: -40.6067,
    agendaEvents: _buildRestaurantAgendaEvents(),
  );
}

List<PartnerEventView> _buildArtistAgendaEvents() {
  final now = DateTime.now().toUtc();
  return [
    buildPartnerEventView(
      eventId: '507f1f77bcf86cd799439021',
      occurrenceId: '507f1f77bcf86cd799439121',
      slug: 'jazz-na-orla',
      title: 'Jazz na Orla',
      eventTypeLabel: 'Show',
      location: 'Deck Principal',
      venueTitle: 'Cafe de la Musique',
      venueId: '507f1f77bcf86cd799439011',
      startDateTime: now.subtract(const Duration(minutes: 45)),
      endDateTime: now.add(const Duration(hours: 1)),
      artistNames: const ['Marco Aurélio'],
      artistIds: const ['507f1f77bcf86cd799439099'],
      imageUri: Uri.parse('https://example.com/jazz-na-orla.jpg'),
    ),
    buildPartnerEventView(
      eventId: '507f1f77bcf86cd799439022',
      occurrenceId: '507f1f77bcf86cd799439122',
      slug: 'sunset-premium',
      title: 'Sunset Premium',
      eventTypeLabel: 'Show',
      location: 'Terraço Panorâmico',
      venueTitle: 'Cafe de la Musique',
      venueId: '507f1f77bcf86cd799439011',
      startDateTime: now.add(const Duration(days: 1)),
      artistNames: const ['DJ Nightwave'],
      artistIds: const ['507f1f77bcf86cd799439098'],
      imageUri: Uri.parse('https://example.com/sunset-premium.jpg'),
    ),
  ];
}

List<PartnerEventView> _buildRestaurantAgendaEvents() {
  return [
    buildPartnerEventView(
      eventId: '507f1f77bcf86cd799439031',
      occurrenceId: '507f1f77bcf86cd799439131',
      slug: 'chef-table',
      title: 'Chef Table Experience',
      eventTypeLabel: 'Experiência',
      location: 'Salão Principal',
      venueId: '507f1f77bcf86cd799439015',
      venueTitle: 'Casa Marracini',
      startDateTime: DateTime.now().toUtc().add(const Duration(days: 1)),
      artistNames: const ['Marco Aurélio'],
      artistIds: const ['507f1f77bcf86cd799439099'],
      imageUri: Uri.parse('https://example.com/chef-table.jpg'),
    ),
  ];
}

AccountProfileModel _buildArtistHostAwareProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439099',
    name: 'Marco Aurélio',
    slug: 'marco-aurelio',
    type: 'artist',
    agendaEvents: [
      buildPartnerEventView(
        eventId: '507f1f77bcf86cd799439041',
        occurrenceId: '507f1f77bcf86cd799439141',
        slug: 'jazz-na-orla',
        title: 'Jazz na Orla',
        eventTypeLabel: 'Show',
        location: 'Deck Principal',
        venueId: '507f1f77bcf86cd799439015',
        venueTitle: 'Casa Marracini',
        startDateTime:
            DateTime.now().toUtc().add(const Duration(hours: 4)),
        artistNames: const ['Marco Aurélio', 'DJ Lua'],
        artistIds: const [
          '507f1f77bcf86cd799439099',
          '507f1f77bcf86cd799439199',
        ],
      ),
    ],
  );
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artista',
        'allowed_taxonomies': [],
        'visual': {
          'mode': 'icon',
          'icon': 'music_note',
          'color': '#7E22CE',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
          'has_events': true,
          'has_bio': false,
        },
      },
      {
        'type': 'venue',
        'label': 'Venue',
        'allowed_taxonomies': [],
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#7E22CE',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
          'has_events': true,
          'has_bio': true,
        },
      },
      {
        'type': 'restaurant',
        'label': 'Restaurante',
        'allowed_taxonomies': [],
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#16A34A',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
          'has_events': false,
          'has_bio': false,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#7E22CE',
    },
    'main_color': '#7E22CE',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': 'mobile',
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
