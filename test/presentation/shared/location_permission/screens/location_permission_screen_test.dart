import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

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
}
