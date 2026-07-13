import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets(
    'programming date selector reveals selected date with compact weekday chip',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: const Key('programmingDateViewportHarness'),
                width: 220,
                child: EventProgrammingSection(
                  items: [
                    _buildProgrammingItem(time: '10:00', title: 'Abertura'),
                  ],
                  occurrences: [
                    _buildOccurrence(
                      id: 'occ-1',
                      start: DateTime(2026, 4, 28, 10),
                      programmingCount: 1,
                    ),
                    _buildOccurrence(
                      id: 'occ-2',
                      start: DateTime(2026, 4, 29, 10),
                      programmingCount: 1,
                    ),
                    _buildOccurrence(
                      id: 'occ-3',
                      start: DateTime(2026, 4, 30, 10),
                      isSelected: true,
                      programmingCount: 1,
                    ),
                  ],
                  onOccurrenceTap: (_) {},
                  onLocationTap: (_) {},
                  profileTypeRegistry: null,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final viewportRect = tester.getRect(
        find.byKey(const Key('programmingDateViewportHarness')),
      );
      final selectedRect = tester.getRect(
        find.byKey(const Key('eventDateCard_occ-3')),
      );

      expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
      expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
      expect(selectedRect.height, lessThanOrEqualTo(66.1));
      expect(selectedRect.height, greaterThanOrEqualTo(60));
    },
  );

  testWidgets('programming profile overflow uses e mais X label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventProgrammingSection(
            items: [
              _buildProgrammingItem(
                time: '10:00',
                title: 'Mesa colaborativa',
                linkedProfiles: [
                  _buildLinkedProfile(id: 'profile-1', name: 'Ananda Torres'),
                  _buildLinkedProfile(id: 'profile-2', name: 'DJ Lua'),
                  _buildLinkedProfile(id: 'profile-3', name: 'Coletivo Sol'),
                  _buildLinkedProfile(id: 'profile-4', name: 'Casa Norte'),
                  _buildLinkedProfile(id: 'profile-5', name: 'Atelie Mar'),
                ],
              ),
            ],
            occurrences: [
              _buildOccurrence(
                id: 'occ-1',
                start: DateTime(2026, 4, 28, 10),
                programmingCount: 1,
              ),
            ],
            onOccurrenceTap: (_) {},
            onLocationTap: (_) {},
            profileTypeRegistry: null,
          ),
        ),
      ),
    );

    expect(find.text('e mais 1'), findsOneWidget);
    expect(find.text('+1 perfil'), findsNothing);
  });

  testWidgets('programming item renders explicit end time with as separator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventProgrammingSection(
            items: [
              _buildProgrammingItem(
                time: '10:00',
                endTime: '11:30',
                title: 'Mesa colaborativa',
              ),
            ],
            occurrences: [
              _buildOccurrence(
                id: 'occ-1',
                start: DateTime(2026, 4, 28, 10),
                programmingCount: 1,
              ),
            ],
            onOccurrenceTap: (_) {},
            onLocationTap: (_) {},
            profileTypeRegistry: null,
          ),
        ),
      ),
    );

    expect(find.text('10:00 às 11:30'), findsOneWidget);
    expect(find.text('10:00 - 11:30'), findsNothing);
  });

  testWidgets(
    'timed programming places the time above the title in the card content column',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventProgrammingSection(
              items: [
                _buildProgrammingItem(
                  time: '10:00',
                  title: 'Mesa colaborativa',
                ),
              ],
              occurrences: [
                _buildOccurrence(
                  id: 'occ-1',
                  start: DateTime(2026, 4, 28, 10),
                  programmingCount: 1,
                ),
              ],
              onOccurrenceTap: (_) {},
              onLocationTap: (_) {},
              profileTypeRegistry: null,
            ),
          ),
        ),
      );

      final timeRect = tester.getRect(find.text('10:00'));
      final titleRect = tester.getRect(find.text('Mesa colaborativa'));

      expect(timeRect.top, lessThan(titleRect.top));
      expect(timeRect.left, greaterThanOrEqualTo(titleRect.left - 1));
    },
  );

  testWidgets(
    'untimed programming items render without a synthetic time label or fake hour chip',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventProgrammingSection(
              items: [
                _buildProgrammingItem(time: '', title: 'Mesa colaborativa'),
              ],
              occurrences: [
                _buildOccurrence(
                  id: 'occ-1',
                  start: DateTime(2026, 4, 28, 10),
                  programmingCount: 1,
                ),
              ],
              onOccurrenceTap: (_) {},
              onLocationTap: (_) {},
              profileTypeRegistry: null,
            ),
          ),
        ),
      );

      expect(find.text('Logo após'), findsNothing);
      expect(find.text('10:00'), findsNothing);
      expect(find.text('00:00'), findsNothing);
      expect(find.text('11:30'), findsNothing);
      expect(find.textContaining('às'), findsNothing);
      expect(find.byType(Chip), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
    },
  );

  testWidgets('programming item custom html renders through the safe html path', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventProgrammingSection(
            items: [
              _buildProgrammingItem(
                time: '10:00',
                title:
                    '<strong>Programação</strong><p>Primeira linha</p><p>Segunda linha</p><script>alert(1)</script>',
              ),
            ],
            occurrences: [
              _buildOccurrence(
                id: 'occ-1',
                start: DateTime(2026, 4, 28, 10),
                programmingCount: 1,
              ),
            ],
            onOccurrenceTap: (_) {},
            onLocationTap: (_) {},
            profileTypeRegistry: null,
          ),
        ),
      ),
    );

    final htmlWidget = tester.widget<Html>(find.byType(Html));

    expect(find.byType(Html), findsOneWidget);
    expect(find.text('Programação'), findsOneWidget);
    expect(find.text('Primeira linha'), findsOneWidget);
    expect(find.text('Segunda linha'), findsOneWidget);
    expect(htmlWidget.data, contains('<strong>Programação</strong>'));
    expect(htmlWidget.data, isNot(contains('<script>')));
    expect(find.textContaining('<strong>'), findsNothing);
    expect(find.textContaining('<p>'), findsNothing);
    expect(find.textContaining('<script>'), findsNothing);
  });
}

