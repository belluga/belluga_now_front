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
