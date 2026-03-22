import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_not_live_screen/location_not_live_screen.dart';
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

  testWidgets('not-live deniedForever shows unblock instructions',
      (tester) async {
    final controller = LocationPermissionController(isWeb: false);
    GetIt.I.registerSingleton<LocationPermissionController>(controller);

    await tester.pumpWidget(
      const MaterialApp(
        home: LocationNotLiveScreen(
          blockerState: LocationPermissionState.deniedForever,
          addressLabel: null,
          capturedAt: null,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Como liberar:'), findsOneWidget);
    expect(find.text('1. Toque em Abrir configurações.'), findsOneWidget);
    expect(find.text('Abrir configurações'), findsOneWidget);
  });
}
