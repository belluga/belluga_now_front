import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/static_assets_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_state.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
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
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
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
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
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
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
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
        matching: find.byIcon(BooraIcons.musicalNote),
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

    final heroFallback = tester.widget<Container>(
      find.byKey(const Key('accountProfileHeroDefaultFallback')),
    );
    expect(heroFallback.alignment, const Alignment(0, -0.62));
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
    expect(
        find.byKey(const Key('accountProfileHeroTypeAvatar')), findsOneWidget);
  });

  testWidgets('hero fades cover into theme surface before profile data',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await GetIt.I.reset(dispose: false);
    GetIt.I.registerSingleton<AppData>(
      _buildAppData(restaurantReferenceLocationEnabled: true),
    );
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: buildAccountProfileModelFromPrimitives(
            id: '507f1f77bcf86cd799439115',
            name: 'QA Discovery Tag Longa',
            slug: 'qa-discovery-tag-longa',
            type: 'restaurant',
            coverUrl: 'https://tenant.test/cover.png',
            distanceMeters: 0,
            locationLat: -20.7389,
            locationLng: -40.8212,
            tags: const [
              'Super Festival Gastronômico Com Nome Muito Grande',
              'Música Instrumental Experimental Noturna',
              'Ao Vivo',
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(appBar.expandedHeight, 400);

    final summaryFinder = find.byKey(
      const Key('accountProfileHeroSurfaceSummary'),
    );
    expect(summaryFinder, findsOneWidget);

    final summaryContext = tester.element(summaryFinder);
    final colorScheme = Theme.of(summaryContext).colorScheme;

    final fadeBox = tester.widget<DecoratedBox>(
      find.byKey(const Key('accountProfileHeroFadeGradient')),
    );
    final decoration = fadeBox.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    expect(
      gradient.stops,
      const <double>[0, 0.16, 0.32, 0.48, 0.64, 0.8, 1],
    );
    expect(gradient.colors.first, Colors.transparent);
    expect(gradient.colors.last, colorScheme.surface);

    final title = tester.widget<Text>(
      find.descendant(
        of: summaryFinder,
        matching: find.text('QA Discovery Tag Longa'),
      ),
    );
    expect(title.style?.color, colorScheme.onSurface);

    final referencePointButton = find.byKey(
      const Key('accountProfileHeroReferencePointButton'),
    );
    expect(referencePointButton, findsOneWidget);
    final buttonLabel = tester.widget<Text>(
      find.descendant(
        of: referencePointButton,
        matching: find.text('Usar como ponto de referência'),
      ),
    );
    expect(buttonLabel.maxLines, 1);
  });

  testWidgets('account profile detail exposes the canonical share action',
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

    expect(find.byKey(const Key('accountProfileShareAction')), findsOneWidget);
    expect(
      find.byKey(const Key('accountProfileWhatsappAction')),
      findsOneWidget,
    );
  });

  testWidgets(
      'web authenticated favorite action toggles instead of leaving the page',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(authorized: true),
    );
    final router = _RecordingStackRouter();
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
          isWebRuntime: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountProfileFavoriteAction')));
    await tester.pumpAndSettle();

    expect(
      repository
          .isFavorite(
            AccountProfilesRepositoryContractPrimString.fromRaw(
              _buildArtistProfile().id,
            ),
          )
          .value,
      isTrue,
    );
    expect(router.lastPushedPath, isNull);
    expect(router.lastReplacedPath, isNull);
  });

  testWidgets(
      'web anonymous favorite action promotes app instead of phone login',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final authRepository = _FakeAuthRepository(authorized: false);
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      authRepository: authRepository,
    );
    final router = _RecordingStackRouter();
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    _registerAppPromotionController();

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
          isWebRuntime: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountProfileFavoriteAction')));
    await tester.pumpAndSettle();

    expect(find.text('Entrar para favoritar'), findsNothing);
    expect(find.byKey(const Key('app_promotion_modal')), findsOneWidget);
    expect(find.text('Escolha seus favoritos pelo app'), findsOneWidget);
    expect(
      find.text('Use o app para salvar perfis favoritos e receber novidades.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('app_promotion_store_badge_android')),
      findsOneWidget,
    );
    expect(
      repository
          .isFavorite(
            AccountProfilesRepositoryContractPrimString.fromRaw(
              _buildArtistProfile().id,
            ),
          )
          .value,
      isFalse,
    );
    expect(router.lastPushedPath, isNull);
    expect(router.lastReplacedPath, isNull);
  });

  testWidgets(
      'non-web anonymous favorite action redirects to login with replay path',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(authorized: false),
    );
    final router = _RecordingStackRouter();
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
          isWebRuntime: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountProfileFavoriteAction')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app_promotion_modal')), findsNothing);
    expect(
      repository
          .isFavorite(
            AccountProfilesRepositoryContractPrimString.fromRaw(
              _buildArtistProfile().id,
            ),
          )
          .value,
      isFalse,
    );
    expect(router.lastPushedPath, isNull);
    expect(
      router.lastReplacedPath,
      '/auth/login?redirect=%2Fparceiro%2Fteste',
    );
  });

  testWidgets('account profile WhatsApp action uses public profile payload',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    final sharedParams = <ShareParams>[];
    final launchedUris = <Uri>[];
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
          shareLauncher: (params) async {
            sharedParams.add(params);
          },
          externalUrlLauncher: (uri, {required mode}) async {
            launchedUris.add(uri);
            expect(mode, LaunchMode.externalApplication);
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountProfileWhatsappAction')));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(2));
    expect(launchedUris.first.scheme, 'whatsapp');
    expect(launchedUris.first.host, 'send');
    expect(launchedUris.last.host, 'wa.me');
    expect(
      launchedUris.last.queryParameters['text'],
      contains('https://tenant.test/parceiro/cafe-de-la-musique'),
    );
    expect(sharedParams, hasLength(1));
    expect(sharedParams.single.subject, 'Cafe de la Musique');
    expect(sharedParams.single.text, contains('Cafe de la Musique'));
    expect(
      sharedParams.single.text,
      contains('https://tenant.test/parceiro/cafe-de-la-musique'),
    );
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
    expect(
        find.byKey(const Key('accountProfileHeroTypeAvatar')), findsOneWidget);
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

  testWidgets(
      'artist profile hides agenda CTA after profile is already favorited',
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
      'renders directions section and inline provider actions for restaurant with POI coordinates',
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
    expect(find.text('Traçar rota'), findsNothing);
    expect(find.text('Seguir'), findsNothing);
    expect(find.byKey(const Key('accountProfileLocationTile')), findsOneWidget);
    expect(find.byKey(const Key('accountProfileLocationDistanceBadge')),
        findsOneWidget);
    expect(
        find.byKey(const Key('accountProfileRouteFooterButton')), findsNothing);
    expect(
        find.byKey(const Key('accountProfileMainWazeButton')), findsOneWidget);
    expect(
        find.byKey(const Key('accountProfileMainUberButton')), findsOneWidget);
    expect(find.byKey(const Key('accountProfileMainOtherDirectionsButton')),
        findsOneWidget);
    expect(find.bySemanticsLabel('Outros'), findsOneWidget);
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

    expect(
        find.byKey(const Key('accountProfileFavoriteAction')), findsOneWidget);

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    final collapsedTitle = tester.widget<Text>(
      find.byKey(const Key('immersiveCollapsedTitle')),
    );
    final sliverAppBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    final collapsedHeaderCenter = tester.getCenter(
      find.byKey(const Key('immersiveCollapsedTitle')),
    );
    final navigationToolbarRect =
        tester.getRect(find.byType(NavigationToolbar));
    final toolbarCenterY = navigationToolbarRect.center.dy;

    expect(
        find.byKey(const Key('accountProfileFavoriteAction')), findsOneWidget);
    expect(find.byKey(const Key('accountProfileCollapsedIdentitySurface')),
        findsNothing);
    expect(find.byKey(const Key('immersiveCollapsedTitle')), findsOneWidget);
    expect(find.text('Cafe de la Musique'), findsWidgets);
    expect(collapsedTitle.maxLines, 2);
    expect(collapsedTitle.overflow, TextOverflow.ellipsis);
    expect(sliverAppBar.toolbarHeight, 72);
    expect((collapsedHeaderCenter.dy - toolbarCenterY).abs(),
        lessThanOrEqualTo(8));
  });

  testWidgets(
      'collapsed header keeps only the account title readable after hero scroll',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfileWithManyTaxonomies().copyWith(
            nameValue: TitleValue()
              ..parse('Pop Rock Nacional e Internacional na Orla'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveCollapsedTitle')), findsOneWidget);
    final collapsedTitleFinder = find.byKey(
      const Key('immersiveCollapsedTitle'),
    );
    final collapsedTitle = tester.widget<Text>(collapsedTitleFinder);
    final collapsedTitleRect = tester.getRect(collapsedTitleFinder);
    final navigationToolbarRect =
        tester.getRect(find.byType(NavigationToolbar));

    expect(collapsedTitle.maxLines, 2);
    expect(
      collapsedTitleRect.top,
      greaterThanOrEqualTo(navigationToolbarRect.top - 0.5),
    );
    expect(
      collapsedTitleRect.bottom,
      lessThanOrEqualTo(navigationToolbarRect.bottom + 0.5),
    );
    expect(find.byKey(const Key('accountProfileCollapsedTaxonomySummary')),
        findsNothing);
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
    final expectedSchedule = liveEvent.expandedScheduleLabel;

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
      tester
          .widget<Text>(
            find.byKey(
              const Key(
                'accountProfileAgendaLiveEyebrow_507f1f77bcf86cd799439121',
              ),
            ),
          )
          .data,
      'Show',
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(
                const Key(
                  'accountProfileAgendaLiveSchedule_507f1f77bcf86cd799439121',
                ),
              ),
              matching: find.byType(Text),
            ),
          )
          .data,
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

  testWidgets('live agenda highlight compresses counterpart chips as e mais X',
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
          accountProfile: _buildProfileWithCrowdedLiveAgenda(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(
          const Key(
            'accountProfileAgendaLiveCounterparts_507f1f77bcf86cd799439151',
          ),
        ),
        matching: find.text('Ananda Torres'),
      ),
      findsOneWidget,
    );
    expect(find.text('e mais 2'), findsOneWidget);
    expect(find.text('DJ Lua'), findsNothing);
    expect(find.text('Coletivo Sol'), findsNothing);
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

  testWidgets(
      'agenda keeps a future occurrence visible when the backend readback repeats event_id with a different occurrence_id',
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
          accountProfile: _buildArtistRecurringOccurrenceProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acontecendo Agora'), findsOneWidget);
    expect(find.text('Próximos Eventos'), findsOneWidget);
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaLiveCard_507f1f77bcf86cd799439221',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'accountProfileAgendaCardHeadline_507f1f77bcf86cd799439222',
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

  testWidgets(
      'renders nested account profile groups as custom tabs and navigates linked profile',
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
          accountProfile: _buildVenueFullProfile().copyWith(
            nestedProfileGroupValues: [_buildNestedAccountProfileGroup()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_3'))).data,
      'Parceiros',
    );

    await tester.ensureVisible(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountProfileNestedGroup_parceiros')),
        findsOneWidget);
    expect(find.text('Ananda Torres'), findsOneWidget);
    expect(find.text('Música'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key(
          'accountProfileNestedCard_parceiros_507f1f77bcf86cd799439081',
        ),
      ),
    );
    await tester.pump();

    expect(router.lastPushedPath, '/parceiro/ananda-torres');
  });

  testWidgets(
      'renders non navigable nested members without chevron and does not navigate',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter();

    final nonNavigableGroup = AccountProfileNestedGroup(
      idValue: AccountProfileNestedGroupIdValue('parceiros'),
      labelValue: AccountProfileNestedGroupLabelValue('Parceiros'),
      orderValue: AccountProfileNestedGroupOrderValue(0),
      profiles: [
        AccountProfileNestedGroupMember(
          idValue: MongoIDValue()..parse('507f1f77bcf86cd799439082'),
          nameValue: TitleValue()..parse('Parceiro Sem Link'),
          profileTypeValue: AccountProfileTypeValue('guest_public'),
          canOpenPublicDetailValue: DomainBooleanValue(
            defaultValue: false,
            isRequired: false,
          )..parse('false'),
          tagValues: [AccountProfileTagValue('Convidado')],
        ),
      ],
    );

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildVenueFullProfile().copyWith(
            nestedProfileGroupValues: [nonNavigableGroup],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(
      const Key('accountProfileNestedCard_parceiros_507f1f77bcf86cd799439082'),
    );
    expect(cardFinder, findsOneWidget);
    expect(
      find.descendant(
          of: cardFinder, matching: find.byIcon(Icons.chevron_right)),
      findsNothing,
    );

    await tester.tap(cardFinder);
    await tester.pump();

    expect(router.lastPushedPath, isNull);
  });

  testWidgets(
      'keeps parent profile data when a stacked partner detail changes repository selection',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final parentProfile = _buildVenueFullProfile().copyWith(
      nameValue: TitleValue()..parse('Du Jorge'),
      slugValue: SlugValue()..parse('du-jorge'),
      nestedProfileGroupValues: [_buildNestedAccountProfileGroup()],
    );
    final childProfile = _buildArtistProfile().copyWith(
      nameValue: TitleValue()..parse('QA Discovery Tag Várias Tags'),
      slugValue: SlugValue()..parse('qa-discovery-tag-varias-tags'),
    );

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: parentProfile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.pumpAndSettle();

    repository.setSelectedAccountProfile(childProfile);
    await tester.pumpAndSettle();

    final heroSummary = find.byKey(
      const Key('accountProfileHeroSurfaceSummary'),
    );
    expect(
      find.descendant(of: heroSummary, matching: find.text('Du Jorge')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: heroSummary,
        matching: find.text('QA Discovery Tag Várias Tags'),
      ),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_3'))).data,
      'Parceiros',
    );
    expect(find.byKey(const Key('accountProfileNestedGroup_parceiros')),
        findsOneWidget);
  });

  testWidgets(
      'back from a nested linked profile restores the parent account detail',
      (tester) async {
    final parentProfile = _buildVenueFullProfile().copyWith(
      nameValue: TitleValue()..parse('Du Jorge'),
      slugValue: SlugValue()..parse('du-jorge'),
      nestedProfileGroupValues: [_buildNestedAccountProfileGroup()],
    );
    final childProfile = _buildArtistProfile().copyWith(
      idValue: MongoIDValue()..parse('507f1f77bcf86cd799439081'),
      nameValue: TitleValue()..parse('Ananda Torres'),
      slugValue: SlugValue()..parse('ananda-torres'),
    );
    final repository = _FakeAccountProfilesRepository(
      profiles: [parentProfile, childProfile],
    );
    GetIt.I.registerSingleton<AccountProfilesRepositoryContract>(repository);
    GetIt.I.registerSingleton<StaticAssetsRepositoryContract>(
      _FakeStaticAssetsRepository(),
    );
    GetIt.I.registerSingleton<DiscoveryModule>(DiscoveryModule());

    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'discovery-test-root',
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('openParentAccountDetail'),
                onPressed: () => context.router.push(
                  PartnerDetailRoute(slug: 'du-jorge'),
                ),
                child: const Text('Abrir Du Jorge'),
              ),
            ),
          ),
        ),
        AutoRoute(
          path: '/parceiro/:slug',
          page: PartnerDetailRoute.page,
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.partnerDetail,
          ),
        ),
      ],
    )..ignorePopCompleters = true;

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routeInformationParser: router.defaultRouteParser(),
        routerDelegate: router.delegate(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('openParentAccountDetail')));
    await tester.pumpAndSettle();

    final parentHeroSummary = find.byKey(
      const Key('accountProfileHeroSurfaceSummary'),
    );
    expect(
      find.descendant(of: parentHeroSummary, matching: find.text('Du Jorge')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key(
          'accountProfileNestedCard_parceiros_507f1f77bcf86cd799439081',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final childHeroSummary = find.byKey(
      const Key('accountProfileHeroSurfaceSummary'),
    );
    expect(
      find.descendant(
        of: childHeroSummary,
        matching: find.text('Ananda Torres'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    final restoredParentHeroSummary = find.byKey(
      const Key('accountProfileHeroSurfaceSummary'),
    );
    expect(
      find.descendant(
        of: restoredParentHeroSummary,
        matching: find.text('Du Jorge'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: restoredParentHeroSummary,
        matching: find.text('Ananda Torres'),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('accountProfileNestedGroup_parceiros')),
        findsOneWidget);
  });

  testWidgets(
      'nested linked profile routes keep isolated detail controller instances',
      (tester) async {
    final parentProfile = _buildVenueFullProfile().copyWith(
      nameValue: TitleValue()..parse('Du Jorge'),
      slugValue: SlugValue()..parse('du-jorge'),
      nestedProfileGroupValues: [_buildNestedAccountProfileGroup()],
    );
    final childProfile = _buildArtistProfile().copyWith(
      idValue: MongoIDValue()..parse('507f1f77bcf86cd799439081'),
      nameValue: TitleValue()..parse('Ananda Torres'),
      slugValue: SlugValue()..parse('ananda-torres'),
    );
    final repository = _FakeAccountProfilesRepository(
      profiles: [parentProfile, childProfile],
    );
    final createdControllers = <_TrackingAccountProfileDetailController>[];
    GetIt.I.registerSingleton<AccountProfilesRepositoryContract>(repository);
    GetIt.I.registerSingleton<StaticAssetsRepositoryContract>(
      _FakeStaticAssetsRepository(),
    );
    GetIt.I.registerFactory<AccountProfileDetailController>(() {
      final controller = _TrackingAccountProfileDetailController(
        id: createdControllers.length + 1,
        accountProfilesRepository: repository,
      );
      createdControllers.add(controller);
      return controller;
    });
    GetIt.I.registerSingleton<DiscoveryModule>(DiscoveryModule());

    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'discovery-test-root',
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('openParentAccountDetail'),
                onPressed: () => context.router.push(
                  PartnerDetailRoute(slug: 'du-jorge'),
                ),
                child: const Text('Abrir Du Jorge'),
              ),
            ),
          ),
        ),
        AutoRoute(
          path: '/parceiro/:slug',
          page: PartnerDetailRoute.page,
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.partnerDetail,
          ),
        ),
      ],
    )..ignorePopCompleters = true;

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routeInformationParser: router.defaultRouteParser(),
        routerDelegate: router.delegate(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('openParentAccountDetail')));
    await tester.pumpAndSettle();

    expect(createdControllers, hasLength(1));
    final parentController = createdControllers.single;
    expect(parentController.id, 1);
    expect(parentController.loadedSlugs, contains('du-jorge'));

    await tester.ensureVisible(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.tap(find.byKey(const Key('immersiveTabLabel_3')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key(
          'accountProfileNestedCard_parceiros_507f1f77bcf86cd799439081',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(createdControllers, hasLength(2));
    final childController = createdControllers.last;
    expect(childController.id, 2);
    expect(identical(parentController, childController), isFalse);
    expect(childController.loadedSlugs, contains('ananda-torres'));
    expect(parentController.disposed, isFalse);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(createdControllers, hasLength(2));
    expect(parentController.disposed, isFalse);
    expect(childController.disposed, isTrue);
    expect(
      parentController.detailStateStreamValue.value.accountProfile?.slug,
      'du-jorge',
    );
    expect(find.text('Du Jorge'), findsWidgets);
    expect(
      find.byKey(const Key('accountProfileNestedGroup_parceiros')),
      findsOneWidget,
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

    expect(find.byIcon(BooraIcons.inviteSolid), findsNothing);
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

  testWidgets(
      'tapping location tile opens in-app map focused on account profile poi',
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

  testWidgets('tapping inline directions delegates to shared directions widget',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    final chooser = _RecordingDirectionsAppChooser();
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
          directionsAppChooser: chooser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final otherDirectionsButton =
        find.byKey(const Key('accountProfileMainOtherDirectionsButton'));
    await tester.ensureVisible(otherDirectionsButton);
    await tester.pumpAndSettle();
    await tester.tap(otherDirectionsButton);
    await tester.pump();

    expect(chooser.presentCallCount, 1);
    expect(chooser.lastTarget?.destinationName, 'Casa Marracini');
    expect(chooser.lastTarget?.latitude, closeTo(-20.7389, 0.00001));
    expect(chooser.lastTarget?.longitude, closeTo(-40.8212, 0.00001));

    final wazeButton = find.byKey(const Key('accountProfileMainWazeButton'));
    await tester.ensureVisible(wazeButton);
    await tester.pumpAndSettle();
    await tester.tap(wazeButton);
    await tester.pump();

    expect(chooser.directCallCount, 1);
    expect(chooser.lastDirectProvider, DirectionsDirectProvider.waze);
    expect(chooser.lastDirectTarget?.destinationName, 'Casa Marracini');
    expect(chooser.lastDirectTarget?.latitude, closeTo(-20.7389, 0.00001));
    expect(chooser.lastDirectTarget?.longitude, closeTo(-40.8212, 0.00001));
  });

  testWidgets(
      'hero saves eligible account profile as ponto de referência with provenance',
      (tester) async {
    await GetIt.I.reset(dispose: false);
    GetIt.I.registerSingleton<AppData>(
      _buildAppData(restaurantReferenceLocationEnabled: true),
    );
    final repository = _FakeAccountProfilesRepository();
    final proximityRepository = _FakeProximityPreferencesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      proximityPreferencesRepository: proximityRepository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildAutoRouteTestApp(
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final referencePointButton = find.byKey(
      const Key('accountProfileHeroReferencePointButton'),
    );
    expect(find.text('Usar como ponto de referência'), findsOneWidget);
    expect(
      find.descendant(
        of: referencePointButton,
        matching: find.byIcon(Icons.location_on_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(referencePointButton);
    await tester.pumpAndSettle();

    expect(proximityRepository.lastFixedReference, isNull);
    expect(
      find.byKey(const Key('accountProfileReferencePointDialogCopy')),
      findsOneWidget,
    );
    final previewCard = find.byKey(
      const Key('accountProfileReferencePointPreviewCard'),
    );
    expect(previewCard, findsOneWidget);
    expect(
      find.descendant(of: previewCard, matching: find.text('Casa Marracini')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: previewCard, matching: find.text('Restaurante')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('accountProfileReferencePointConfirmButton')),
    );
    await tester.pumpAndSettle();

    final fixedReference = proximityRepository.lastFixedReference;
    expect(fixedReference, isNotNull);
    expect(fixedReference!.entityNamespace, 'account_profile');
    expect(fixedReference.entityType, 'restaurant');
    expect(fixedReference.entityId, '507f1f77bcf86cd799439012');
    expect(fixedReference.entitySlug, 'casa-marracini');
    expect(fixedReference.label, 'Casa Marracini');
    expect(fixedReference.coordinate.latitude, closeTo(-20.7389, 0.00001));
    expect(fixedReference.coordinate.longitude, closeTo(-40.8212, 0.00001));
    expect(find.text('Ponto de referência'), findsOneWidget);
  });

  testWidgets('hero renders current ponto de referência selected state',
      (tester) async {
    await GetIt.I.reset(dispose: false);
    GetIt.I.registerSingleton<AppData>(
      _buildAppData(restaurantReferenceLocationEnabled: true),
    );
    final profile = _buildRestaurantProfile();
    final repository = _FakeAccountProfilesRepository();
    final proximityRepository = _FakeProximityPreferencesRepository(
      fixedReference: _fixedReferenceFor(profile),
    );
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      proximityPreferencesRepository: proximityRepository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildAutoRouteTestApp(
        child: AccountProfileDetailScreen(accountProfile: profile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ponto de referência'), findsOneWidget);
    expect(find.text('Usar como ponto de referência'), findsNothing);
    expect(
      find.byKey(const Key('accountProfileHeroClearReferencePointButton')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('accountProfileHeroClearReferencePointButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('accountProfileClearReferencePointDialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('accountProfileClearReferencePointConfirmButton')),
    );
    await tester.pumpAndSettle();

    expect(proximityRepository.clearFixedReferenceCalls, 1);
    expect(proximityRepository.lastFixedReference, isNull);
    expect(find.text('Usar como ponto de referência'), findsOneWidget);
  });

  testWidgets('hero hides reference point action when capability is disabled',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
      proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildRestaurantProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usar como ponto de referência'), findsNothing);
    expect(
      find.byKey(const Key('accountProfileHeroReferencePointButton')),
      findsNothing,
    );
  });

  testWidgets(
      'renders favorite CTA fallback when no tabs are available and profile is favoritable',
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
          accountProfile: _buildMinimalProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('accountProfileNoSectionsFallback')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Favorite para ser avisado das novidades sobre Perfil Sem Seções.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('accountProfileFavoriteFooterButton')),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps neutral fallback when no tabs are available and profile is already favorited',
      (tester) async {
    final repository = _FakeAccountProfilesRepository(
      initialFavoriteIds: const {'507f1f77bcf86cd799439013'},
    );
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildMinimalProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mais sobre este perfil'), findsOneWidget);
    expect(
      find.text(
        'Favorite para ser avisado das novidades sobre Perfil Sem Seções.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('accountProfileFavoriteFooterButton')),
      findsNothing,
    );
  });

  testWidgets(
      'keeps neutral fallback when no tabs are available and profile is not favoritable',
      (tester) async {
    await GetIt.I.reset(dispose: false);
    GetIt.I.registerSingleton<AppData>(_buildAppData(artistFavoritable: false));

    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildMinimalProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mais sobre este perfil'), findsOneWidget);
    expect(
      find.text(
        'Favorite para ser avisado das novidades sobre Perfil Sem Seções.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('accountProfileFavoriteFooterButton')),
      findsNothing,
    );
  });

  testWidgets('renders bio only once and without raw html tags',
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
          accountProfile: _buildVenueWithBioProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manifesto Singular'), findsOneWidget);
    expect(find.text('Texto de apoio da casa'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Conteúdo'), findsNothing);
    expect(find.textContaining('<p>'), findsNothing);
    expect(find.textContaining('<strong>'), findsNothing);
  });

  testWidgets(
      'renders account profile bio and content as independent Sobre blocks',
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
          accountProfile: _buildVenueWithBioAndContentProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sobre'), findsNWidgets(2));
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(find.text('Resumo da casa'), findsOneWidget);
    expect(find.text('Programação curatorial'), findsOneWidget);
    expect(find.text('Conteúdo principal do perfil 😄'), findsOneWidget);
  });

  testWidgets('renders content-only profile without redundant nested heading',
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
          accountProfile: _buildVenueWithContentOnlyProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Conteúdo'), findsNothing);
    expect(find.text('Conteúdo institucional sem bio'), findsOneWidget);
  });

  testWidgets('renders legacy plain text newlines faithfully', (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: AccountProfileDetailScreen(
          accountProfile: _buildVenueWithPlainTextBioProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Primeira linha'), findsOneWidget);
    expect(find.text('Segunda linha'), findsOneWidget);
    expect(find.text('Novo parágrafo'), findsOneWidget);
  });

  testWidgets(
      'partner detail back falls back to discovery when no history exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
        router.replaceAllRoutes.single.single.routeName, DiscoveryRoute.name);
  });

  testWidgets(
      'partner detail system back falls back to discovery when no history exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
        router.replaceAllRoutes.single.single.routeName, DiscoveryRoute.name);
  });

  testWidgets('partner detail back pops when previous history exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter()..canPopResult = true;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets('partner detail system back pops when previous history exists',
      (tester) async {
    final repository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: repository,
    );
    GetIt.I.registerSingleton<AccountProfileDetailController>(controller);
    final router = _RecordingStackRouter()..canPopResult = true;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: AccountProfileDetailScreen(
          accountProfile: _buildArtistProfile(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });
}

Widget _buildAutoRouteTestApp({
  required Widget child,
  ThemeData? theme,
}) {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'partner-detail-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.partnerDetail,
        ),
        builder: (_, __) => RouteInstanceScope(child: child),
      ),
    ],
  )..ignorePopCompleters = true;

  return MaterialApp.router(
    theme: theme,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const <Locale>[Locale('pt', 'BR')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routeInformationParser: router.defaultRouteParser(),
    routerDelegate: router.delegate(),
  );
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
  required Widget child,
  ThemeData? theme,
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
      theme: theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RouteDataScope(
        routeData: routeData,
        child: RouteInstanceScope(child: child),
      ),
    ),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  String? lastPushedPath;
  String? lastReplacedPath;
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes = [];

  @override
  RootStackRouter get root => _FakeRootStackRouter('/parceiro/ananda-torres');

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
    required this.fullPath,
    String? name,
    Map<String, dynamic>? meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
    Map<String, dynamic> queryParams = const {},
  })  : name = name ?? PartnerDetailRoute.name,
        meta = meta ??
            canonicalRouteMeta(
              family: CanonicalRouteFamily.partnerDetail,
            ),
        pageRouteInfo = pageRouteInfo ?? const DiscoveryRoute(),
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

class _RecordingDirectionsAppChooser implements DirectionsAppChooserContract {
  int presentCallCount = 0;
  int directCallCount = 0;
  DirectionsLaunchTarget? lastTarget;
  DirectionsDirectProvider? lastDirectProvider;
  DirectionsLaunchTarget? lastDirectTarget;

  @override
  Future<List<DirectionsAppChoice>> loadOptions({
    required DirectionsLaunchTarget target,
  }) async =>
      const <DirectionsAppChoice>[];

  @override
  Future<bool> launchDirect({
    required DirectionsDirectProvider provider,
    required DirectionsLaunchTarget target,
  }) async {
    directCallCount += 1;
    lastDirectProvider = provider;
    lastDirectTarget = target;
    return true;
  }

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

class _FakeProximityPreferencesRepository
    extends ProximityPreferencesRepositoryContract {
  _FakeProximityPreferencesRepository({
    FixedLocationReference? fixedReference,
  }) {
    if (fixedReference != null) {
      setCurrentPreference(_preferenceWith(fixedReference));
    }
  }

  FixedLocationReference? lastFixedReference;
  int clearFixedReferenceCalls = 0;

  @override
  Future<void> setFixedReference({
    required FixedLocationReference fixedReference,
  }) async {
    lastFixedReference = fixedReference;
    setCurrentPreference(_preferenceWith(fixedReference));
  }

  @override
  Future<void> clearFixedReference() async {
    clearFixedReferenceCalls += 1;
    lastFixedReference = null;
    setCurrentPreference(
      ProximityPreference(
        maxDistanceMetersValue: DistanceInMetersValue.fromRaw(25000),
        locationPreference:
            const ProximityLocationPreference.liveDeviceLocation(),
      ),
    );
  }

  ProximityPreference _preferenceWith(FixedLocationReference fixedReference) {
    return ProximityPreference(
      maxDistanceMetersValue: DistanceInMetersValue.fromRaw(25000),
      locationPreference: ProximityLocationPreference.fixedReference(
        fixedReference: fixedReference,
      ),
    );
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
    detailStateStreamValue.addValue(AccountProfileDetailState.empty);
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

class _TrackingAccountProfileDetailController
    extends AccountProfileDetailController {
  _TrackingAccountProfileDetailController({
    required this.id,
    required super.accountProfilesRepository,
  });

  final int id;
  final loadedSlugs = <String>[];
  bool disposed = false;

  @override
  Future<void> loadResolvedAccountProfile(
    AccountProfileModel accountProfile,
  ) {
    loadedSlugs.add(accountProfile.slug);
    return super.loadResolvedAccountProfile(accountProfile);
  }

  @override
  void onDispose() {
    disposed = true;
    super.onDispose();
  }
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
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

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

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    Set<String> initialFavoriteIds = const <String>{},
    List<AccountProfileModel> profiles = const <AccountProfileModel>[],
  })  : _favoriteIds = Set<String>.from(initialFavoriteIds),
        _profiles = List<AccountProfileModel>.from(profiles) {
    favoriteAccountProfileIdsStreamValue.addValue(
      _favoriteIds
          .map(
            (id) => AccountProfilesRepositoryContractPrimString.fromRaw(id),
          )
          .toSet(),
    );
  }

  final Set<String> _favoriteIds;
  final List<AccountProfileModel> _profiles;

  @override
  Future<void> init() async {}

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
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
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

class _FakeStaticAssetsRepository implements StaticAssetsRepositoryContract {
  @override
  Future<PublicStaticAssetModel?> getStaticAssetByRef(
    StaticAssetRepoText assetRef,
  ) async =>
      null;
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

AccountProfileModel _buildArtistProfileWithManyTaxonomies() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439011',
    name: 'Cafe de la Musique',
    slug: 'cafe-de-la-musique',
    type: 'artist',
    tags: const [
      'Sunset Premium',
      'Praia',
      'Guarapari',
      'Teatro Experimental',
      'Gastronomia Autoral',
    ],
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

AccountProfileModel _buildArtistRecurringOccurrenceProfile() {
  final now = DateTime.now().toUtc();
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439011',
    name: 'Cafe de la Musique',
    slug: 'cafe-de-la-musique',
    type: 'artist',
    tags: const ['Sunset Premium', 'Praia', 'Guarapari'],
    agendaEvents: [
      buildPartnerEventView(
        eventId: '507f1f77bcf86cd799439021',
        occurrenceId: '507f1f77bcf86cd799439221',
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
        eventId: '507f1f77bcf86cd799439021',
        occurrenceId: '507f1f77bcf86cd799439222',
        slug: 'jazz-na-orla',
        title: 'Jazz na Orla',
        eventTypeLabel: 'Show',
        location: 'Deck Principal',
        venueTitle: 'Cafe de la Musique',
        venueId: '507f1f77bcf86cd799439011',
        startDateTime: now.add(const Duration(days: 1)),
        artistNames: const ['Marco Aurélio'],
        artistIds: const ['507f1f77bcf86cd799439099'],
        imageUri: Uri.parse('https://example.com/jazz-na-orla.jpg'),
      ),
    ],
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

FixedLocationReference _fixedReferenceFor(AccountProfileModel profile) {
  return FixedLocationReference(
    sourceKind: FixedLocationReferenceSourceKind.entityReference,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse(profile.locationLat.toString()),
      longitudeValue: LongitudeValue()..parse(profile.locationLng.toString()),
    ),
    labelValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.name),
    entityNamespaceValue:
        ProximityPreferenceOptionalTextValue.fromRaw('account_profile'),
    entityTypeValue:
        ProximityPreferenceOptionalTextValue.fromRaw(profile.profileType),
    entityIdValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.id),
    entitySlugValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.slug),
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

AccountProfileModel _buildVenueWithBioAndContentProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439024',
    name: 'Casa de Cultura',
    slug: 'casa-de-cultura',
    type: 'venue',
    bio: '<p><strong>Resumo da casa</strong></p>',
    content:
        '<h2>Programação curatorial</h2><p>Conteúdo principal do perfil 😄</p>',
  );
}

AccountProfileModel _buildVenueWithContentOnlyProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439025',
    name: 'Ateliê Aberto',
    slug: 'atelie-aberto',
    type: 'venue',
    content: '<p>Conteúdo institucional sem bio</p>',
  );
}

AccountProfileModel _buildVenueWithPlainTextBioProfile() {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439026',
    name: 'Casa da Orla',
    slug: 'casa-da-orla',
    type: 'venue',
    bio: 'Primeira linha\nSegunda linha\n\nNovo parágrafo',
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

AccountProfileNestedGroup _buildNestedAccountProfileGroup() {
  return AccountProfileNestedGroup(
    idValue: AccountProfileNestedGroupIdValue('parceiros'),
    labelValue: AccountProfileNestedGroupLabelValue('Parceiros'),
    orderValue: AccountProfileNestedGroupOrderValue(0),
    profiles: [
      AccountProfileNestedGroupMember(
        idValue: MongoIDValue()..parse('507f1f77bcf86cd799439081'),
        nameValue: TitleValue()..parse('Ananda Torres'),
        slugValue: SlugValue()..parse('ananda-torres'),
        profileTypeValue: AccountProfileTypeValue('artist'),
        canOpenPublicDetailValue: DomainBooleanValue(
          defaultValue: false,
          isRequired: false,
        )..parse('true'),
        publicDetailPathValue: AccountProfileNestedGroupMemberTextValue(
          '/parceiro/ananda-torres',
        ),
        tagValues: [AccountProfileTagValue('Música')],
      ),
    ],
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
        startDateTime: DateTime.now().toUtc().add(const Duration(hours: 4)),
        artistNames: const ['Marco Aurélio', 'DJ Lua'],
        artistIds: const [
          '507f1f77bcf86cd799439099',
          '507f1f77bcf86cd799439199',
        ],
      ),
    ],
  );
}

