import 'dart:async';

import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidate_discovery_page_loader.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'does not search below two graphemes and supersedes stale requests',
    () async {
      final repository = _CandidateRepository();
      final firstGate = Completer<TenantAdminAccountProfileCandidatePage>();
      repository.responsesBySearch['xa'] = firstGate.future;
      repository.responsesBySearch['xap'] = Future.value(
        _candidatePage(items: [_candidate('profile-xapuri', 'Xapuri')]),
      );
      final controller = TenantAdminAccountProfileCandidatePickerController(
        pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
          repository: repository,
        ),
        scope: TenantAdminAccountProfileCandidateScope.queryable,
        maxSelections: 50,
        searchDebounce: Duration.zero,
      );

      controller.updateSearch('x');
      await Future<void>.delayed(Duration.zero);
      expect(repository.searches, isEmpty);

      controller.updateSearch('xa');
      await Future<void>.delayed(Duration.zero);
      expect(repository.searches, ['xa']);

      controller.updateSearch('xap');
      firstGate.complete(
        _candidatePage(items: [_candidate('profile-old', 'Old')]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.searches, ['xa', 'xap']);
      expect(
        controller.candidatesStreamValue.value.single.displayName,
        'Xapuri',
      );
      controller.dispose();
    },
  );

  test(
    'keeps next-page loading single-flight and enforces the selection max',
    () async {
      final repository = _CandidateRepository();
      final nextGate = Completer<TenantAdminAccountProfileCandidatePage>();
      repository.responsesByPage[1] = Future.value(
        _candidatePage(
          items: [_candidate('profile-one', 'One')],
          hasMore: true,
        ),
      );
      repository.responsesByPage[2] = nextGate.future;
      final controller = TenantAdminAccountProfileCandidatePickerController(
        pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
          repository: repository,
        ),
        scope: TenantAdminAccountProfileCandidateScope.contactCapable,
        maxSelections: 1,
        searchDebounce: Duration.zero,
      );

      controller.updateSearch('on');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.toggleSelection(_candidate('profile-one', 'One')),
        isTrue,
      );
      expect(
        controller.toggleSelection(_candidate('profile-two', 'Two')),
        isFalse,
      );

      final first = controller.loadNextPage();
      final second = controller.loadNextPage();
      await Future<void>.delayed(Duration.zero);
      expect(repository.pages, [1, 2]);
      nextGate.complete(
        _candidatePage(items: [_candidate('profile-two', 'Two')]),
      );
      await Future.wait([first, second]);

      expect(
        controller.selectedSummariesStreamValue.value.single.id,
        'profile-one',
      );
      controller.dispose();
    },
  );

  test(
    'ignores a pending search result after the picker session is disposed',
    () async {
      final repository = _CandidateRepository();
      final gate = Completer<TenantAdminAccountProfileCandidatePage>();
      repository.responsesBySearch['xa'] = gate.future;
      final controller = TenantAdminAccountProfileCandidatePickerController(
        pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
          repository: repository,
        ),
        scope: TenantAdminAccountProfileCandidateScope.queryable,
        maxSelections: 50,
        searchDebounce: Duration.zero,
      );

      controller.updateSearch('xa');
      await Future<void>.delayed(Duration.zero);
      expect(repository.searches, ['xa']);

      controller.dispose();
      gate.complete(
        _candidatePage(items: [_candidate('profile-xapuri', 'Xapuri')]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.toggleSelection(_candidate('profile-xapuri', 'Xapuri')),
        isFalse,
      );
    },
  );
}

class _CandidateRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  final List<String> searches = <String>[];
  final List<int> pages = <int>[];
  final Map<String, Future<TenantAdminAccountProfileCandidatePage>>
  responsesBySearch =
      <String, Future<TenantAdminAccountProfileCandidatePage>>{};
  final Map<int, Future<TenantAdminAccountProfileCandidatePage>>
  responsesByPage = <int, Future<TenantAdminAccountProfileCandidatePage>>{};

  @override
  Future<TenantAdminAccountProfileCandidatePage>
  fetchAccountProfileCandidatesPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required TenantAdminAccountProfilesRepoString search,
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) {
    searches.add(search.value);
    pages.add(page.value);
    return responsesByPage[page.value] ??
        responsesBySearch[search.value] ??
        Future.value(_candidatePage());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TenantAdminAccountProfileCandidate _candidate(String id, String displayName) {
  return TenantAdminAccountProfileCandidate(
    idValue: TenantAdminAccountProfileIdValue(id),
    displayNameValue: TenantAdminRequiredTextValue()..parse(displayName),
  );
}

TenantAdminAccountProfileCandidatePage _candidatePage({
  List<TenantAdminAccountProfileCandidate> items =
      const <TenantAdminAccountProfileCandidate>[],
  bool hasMore = false,
}) {
  return TenantAdminAccountProfileCandidatePage(
    items: items,
    pageValue: TenantAdminCountValue(1),
    perPageValue: TenantAdminCountValue(20),
    hasMoreValue: TenantAdminFlagValue(hasMore),
    browseLimitReachedValue: TenantAdminFlagValue(false),
  );
}
