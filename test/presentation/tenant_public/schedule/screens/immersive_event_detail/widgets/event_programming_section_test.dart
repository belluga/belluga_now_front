import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_timeline_rail_painter.dart';
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

  testWidgets(
    'programming wraps every linked profile as a complete labeled passive chip',
    (tester) async {
      final profiles = <EventLinkedAccountProfile>[
        _buildLinkedProfile(id: 'profile-1', name: 'Ananda Torres'),
        _buildLinkedProfile(id: 'profile-2', name: 'DJ Lua'),
        _buildLinkedProfile(id: 'profile-3', name: 'Coletivo Sol'),
        _buildLinkedProfile(id: 'profile-4', name: 'Casa Norte'),
        _buildLinkedProfile(id: 'profile-5', name: 'Atelie Mar'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventProgrammingSection(
              items: [
                _buildProgrammingItem(
                  time: '10:00',
                  title: 'Mesa colaborativa',
                  linkedProfiles: profiles,
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

      for (final profile in profiles) {
        final target = find.byKey(Key('eventProgrammingProfile_${profile.id}'));
        expect(target, findsOneWidget);
        expect(
          find.descendant(of: target, matching: find.text(profile.displayName)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: target,
            matching: find.byKey(
              Key('eventProgrammingProfileAvatar_${profile.id}'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: target, matching: find.byType(GestureDetector)),
          findsNothing,
        );
      }
      expect(
        find.byKey(const Key('eventProgrammingProfiles_0')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Wrap>(find.byKey(const Key('eventProgrammingProfiles_0')))
            .children,
        hasLength(5),
      );
      expect(find.textContaining('e mais'), findsNothing);
    },
  );

  testWidgets('programming single profile keeps its labeled passive chip', (
    tester,
  ) async {
    final profile = _buildLinkedProfile(id: 'profile-1', name: 'Ananda Torres');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventProgrammingSection(
            items: [
              _buildProgrammingItem(
                time: '10:00',
                title: 'Mesa colaborativa',
                linkedProfiles: [profile],
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

    final target = find.byKey(const Key('eventProgrammingProfile_profile-1'));
    expect(target, findsOneWidget);
    expect(find.text('Ananda Torres'), findsOneWidget);

    await tester.tap(target);
    await tester.pump();

    expect(
      find.descendant(of: target, matching: find.byType(GestureDetector)),
      findsNothing,
    );
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
    'programming paints one external bounded rail and leaves no time reserve for untimed content',
    (tester) async {
      final profile = _buildLinkedProfile(
        id: 'profile-untimed',
        name: 'Pessoa sem horário',
      );
      final location = _buildLinkedProfile(
        id: 'location-untimed',
        name: 'Local sem horário',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventProgrammingSection(
              items: [
                _buildProgrammingItem(time: '10:00', title: 'Com horário'),
                _buildProgrammingItem(time: '', title: 'Sem horário'),
                _buildProgrammingItem(time: '', linkedProfiles: [profile]),
                _buildProgrammingItem(time: '', locationProfile: location),
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
      final timedTitleRect = tester.getRect(find.text('Com horário'));
      final untimedTitleRect = tester.getRect(find.text('Sem horário'));
      final timedCardRect = tester.getRect(
        find.byKey(const Key('eventProgrammingItem_0')),
      );
      final untimedCardRect = tester.getRect(
        find.byKey(const Key('eventProgrammingItem_1')),
      );
      final profilesOnlyCardRect = tester.getRect(
        find.byKey(const Key('eventProgrammingItem_2')),
      );
      final locationOnlyCardRect = tester.getRect(
        find.byKey(const Key('eventProgrammingItem_3')),
      );
      final profilesOnlyRect = tester.getRect(
        find.byKey(const Key('eventProgrammingProfile_profile-untimed')),
      );
      final locationOnlyRect = tester.getRect(
        find.byKey(const Key('eventProgrammingLocation_location-untimed')),
      );
      final railFinder = find.byKey(const Key('eventProgrammingTimelineRail'));
      final rail = tester.widget<CustomPaint>(railFinder);
      final painter = rail.painter! as EventProgrammingTimelineRailPainter;
      final endpoints = painter.debugEndpoints();
      final timelineOrigin = tester.getTopLeft(railFinder);
      expect(painter.markerKeys, hasLength(4));
      final firstMarkerRect = tester.getRect(
        find.byKey(painter.markerKeys.first),
      );
      final lastMarkerRect = tester.getRect(
        find.byKey(painter.markerKeys.last),
      );

      expect(timedCardRect.contains(timeRect.center), isTrue);
      expect(
        timeRect.top - timedCardRect.top,
        lessThanOrEqualTo(20),
        reason: 'The time belongs in the card top content, not a lower gutter.',
      );
      expect(timeRect.top, lessThan(timedTitleRect.top));
      expect(
        timeRect.left - timedCardRect.left,
        lessThanOrEqualTo(20),
        reason:
            'The time must share normal card-content padding with the title.',
      );
      expect(
        timedTitleRect.left - timedCardRect.left,
        lessThanOrEqualTo(20),
        reason: 'The title cannot be shifted right by a time column.',
      );
      expect(
        untimedTitleRect.top - untimedCardRect.top,
        lessThanOrEqualTo(20),
        reason:
            'A title-only untimed card must begin at normal card padding, not below a hidden time slot.',
      );
      expect(
        profilesOnlyRect.top - profilesOnlyCardRect.top,
        lessThanOrEqualTo(20),
      );
      expect(
        locationOnlyRect.top - locationOnlyCardRect.top,
        lessThanOrEqualTo(20),
      );
      expect(firstMarkerRect.right, lessThan(timedCardRect.left));
      expect(firstMarkerRect.right, lessThan(untimedCardRect.left));
      expect(railFinder, findsOneWidget);
      expect(endpoints, isNotNull);
      expect(
        endpoints!.start.dy,
        closeTo(firstMarkerRect.center.dy - timelineOrigin.dy, 0.5),
        reason: 'The list rail cannot continue above the first marker.',
      );
      expect(
        endpoints.end.dy,
        closeTo(lastMarkerRect.center.dy - timelineOrigin.dy, 0.5),
        reason: 'The list rail cannot continue below the last marker.',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('eventProgrammingItem_0')),
          matching: railFinder,
        ),
        findsNothing,
      );
      expect(
        find.byKey(const Key('eventProgrammingTimelineRail_0')),
        findsNothing,
      );
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
