import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_timeline_rail_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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
                  onProfileTap: (_) {},
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
    'programming profile chips act only on their canonical public-detail path',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final profiles = <AccountProfileSummary>[
        _buildLinkedProfile(
          id: 'profile-1',
          name: 'Ananda Torres',
          slug: 'unrelated-ananda-slug',
          publicDetailPath: '/perfil/caminho-produtor-ananda',
        ),
        _buildLinkedProfile(
          id: 'profile-2',
          name: 'DJ Lua',
          slug: 'unrelated-dj-slug',
          publicDetailPath: '/perfil/caminho-produtor-dj',
        ),
        _buildLinkedProfile(
          id: 'profile-3',
          name: 'Coletivo Sol',
          slug: 'unrelated-coletivo-slug',
          canOpenPublicDetail: false,
          publicDetailPath: '/perfil/raw-ineligible-nao-usar',
        ),
        _buildLinkedProfile(id: 'profile-4', name: 'Casa Norte'),
        _buildLinkedProfile(id: 'profile-5', name: 'Atelie Mar'),
      ];
      final tappedProfiles = <AccountProfileSummary>[];
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
              onProfileTap: tappedProfiles.add,
              onLocationTap: (_) {},
              profileTypeRegistry: null,
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tappedProfiles, [profiles.first]);

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
        final isEligible = profile.publicDetailUrl != null;
        final actionLabel = 'Abrir perfil de ${profile.displayName}';
        final action = find.ancestor(
          of: target,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == actionLabel,
          ),
        );
        expect(
          find.ancestor(of: target, matching: find.byType(InkWell)),
          isEligible ? findsOneWidget : findsNothing,
        );
        if (isEligible) {
          expect(action, findsOneWidget);
          final actionNode = tester.getSemantics(action);
          expect(actionNode.flagsCollection.isButton, isTrue);
          expect(actionNode.label, actionLabel);
          expect(
            actionNode.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          await tester.tap(target);
          await tester.pump();
          expect(tappedProfiles, contains(profile));
        } else {
          expect(action, findsNothing);
          final inertNode = tester.getSemantics(target);
          expect(inertNode.flagsCollection.isButton, isFalse);
          expect(
            inertNode.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
          await tester.tap(target, warnIfMissed: false);
          await tester.pump();
          expect(tappedProfiles, isNot(contains(profile)));
        }
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
      semantics.dispose();
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
            onProfileTap: (_) {},
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
            onProfileTap: (_) {},
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
              onProfileTap: (_) {},
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
              onProfileTap: (_) {},
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
            onProfileTap: (_) {},
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
    occurrenceIdValue: AccountProfileTextValue(id),
    occurrenceSlugValue: AccountProfileTextValue('$id-slug'),
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
  List<AccountProfileSummary> linkedProfiles = const [],
  AccountProfileSummary? locationProfile,
}) {
  return EventProgrammingItem(
    timeValue: EventProgrammingTimeValue(time),
    endTimeValue: endTime == null ? null : EventProgrammingTimeValue(endTime),
    titleValue: title == null ? null : AccountProfileTextValue(title),
    linkedAccountProfiles: linkedProfiles,
    locationProfile: locationProfile,
  );
}

AccountProfileSummary _buildLinkedProfile({
  required String id,
  required String name,
  String? slug,
  bool canOpenPublicDetail = true,
  String? publicDetailPath,
}) {
  return AccountProfileSummary(
    idValue: AccountProfileTextValue(id),
    nameValue: AccountProfileNameValue()..parse(name),
    profileTypeValue: AccountProfileTypeValue('artist'),
    slugValue: SlugValue()..parse(slug ?? id),
    canOpenPublicDetailValue: DomainBooleanValue(
      defaultValue: false,
      isRequired: false,
    )..parse(canOpenPublicDetail.toString()),
    publicDetailPathValue: publicDetailPath == null
        ? null
        : AccountProfilePublicDetailPathValue(publicDetailPath),
  );
}
