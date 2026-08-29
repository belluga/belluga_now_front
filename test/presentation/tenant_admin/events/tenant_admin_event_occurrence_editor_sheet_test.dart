import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_label_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/widgets/tenant_admin_event_occurrence_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'persisted occurrence group edits inline with scoped authoritative save',
    (tester) async {
      final repository = _EventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: repository,
        taxonomiesRepository: _TaxonomiesRepository(),
      );
      controller.initEventForm(existingEvent: _event());
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      unawaited(
        showTenantAdminEventOccurrenceEditorSheet(
          context: tester.element(find.byType(Scaffold)),
          controller: controller,
          occurrenceKey: controller.occurrenceKeyAt(0)!,
          title: 'Occurrence',
          eventId: 'event-1',
          venues: const [],
          pickDateTime:
              ({
                required initialDateTime,
                required firstDate,
                required lastDate,
              }) async => null,
          pickRelatedAccountProfile: ({required excludedProfileIds}) async =>
              null,
          closeModalSheet: <T>(BuildContext context, [T? result]) async => true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Artists'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(
        find.byKey(const Key('OccurrenceProfileProfileGroupLabel_artists')),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Server label');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(repository.eventId, 'event-1');
      expect(repository.occurrenceId, 'occurrence-1');
      expect(repository.groupId, 'artists');
      expect(find.text('Authoritative label'), findsOneWidget);
      controller.dispose();
    },
  );
}

TenantAdminEvent _event() => TenantAdminEvent(
  eventIdValue: tenantAdminRequiredText('event-1'),
  slugValue: tenantAdminRequiredText('event-1'),
  titleValue: tenantAdminRequiredText('Event'),
  contentValue: tenantAdminOptionalText('Content'),
  type: TenantAdminEventType(
    nameValue: tenantAdminRequiredText('Show'),
    slugValue: tenantAdminRequiredText('show'),
  ),
  occurrences: [
    TenantAdminEventOccurrence(
      occurrenceIdValue: tenantAdminOptionalText('occurrence-1'),
      dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 6, 1)),
      profileGroups: [
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('artists'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          memberCountValue: TenantAdminCountValue(0),
        ),
      ],
    ),
  ],
  publication: TenantAdminEventPublication(
    statusValue: tenantAdminRequiredText('draft'),
  ),
);

class _EventsRepository extends TenantAdminEventsRepositoryContract {
  String? eventId;
  String? occurrenceId;
  String? groupId;
  @override
  Future<TenantAdminNestedGroupLabelMutationResult>
  patchOccurrenceProfileGroupLabel({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventsRepoString occurrenceId,
    required TenantAdminEventsRepoString groupId,
    required TenantAdminEventsRepoString label,
  }) async {
    this.eventId = eventId.value;
    this.occurrenceId = occurrenceId.value;
    this.groupId = groupId.value;
    return TenantAdminNestedGroupLabelMutationResult(
      idValue: TenantAdminNestedProfileGroupTextValue(groupId.value),
      labelValue: TenantAdminNestedProfileGroupTextValue('Authoritative label'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TaxonomiesRepository extends TenantAdminTaxonomiesRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
