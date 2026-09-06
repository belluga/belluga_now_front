import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paginates and deduplicates members while exposing search sentinel',
    () async {
      final pages = <Future<TenantAdminNestedGroupMemberPage>>[
        Future.value(_page(['one'], cursor: 'next')),
        Future.value(_page(['one', 'two'])),
      ];
      final cursors = <String?>[];
      final controller = _controller(
        loadPage: ({cursor, search}) {
          cursors.add(cursor);
          return pages.removeAt(0);
        },
      );

      await controller.initialize();
      expect(controller.stateStreamValue.value.searchAvailable, isTrue);
      controller.loadMoreIfNeeded(0);
      await Future<void>.delayed(Duration.zero);

      expect(controller.stateStreamValue.value.items.map((item) => item.id), [
        'one',
        'two',
      ]);
      expect(cursors, [null, 'next']);
      controller.dispose();
    },
  );

  test('a newer search discards an in-flight response', () async {
    final burstLevel =
        int.tryParse(Platform.environment['DELPHI_RACE_BURST_LEVEL'] ?? '') ??
        2;
    final initialGate = Completer<TenantAdminNestedGroupMemberPage>();
    final staleGates = <String, Completer<TenantAdminNestedGroupMemberPage>>{};
    final queries = List<String>.generate(
      burstLevel,
      (index) => 'q${index.toString().padLeft(2, '0')}',
    );
    final searches = <String?>[];
    final controller = _controller(
      loadPage: ({cursor, search}) {
        searches.add(search);
        if (search == null) return initialGate.future;
        if (search == queries.last) return Future.value(_page(['new']));
        return (staleGates[search] ??=
                Completer<TenantAdminNestedGroupMemberPage>())
            .future;
      },
    );

    final initialization = controller.initialize();
    for (final query in queries) {
      controller.updateSearch(query);
      await Future<void>.delayed(Duration.zero);
    }
    initialGate.complete(_page(['old']));
    for (final gate in staleGates.values.toList(growable: false).reversed) {
      gate.complete(_page(['old']));
    }
    await initialization;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(searches, [
      null,
      queries.last,
    ], reason: 'Repeated resets coalesce to the latest queued search.');
    expect(controller.stateStreamValue.value.items.map((item) => item.id), [
      'new',
    ]);
    controller.dispose();
  });

  test('mutation refreshes the first page and reports failures', () async {
    var loadCount = 0;
    var shouldFail = false;
    final controller = _controller(
      loadPage: ({cursor, search}) async {
        loadCount += 1;
        return _page([loadCount == 1 ? 'before' : 'after']);
      },
      removeMembers: (ids) async {
        if (shouldFail) throw StateError('forced failure');
      },
    );

    await controller.initialize();
    await controller.remove('before');
    expect(controller.stateStreamValue.value.items.single.id, 'after');

    shouldFail = true;
    await controller.remove('after');
    expect(
      controller.stateStreamValue.value.errorMessage,
      contains('forced failure'),
    );
    expect(controller.stateStreamValue.value.mutationLoading, isFalse);
    controller.dispose();
  });
}

TenantAdminGroupMembersPageController _controller({
  required TenantAdminGroupMembersPageLoader loadPage,
  TenantAdminGroupMembersMutation? removeMembers,
}) {
  return TenantAdminGroupMembersPageController(
    loadPage: loadPage,
    addMembers: (_) async {},
    removeMembers: removeMembers ?? (_) async {},
    searchDebounce: Duration.zero,
  );
}

TenantAdminNestedGroupMemberPage _page(List<String> ids, {String? cursor}) {
  return TenantAdminNestedGroupMemberPage(
    items: ids
        .map(
          (id) => TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue(id),
            displayNameValue: TenantAdminOptionalTextValue()..parse(id),
          ),
        )
        .toList(growable: false),
    nextCursorValue: TenantAdminOptionalTextValue()..parse(cursor),
  );
}
