import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders approved minimal copy baseline', (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PERMISSÃO'), findsOneWidget);
    expect(find.text('Veja o que está perto de você'), findsOneWidget);
    expect(
      find.text(
        'Ative sua localização para mostrar eventos e lugares mais relevantes próximos de você.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Usamos sua localização apenas para melhorar a ordem e a relevância do que aparece para você.',
      ),
      findsNothing,
    );
    expect(find.text('Permitir localização'), findsOneWidget);
    expect(find.text('Continuar sem localização'), findsOneWidget);
    expect(find.text('Eventos e Gastronomia • 400m'), findsOneWidget);

    final titleTop =
        tester.getTopLeft(find.text('Veja o que está perto de você')).dy;
    final heroTop =
        tester.getTopLeft(find.text('Eventos e Gastronomia • 400m')).dy;
    expect(titleTop, lessThan(heroTop));
  });

  testWidgets('deniedForever shows explicit unblock instructions',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.deniedForever,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Como liberar:'), findsOneWidget);
    expect(find.text('1. Toque em Abrir configurações.'), findsOneWidget);
    expect(find.text('2. Entre em Permissões > Localização.'), findsOneWidget);
    expect(find.text('Abrir configurações'), findsOneWidget);
    expect(find.text('Veja o que está perto de você'), findsOneWidget);
  });

  testWidgets('live-only mode exposes Agora não instead of continue copy',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          allowContinueWithoutLocation: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Agora não'), findsOneWidget);
    expect(find.text('Continuar sem localização'), findsNothing);
  });

  testWidgets('secondary action returns continue without location result',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);
    LocationPermissionGateResult? capturedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          onResult: (result) => capturedResult = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Continuar sem localização'));
    await tester.pump();

    expect(
      capturedResult,
      LocationPermissionGateResult.continueWithoutLocation,
    );
  });

  testWidgets('granted permission result returns granted gate outcome',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);
    LocationPermissionGateResult? capturedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          onResult: (result) => capturedResult = result,
        ),
      ),
    );
    await tester.pump();

    controller.resultStreamValue.addValue(true);
    await tester.pump();
    await tester.pump();

    expect(capturedResult, LocationPermissionGateResult.granted);
  });

  testWidgets('failed permission result keeps screen open and shows feedback',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );
    await tester.pump();

    controller.resultStreamValue.addValue(false);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LocationPermissionScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Não foi possível liberar'), findsOneWidget);
  });

  testWidgets('back button falls back to home when there is no stack',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter();
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(router.popCalls, 0);
    expect(router.replaceAllCalls, 1);
    expect(router.lastReplaceAllRoutes?.single.routeName, TenantHomeRoute.name);
  });

  testWidgets('system back falls back to home when there is no stack',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter();
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );
    await tester.pump();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.popCalls, 0);
    expect(router.replaceAllCalls, 1);
    expect(router.lastReplaceAllRoutes?.single.routeName, TenantHomeRoute.name);
  });

  testWidgets('back button uses pop when the permission route has stack history',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter()..canPopValue = true;
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(router.popCalls, 1);
    expect(router.replaceAllCalls, 0);
  });

  testWidgets('uses emphasized button colors in light and dark themes',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);
    const lightPrimary = Color(0xFF0057D8);
    const darkPrimary = Color(0xFF8AB4FF);

    ThemeData buildTheme(Brightness brightness, Color primary) {
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ),
      );
    }

    Future<void> pumpForTheme(ThemeMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light, lightPrimary),
          darkTheme: buildTheme(Brightness.dark, darkPrimary),
          themeMode: mode,
          home: const LocationPermissionScreen(
            initialState: LocationPermissionState.denied,
          ),
        ),
      );
      await tester.pump();
    }

    await pumpForTheme(ThemeMode.light);
    final lightTheme = Theme.of(
      tester.element(find.byType(LocationPermissionScreen)),
    );
    final lightPrimaryButton =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final lightSecondaryButton =
        tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(
      lightPrimaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      lightTheme.colorScheme.primary,
    );
    expect(
      lightPrimaryButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      lightTheme.colorScheme.onPrimary,
    );
    expect(
      lightSecondaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      lightTheme.colorScheme.surfaceContainerLow,
    );

    await pumpForTheme(ThemeMode.dark);
    final darkTheme = Theme.of(
      tester.element(find.byType(LocationPermissionScreen)),
    );
    final darkPrimaryButton =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final darkSecondaryButton =
        tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(
      darkPrimaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      darkTheme.colorScheme.primary,
    );
    expect(
      darkPrimaryButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      darkTheme.colorScheme.onPrimary,
    );
    expect(
      darkSecondaryButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      darkTheme.colorScheme.surfaceContainerLow,
    );
  });

  testWidgets(
      'back button returns cancelled result without closing when callback owns navigation',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter();
    LocationPermissionGateResult? capturedResult;
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          onResult: (result) => capturedResult = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(capturedResult, LocationPermissionGateResult.cancelled);
    expect(router.popCalls, 0);
    expect(router.replaceAllCalls, 0);
  });

  testWidgets('back button pops the route when guarded flow requests dismissal',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter()..canPopValue = true;
    LocationPermissionGateResult? capturedResult;
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          popRouteAfterResult: true,
          onResult: (result) => capturedResult = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(capturedResult, LocationPermissionGateResult.cancelled);
    expect(router.popCalls, 1);
    expect(router.replaceAllCalls, 0);
  });

  testWidgets(
      'granted result stays owned by guarded callback even when boundary dismissal is enabled',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    final router = _RecordingStackRouter();
    LocationPermissionGateResult? capturedResult;
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          popRouteAfterResult: true,
          onResult: (result) => capturedResult = result,
        ),
      ),
    );
    await tester.pump();

    controller.resultStreamValue.addValue(true);
    await tester.pump();
    await tester.pump();

    expect(capturedResult, LocationPermissionGateResult.granted);
    expect(router.popCalls, 0);
    expect(router.replaceAllCalls, 0);
  });
}

Widget _buildWidget({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: child,
    ),
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {
  int popCalls = 0;
  int replaceAllCalls = 0;
  bool canPopValue = false;
  List<PageRouteInfo>? lastReplaceAllRoutes;

  @override
  RootStackRouter get root => _FakeRootStackRouter();

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopValue;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCalls += 1;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo>? routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalls += 1;
    lastReplaceAllRoutes = routes;
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  @override
  RootStackRouter get root => this;

  @override
  String get currentPath => '/location/permission';

  @override
  Object? get pathState => null;

  @override
  PageRouteInfo? buildPageRoute(
    String? path, {
    bool includePrefixMatches = true,
  }) {
    final uri = Uri.tryParse(path ?? '');
    if (uri == null) {
      return null;
    }

    return switch (uri.path) {
      '/' => const TenantHomeRoute(),
      '/profile' => const ProfileRoute(),
      _ => null,
    };
  }
}