EventOccurrenceOption _buildOccurrence({
  required String id,
  required DateTime start,
  DateTime? end,
  bool isSelected = false,
  bool hasLocationOverride = false,
  int programmingCount = 0,
  List<EventProgrammingItem> programmingItems = const [],
}) {
  final endValue = DomainOptionalDateTimeValue()..parse(end?.toIso8601String());
  return EventOccurrenceOption(
    occurrenceIdValue: EventLinkedAccountProfileTextValue(id),
    occurrenceSlugValue: EventLinkedAccountProfileTextValue('$id-slug'),
    dateTimeStartValue: DateTimeValue(isRequired: true)
      ..parse(start.toIso8601String()),
    dateTimeEndValue: endValue,
    isSelectedValue: EventOccurrenceFlagValue()..parse(isSelected.toString()),
    hasLocationOverrideValue: EventOccurrenceFlagValue()
      ..parse(hasLocationOverride.toString()),
    programmingCountValue: EventProgrammingCountValue()
      ..parse(programmingCount.toString()),
    programmingItems: programmingItems,
  );
}

EventProgrammingItem _buildProgrammingItem({
  required String time,
  String? endTime,
  String? title,
  List<EventLinkedAccountProfile> linkedProfiles = const [],
  EventLinkedAccountProfile? locationProfile,
}) {
  return EventProgrammingItem(
    timeValue: EventProgrammingTimeValue(time),
    endTimeValue: endTime == null ? null : EventProgrammingTimeValue(endTime),
    titleValue: title == null
        ? null
        : EventLinkedAccountProfileTextValue(title),
    linkedAccountProfiles: linkedProfiles,
    locationProfile: locationProfile,
  );
}

EventLinkedAccountProfile _buildLinkedProfile({
  required String id,
  required String name,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(name),
    profileTypeValue: AccountProfileTypeValue('artist'),
    slugValue: SlugValue()..parse(id),
  );
}
