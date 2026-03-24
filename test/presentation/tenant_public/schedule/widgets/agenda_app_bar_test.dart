import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'radius slider updates local value on change and commits on change end',
    (tester) async {
      final controller = _FakeAgendaAppBarController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AgendaAppBar(controller: controller),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.radar));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNotNull);
      expect(slider.onChangeEnd, isNotNull);

      slider.onChanged!(6);
      await tester.pump();

      expect(controller.setRadiusMetersCallCount, 0);
      expect(controller.radiusMetersStreamValue.value, 5000);
      expect(find.text('6 km'), findsOneWidget);

      slider.onChangeEnd!(6);
      await tester.pump();

      expect(controller.setRadiusMetersCallCount, 1);
      expect(controller.radiusMetersStreamValue.value, 6000);
    },
  );
}

class _FakeAgendaAppBarController implements AgendaAppBarController {
  @override
  final StreamValue<bool> searchActiveStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final TextEditingController searchController = TextEditingController();

  @override
  final FocusNode focusNode = FocusNode();

  @override
  double get minRadiusMeters => 1000;

  @override
  final StreamValue<double> maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 10000);

  @override
  final StreamValue<double> radiusMetersStreamValue =
      StreamValue<double>(defaultValue: 5000);

  @override
  final StreamValue<InviteFilter> inviteFilterStreamValue =
      StreamValue<InviteFilter>(defaultValue: InviteFilter.none);

  @override
  final StreamValue<bool> showHistoryStreamValue =
      StreamValue<bool>(defaultValue: false);

  int setRadiusMetersCallCount = 0;

  @override
  void setRadiusMeters(double meters) {
    setRadiusMetersCallCount += 1;
    radiusMetersStreamValue.addValue(meters);
  }

  @override
  void cycleInviteFilter() {}

  @override
  Future<void> searchEvents(String query) async {}

  @override
  void toggleHistory() {}

  @override
  void toggleSearchMode() {}
}
