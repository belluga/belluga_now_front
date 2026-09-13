import 'dart:async';

import 'package:belluga_now/application/tenant_admin/events/tenant_admin_event_occurrence_group_members_page_loader.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_occurrence_related_profile_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paginates one group, excludes selected ids, and deduplicates rows',
    () async {
      final repository = _EventsRepository()
        ..responses.addAll([
          Future.value(_page(['excluded', 'one'], cursor: 'next')),
          Future.value(_page(['one', 'two'])),
        ]);
      final controller = _controller(repository);

      await controller.initialize();
      expect(controller.searchAvailableStreamValue.value, isTrue);
      expect(controller.itemsStreamValue.value.map((item) => item.id), ['one']);

      await controller.loadNextPage();
      expect(controller.itemsStreamValue.value.map((item) => item.id), [
        'one',
        'two',
      ]);
      expect(repository.cursors, [null, 'next']);
      controller.dispose();
    },
  );

  test('a newer search supersedes an in-flight response', () async {
    final repository = _EventsRepository();
    final initialGate = Completer<TenantAdminNestedGroupMemberPage>();
    repository.responses.add(initialGate.future);
    final controller = _controller(repository);

    final initialization = controller.initialize();
    controller.updateSearch('sil');
    await Future<void>.delayed(Duration.zero);
    initialGate.complete(_page(['old']));
    await initialization;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.searches, [null, 'sil']);
    expect(controller.itemsStreamValue.value.map((item) => item.id), ['sil']);
    controller.dispose();
  });

  test('does not request a one-grapheme search', () async {
    final repository = _EventsRepository();
    final controller = _controller(repository);
    await controller.initialize();

    controller.updateSearch('x');
    await Future<void>.delayed(Duration.zero);

    expect(repository.searches, [null]);
    expect(controller.itemsStreamValue.value, isEmpty);
    controller.dispose();
  });

  test(
    'a one-grapheme query clears visible loading and a later valid query recovers after a stale search',
    () async {
      final repository = _EventsRepository();
      final firstGate = Completer<TenantAdminNestedGroupMemberPage>();
      final secondGate = Completer<TenantAdminNestedGroupMemberPage>();
      repository.responses.addAll([
        Future.value(_page(['browse'])),
        firstGate.future,
        secondGate.future,
      ]);
      final controller = _controller(repository);

      await controller.initialize();
      controller.updateSearch('first');
      await Future<void>.delayed(Duration.zero);

      expect(repository.searches, [null, 'first']);
      expect(controller.isLoadingStreamValue.value, isTrue);

      controller.updateSearch('x');

      expect(controller.itemsStreamValue.value, isEmpty);
      expect(controller.hasMoreStreamValue.value, isFalse);
      expect(controller.isLoadingStreamValue.value, isFalse);
      expect(controller.isPageLoadingStreamValue.value, isFalse);

      controller.updateSearch('second');
      await Future<void>.delayed(Duration.zero);

      expect(repository.searches, [null, 'first']);

      firstGate.complete(_page(['stale']));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.searches, [null, 'first', 'second']);
      expect(controller.itemsStreamValue.value, isEmpty);

      secondGate.complete(_page(['second']));
      await Future<void>.delayed(Duration.zero);

      expect(controller.itemsStreamValue.value.map((item) => item.id), [
        'second',
      ]);
      expect(controller.isLoadingStreamValue.value, isFalse);
      expect(controller.isPageLoadingStreamValue.value, isFalse);
      controller.dispose();
    },
  );

  test(
    'a one-grapheme query clears a queued search while pagination is pending',
    () async {
      final repository = _EventsRepository();
      final paginationGate = Completer<TenantAdminNestedGroupMemberPage>();
      repository.responses.addAll([
        Future.value(_page(['browse'], cursor: 'next')),
        paginationGate.future,
      ]);
      final controller = _controller(repository);

      await controller.initialize();
      final pagination = controller.loadNextPage();

      expect(controller.isPageLoadingStreamValue.value, isTrue);

      controller.updateSearch('valid');
      await Future<void>.delayed(Duration.zero);
      controller.updateSearch('x');

      expect(controller.itemsStreamValue.value, isEmpty);
      expect(controller.isPageLoadingStreamValue.value, isFalse);

      paginationGate.complete(_page(['stale']));
      await pagination;

      expect(repository.searches, [null, null]);
      expect(controller.itemsStreamValue.value, isEmpty);
      expect(controller.isLoadingStreamValue.value, isFalse);
      expect(controller.isPageLoadingStreamValue.value, isFalse);
      controller.dispose();
    },
  );
}

TenantAdminOccurrenceRelatedProfilePickerController _controller(
  _EventsRepository repository,
) {
  return TenantAdminOccurrenceRelatedProfilePickerController(
    pageLoader: TenantAdminEventOccurrenceGroupMembersPageLoader(
      eventsRepository: repository,
    ),
    eventId: 'event-1',
    occurrenceId: 'occurrence-1',
    groups: [_group('group-1')],
    excludedProfileIds: const {'excluded'},
    searchDebounce: Duration.zero,
  );
}

class _EventsRepository extends TenantAdminEventsRepositoryContract {
  final List<Future<TenantAdminNestedGroupMemberPage>> responses = [];
  final List<String?> searches = [];
  final List<String?> cursors = [];

  @override
  Future<TenantAdminNestedGroupMemberPage>
  fetchOccurrenceProfileGroupMembersPage({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventsRepoString occurrenceId,
    required TenantAdminEventsRepoString groupId,
    TenantAdminEventsRepoString? cursor,
    TenantAdminEventsRepoString? search,
  }) {
    searches.add(search?.value);
    cursors.add(cursor?.value);
    if (responses.isNotEmpty) return responses.removeAt(0);
    return Future.value(_page([search?.value ?? 'initial']));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TenantAdminNestedProfileGroup _group(String id) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(id),
    labelValue: TenantAdminNestedProfileGroupTextValue('Group'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
  );
}

TenantAdminNestedGroupMemberPage _page(List<String> ids, {String? cursor}) {
  final cursorValue = TenantAdminOptionalTextValue()..parse(cursor);
  return TenantAdminNestedGroupMemberPage(
    items: ids
        .map(
          (id) => TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue(id),
            displayNameValue: TenantAdminOptionalTextValue()..parse(id),
          ),
        )
        .toList(growable: false),
    nextCursorValue: cursorValue,
  );
}
