import 'dart:async';

import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidate_discovery_page_loader.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_candidate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/auto_route_test_harness.dart';

void main() {
  testWidgets(
    'opens before loading completes and explains a terminal browse limit',
    (tester) async {
      final response = Completer<TenantAdminAccountProfileCandidatePage>();
      final controller = TenantAdminAccountProfileCandidatePickerController(
        pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
          repository: _CandidateRepository(response.future),
        ),
        scope: TenantAdminAccountProfileCandidateScope.queryable,
        maxSelections: null,
        searchDebounce: Duration.zero,
      );
      addTearDown(controller.dispose);

      await pumpAutoRouteTestApp(
        tester,
        routeName: 'tenant-admin-account-profile-candidate-picker-test',
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showTenantAdminAccountProfileCandidatePicker(
                  context: context,
                  controller: controller,
                  title: 'Adicionar perfil',
                  emptyMessage: 'Nenhum perfil elegível.',
                  closeOnSelection: true,
                );
              },
              child: const Text('Abrir seletor'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir seletor'));
      await tester.pump();

      expect(
        find.byKey(const Key('tenantAdminAccountProfileCandidatePickerSheet')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      response.complete(
        TenantAdminAccountProfileCandidatePage(
          items: [_candidate('profile-xapuri', 'Xapuri')],
          pageValue: TenantAdminCountValue(50),
          perPageValue: TenantAdminCountValue(20),
          hasMoreValue: TenantAdminFlagValue(false),
          browseLimitReachedValue: TenantAdminFlagValue(true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('tenantAdminAccountProfileCandidateBrowseLimitHint'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Refine a busca'), findsOneWidget);
    },
  );
}

final class _CandidateRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  _CandidateRepository(this.response);

  final Future<TenantAdminAccountProfileCandidatePage> response;

  @override
  Future<TenantAdminAccountProfileCandidatePage>
  fetchAccountProfileCandidatesPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required TenantAdminAccountProfilesRepoString search,
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TenantAdminAccountProfileCandidate _candidate(String id, String displayName) {
  return TenantAdminAccountProfileCandidate(
    idValue: TenantAdminAccountProfileIdValue(id),
    displayNameValue: TenantAdminRequiredTextValue()..parse(displayName),
  );
}
