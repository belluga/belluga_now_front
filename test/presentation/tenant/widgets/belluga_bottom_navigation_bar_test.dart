import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bottom nav shows Perfil label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BellugaBottomNavigationBar(currentIndex: 2),
        ),
      ),
    );

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Menu'), findsNothing);
  });
}
