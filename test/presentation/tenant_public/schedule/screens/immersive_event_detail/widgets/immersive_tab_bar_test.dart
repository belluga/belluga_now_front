import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/immersive_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'selected horizontal tab is revealed fully inside the viewport',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: const Key('tabViewportHarness'),
                width: 240,
                child: ImmersiveTabBar(
                  tabs: const [
                    'Sobre',
                    'Programação',
                    'Artistas',
                    'Gastronomia',
                    'Como Chegar',
                  ],
                  selectedIndex: 4,
                  onTabTapped: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final viewportRect =
          tester.getRect(find.byKey(const Key('tabViewportHarness')));
      final selectedRect =
          tester.getRect(find.byKey(const Key('immersiveTabSelected_4')));

      expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
      expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
    },
  );
}
