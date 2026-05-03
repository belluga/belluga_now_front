import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_flag_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_programming_count_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_programming_time_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets(
    'programming selector runtime settles each of nine date taps after 2 seconds',
    (tester) async {
      var selectedOccurrenceId = 'occ-0';
      var currentOccurrenceIndex = 0;

      List<EventOccurrenceOption> buildOccurrences() {
        return List<EventOccurrenceOption>.generate(
          9,
          (index) => _buildOccurrence(
            id: 'occ-$index',
            start: DateTime(2026, 3, 15 + index, 18),
            end: DateTime(2026, 3, 15 + index, 22),
            isSelected: selectedOccurrenceId == 'occ-$index',
            programmingCount: 1,
          ),
          growable: false,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const <Locale>[Locale('pt', 'BR')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EventProgrammingSection(
                  items: <EventProgrammingItem>[
                    EventProgrammingItem(
                      timeValue: EventProgrammingTimeValue('18:00'),
                      titleValue:
                          EventLinkedAccountProfileTextValue('Faixa ativa'),
                      linkedAccountProfiles:
                          <EventLinkedAccountProfile>[],
                      locationProfile: null,
                    ),
                  ],
                  occurrences: buildOccurrences(),
                  onOccurrenceTap: (occurrence) {
                    setState(() {
                      selectedOccurrenceId = occurrence.occurrenceId;
                    });
                  },
                  onLocationTap: (_) {},
                  profileTypeRegistry: null,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final viewportFinder =
          find.byKey(const Key('eventProgrammingDateSelectorViewport'));
      final selectorListFinder =
          find.byKey(const Key('eventProgrammingDateSelectorList'));

      Future<void> selectAndValidate(
        String occurrenceId, {
        required bool expectCentered,
      }) async {
        final cardFinder = find.byKey(Key('eventDateCard_$occurrenceId'));
        final targetIndex = int.parse(occurrenceId.split('-').last);
        final moveStep = targetIndex >= currentOccurrenceIndex
            ? const Offset(-220, 0)
            : const Offset(220, 0);
        await tester.dragUntilVisible(
          cardFinder,
          selectorListFinder,
          moveStep,
          maxIteration: 20,
          continuous: true,
        );
        await tester.tap(cardFinder);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        final viewportRect = tester.getRect(viewportFinder);
        final selectedRect = tester.getRect(cardFinder);
        final centerDelta =
            (selectedRect.center.dx - viewportRect.center.dx).abs();

        expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 1));
        expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 1));

        if (expectCentered) {
          expect(centerDelta, lessThanOrEqualTo(72));
        }

        currentOccurrenceIndex = targetIndex;
      }

      for (var index = 1; index <= 7; index += 1) {
        await selectAndValidate(
          'occ-$index',
          expectCentered: true,
        );
      }

      await selectAndValidate('occ-8', expectCentered: false);
      await selectAndValidate('occ-0', expectCentered: false);
    },
  );
}

EventOccurrenceOption _buildOccurrence({
  required String id,
  required DateTime start,
  DateTime? end,
  bool isSelected = false,
  int programmingCount = 0,
}) {
  final endValue = DomainOptionalDateTimeValue()..parse(end?.toIso8601String());
  return EventOccurrenceOption(
    occurrenceIdValue: EventLinkedAccountProfileTextValue(id),
    occurrenceSlugValue: EventLinkedAccountProfileTextValue('$id-slug'),
    dateTimeStartValue: DateTimeValue(isRequired: true)
      ..parse(start.toIso8601String()),
    dateTimeEndValue: endValue,
    isSelectedValue: EventOccurrenceFlagValue()..parse(isSelected.toString()),
    hasLocationOverrideValue: EventOccurrenceFlagValue()..parse('false'),
    programmingCountValue: EventProgrammingCountValue()
      ..parse(programmingCount.toString()),
    programmingItems: const <EventProgrammingItem>[],
  );
}
