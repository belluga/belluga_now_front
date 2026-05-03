import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'expanded radius action grows to show the full 800 km label',
    (tester) async {
      final controller = _FakeAgendaAppBarController()
        ..radiusMetersStreamValue.addValue(800000);

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

      final expandedAction =
          find.byKey(const ValueKey<String>('agenda-radius-expanded'));

      expect(expandedAction, findsOneWidget);
      expect(
        find.descendant(
          of: expandedAction,
          matching: find.byIcon(Icons.place_outlined),
        ),
        findsOneWidget,
      );
      expect(find.text('Até 800 km'), findsOneWidget);

      final expandedRect = tester.getRect(expandedAction);
      expect(expandedRect.width, greaterThan(124));
    },
  );

  testWidgets(
    'compact radius action shows place icon with standalone 50 km badge',
    (tester) async {
      final controller = _FakeAgendaAppBarController()
        ..isRadiusActionCompactStreamValue.addValue(true)
        ..radiusMetersStreamValue.addValue(50000);

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

      expect(find.byKey(const ValueKey<String>('agenda-radius-compact')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-compact-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-compact-badge')),
        findsOneWidget,
      );
      final compactAction =
          find.byKey(const ValueKey<String>('agenda-radius-compact'));
      expect(
        find.descendant(
          of: compactAction,
          matching: find.byIcon(Icons.place_outlined),
        ),
        findsOneWidget,
      );
      expect(find.text('50 km'), findsOneWidget);
      expect(find.text('Até 5 km'), findsNothing);

      final buttonRect = tester.getRect(
        find.byKey(const ValueKey<String>('agenda-radius-compact-button')),
      );
      final iconRect = tester.getRect(
        find.descendant(
          of: compactAction,
          matching: find.byIcon(Icons.place_outlined),
        ),
      );
      final badgeRect = tester.getRect(
        find.byKey(const ValueKey<String>('agenda-radius-compact-badge')),
      );

      expect(buttonRect.width, greaterThanOrEqualTo(68));
      expect(badgeRect.center.dy, greaterThan(iconRect.center.dy));
      expect(badgeRect.width, greaterThanOrEqualTo(46));
    },
  );

  testWidgets(
    'compact radius action opens selector sheet when tapped',
    (tester) async {
      final controller = _FakeAgendaAppBarController()
        ..isRadiusActionCompactStreamValue.addValue(true)
        ..radiusMetersStreamValue.addValue(50000);
      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AgendaAppBar(controller: controller),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('agenda-radius-compact-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('50 km'), findsWidgets);
    },
  );

  testWidgets(
    'invite filter defaults compact and extends labels without extending radius',
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

      expect(
        find.byKey(const ValueKey<String>('agenda-invite-filter-compact')),
        findsOneWidget,
      );
      expect(find.text('Convites'), findsNothing);
      expect(find.text('Confirmados'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-expanded')),
        findsOneWidget,
      );

      controller.inviteFilterStreamValue.addValue(InviteFilter.pendingOnly);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('agenda-invite-filter-expanded')),
        findsOneWidget,
      );
      expect(find.text('Convites'), findsOneWidget);
      expect(find.text('Confirmados'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-compact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-expanded')),
        findsNothing,
      );

      controller.inviteFilterStreamValue.addValue(InviteFilter.confirmedOnly);
      await tester.pumpAndSettle();

      expect(find.text('Convites'), findsNothing);
      expect(find.text('Confirmados'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-compact')),
        findsOneWidget,
      );

      controller.inviteFilterStreamValue.addValue(InviteFilter.none);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('agenda-invite-filter-compact')),
        findsOneWidget,
      );
      expect(find.text('Convites'), findsNothing);
      expect(find.text('Confirmados'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('agenda-radius-expanded')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'invite filter tap cycles compact all through Convites and Confirmados',
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

      await tester.tap(
        find.byKey(const ValueKey<String>('agenda-invite-filter-compact')),
      );
      await tester.pumpAndSettle();

      expect(
          controller.inviteFilterStreamValue.value, InviteFilter.pendingOnly);
      expect(find.text('Convites'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('agenda-invite-filter-expanded')),
      );
      await tester.pumpAndSettle();

      expect(
        controller.inviteFilterStreamValue.value,
        InviteFilter.confirmedOnly,
      );
      expect(find.text('Confirmados'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('agenda-invite-filter-expanded')),
      );
      await tester.pumpAndSettle();

      expect(controller.inviteFilterStreamValue.value, InviteFilter.none);
      expect(
        find.byKey(const ValueKey<String>('agenda-invite-filter-compact')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'radius slider updates local value on change and commits on change end',
    (tester) async {
      final controller = _FakeAgendaAppBarController();
      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AgendaAppBar(controller: controller),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('agenda-radius-expanded')));
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

  testWidgets(
    'renders custom radius sheet presentation when provided',
    (tester) async {
      final controller = _FakeAgendaAppBarController();
      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AgendaAppBar(
                  controller: controller,
                  actions: const AgendaAppBarActions(
                    radiusSheetPresentation: AgendaRadiusSheetPresentation(
                      title: 'Distância Máxima',
                      description:
                          'Mostraremos apenas eventos acontecendo dentro desse raio a partir de sua localização.',
                      helperText:
                          'Você pode alterar essa preferência quando quiser.',
                      confirmButtonLabel: 'Confirmar raio',
                    ),
                  ),
                ),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('agenda-radius-expanded')));
      await tester.pumpAndSettle();

      expect(find.text('Distância Máxima'), findsOneWidget);
      expect(
        find.text(
          'Mostraremos apenas eventos acontecendo dentro desse raio a partir de sua localização.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Você pode alterar essa preferência quando quiser.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confirmar raio'), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(6);
      await tester.pump();

      expect(controller.setRadiusMetersCallCount, 0);

      await tester.ensureVisible(find.text('Confirmar raio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar raio'));
      await tester.pumpAndSettle();

      expect(controller.setRadiusMetersCallCount, 1);
      expect(controller.radiusMetersStreamValue.value, 6000);
    },
  );

  testWidgets(
    'keeps confirm button inside bottom safe area on constrained mobile viewport',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = _FakeAgendaAppBarController();
      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(430, 900),
            padding: EdgeInsets.only(bottom: 32),
            viewPadding: EdgeInsets.only(bottom: 32),
          ),
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: MaterialApp(
              home: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: AgendaAppBar(
                    controller: controller,
                    actions: const AgendaAppBarActions(
                      radiusSheetPresentation: AgendaRadiusSheetPresentation(
                        title: 'Distância Máxima',
                        description:
                            'Mostraremos apenas eventos acontecendo dentro desse raio a partir de sua localização.',
                        helperText:
                            'Você pode alterar essa preferência quando quiser.',
                        confirmButtonLabel: 'Confirmar raio',
                      ),
                    ),
                  ),
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('agenda-radius-expanded')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final buttonRect = tester.getRect(
        find.widgetWithText(FilledButton, 'Confirmar raio'),
      );
      expect(buttonRect.bottom, lessThanOrEqualTo(900 - 32));
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
  final StreamValue<bool> isRadiusRefreshLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  @override
  final StreamValue<bool> isRadiusActionCompactStreamValue =
      StreamValue<bool>(defaultValue: false);

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
  void cycleInviteFilter() {
    switch (inviteFilterStreamValue.value) {
      case InviteFilter.none:
        inviteFilterStreamValue.addValue(InviteFilter.pendingOnly);
        break;
      case InviteFilter.pendingOnly:
        inviteFilterStreamValue.addValue(InviteFilter.confirmedOnly);
        break;
      case InviteFilter.confirmedOnly:
        inviteFilterStreamValue.addValue(InviteFilter.none);
        break;
    }
  }

  @override
  Future<void> searchEvents(String query) async {}

  @override
  void toggleHistory() {}

  @override
  void toggleSearchMode() {}
}

class _RecordingStackRouter extends Fake implements StackRouter {
  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async => true;
}
