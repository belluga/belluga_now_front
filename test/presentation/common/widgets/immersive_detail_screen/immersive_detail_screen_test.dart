import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'tab tap keeps the target section start visible with taller collapsed app bar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImmersiveDetailScreen(
            title: 'Profile',
            collapsedToolbarHeight: 72,
            heroContent: Container(color: Colors.black),
            tabs: [
              ImmersiveTabItem(
                title: 'Sobre',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const Key('sectionOneStart'),
                      padding: const EdgeInsets.all(16),
                      child: const Text('Section 1 Start'),
                    ),
                    Container(height: 900, color: Colors.red),
                  ],
                ),
              ),
              ImmersiveTabItem(
                title: 'Agenda',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const Key('sectionTwoStart'),
                      padding: const EdgeInsets.all(16),
                      child: const Text('Section 2 Start'),
                    ),
                    Container(height: 600, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final tabBottom = tester
          .getBottomLeft(find.byKey(const Key('immersiveTabSelected_1')))
          .dy;
      final sectionStartTop =
          tester.getTopLeft(find.byKey(const Key('sectionTwoStart'))).dy;

      expect(sectionStartTop, greaterThanOrEqualTo(tabBottom - 1));
      expect(sectionStartTop, lessThanOrEqualTo(tabBottom + 8));
    },
  );

  testWidgets(
    'returning to first tab resets immersive scroll to the real top',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImmersiveDetailScreen(
            title: 'Event',
            collapsedToolbarHeight: 72,
            heroContent: Stack(
              children: [
                Container(color: Colors.black),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    key: const Key('heroTopMarker'),
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            tabs: [
              ImmersiveTabItem(
                title: 'Sobre',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const Key('firstSectionStart'),
                      padding: const EdgeInsets.all(16),
                      child: const Text('First Section'),
                    ),
                    Container(height: 900, color: Colors.red),
                  ],
                ),
              ),
              ImmersiveTabItem(
                title: 'Artists',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const Key('secondSectionStart'),
                      padding: const EdgeInsets.all(16),
                      child: const Text('Second Section'),
                    ),
                    Container(height: 900, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      final heroTop =
          tester.getTopLeft(find.byKey(const Key('heroTopMarker'))).dy;

      expect(heroTop, greaterThanOrEqualTo(0));
      expect(heroTop, lessThanOrEqualTo(24));
    },
  );
}