AccountProfileModel _buildProfileWithCrowdedLiveAgenda() {
  final now = DateTime.now().toUtc();
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439151',
    name: 'Casa do Som',
    slug: 'casa-do-som',
    type: 'restaurant',
    agendaEvents: [
      buildPartnerEventView(
        eventId: '507f1f77bcf86cd799439051',
        occurrenceId: '507f1f77bcf86cd799439151',
        slug: 'noite-colaborativa',
        title: 'Noite Colaborativa',
        eventTypeLabel: 'Show',
        location: 'Palco Principal',
        venueId: '507f1f77bcf86cd799439151',
        venueTitle: 'Casa do Som',
        startDateTime: now.subtract(const Duration(minutes: 20)),
        endDateTime: now.add(const Duration(hours: 2)),
        artistNames: const ['Ananda Torres', 'DJ Lua', 'Coletivo Sol'],
        artistIds: const [
          '507f1f77bcf86cd799439152',
          '507f1f77bcf86cd799439153',
          '507f1f77bcf86cd799439154',
        ],
        imageUri: Uri.parse('https://example.com/noite-colaborativa.jpg'),
      ),
    ],
  );
}

void _registerAppPromotionController() {
  final appDataRepository = _FakeAppDataRepository(_buildAppData());
  GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
  GetIt.I.registerSingleton<AppPromotionScreenController>(
    AppPromotionScreenController(
      appDataRepository: appDataRepository,
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.android,
    ),
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

AppData _buildAppData({
  bool artistFavoritable = true,
  bool restaurantReferenceLocationEnabled = false,
}) {
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
          'is_favoritable': artistFavoritable,
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
          'has_content': true,
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
          'is_reference_location_enabled': restaurantReferenceLocationEnabled,
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
