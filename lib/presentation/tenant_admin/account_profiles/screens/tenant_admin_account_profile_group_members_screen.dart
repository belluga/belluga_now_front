import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_candidate_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_group_members_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> openTenantAdminAccountProfileGroupMembersScreen({
  required BuildContext context,
  required String accountSlug,
  required String accountProfileId,
  required TenantAdminNestedProfileGroup group,
}) {
  final shellRouter = context.innerRouterOf<StackRouter>(
    TenantAdminShellRoute.name,
  );
  return (shellRouter ?? context.router).push<void>(
    TenantAdminAccountProfileGroupMembersRoute(
      accountSlug: accountSlug,
      accountProfileId: accountProfileId,
      groupId: group.id,
    ),
  );
}

class TenantAdminAccountProfileGroupMembersScreen extends StatefulWidget {
  const TenantAdminAccountProfileGroupMembersScreen({
    super.key,
    required this.accountProfileId,
    required this.group,
  });

  final String accountProfileId;
  final TenantAdminNestedProfileGroup group;

  @override
  State<TenantAdminAccountProfileGroupMembersScreen> createState() =>
      _TenantAdminAccountProfileGroupMembersScreenState();
}

class _TenantAdminAccountProfileGroupMembersScreenState
    extends State<TenantAdminAccountProfileGroupMembersScreen> {
  final TenantAdminAccountProfilesController _profilesController = GetIt.I
      .get<TenantAdminAccountProfilesController>();

  Future<void> _openAddMembersPicker(
    TenantAdminGroupMembersPageController pageController,
  ) async {
    if (pageController.stateStreamValue.value.mutationLoading) return;
    final existingIds = pageController.stateStreamValue.value.items
        .map((item) => item.id)
        .toSet();
    final session = _profilesController.createCandidatePickerSession(
      scope: TenantAdminAccountProfileCandidateScope.queryable,
      maxSelections: TenantAdminAccountProfileCandidatePickerController
          .maxGroupMemberSelectionsPerOperation,
      excludeAccountProfileId: widget.accountProfileId,
    );
    try {
      final selected = await showTenantAdminAccountProfileCandidatePicker(
        context: context,
        controller: session,
        title: 'Adicionar perfis',
        emptyMessage: 'Nenhum perfil elegivel encontrado.',
        closeOnSelection: false,
        searchLabelText: 'Buscar perfil',
        doneLabel: 'Adicionar',
      );
      if (!mounted || selected == null) return;
      final pendingAddIds = selected
          .map((entry) => entry.id)
          .where((profileId) => !existingIds.contains(profileId))
          .toList(growable: false);
      if (pendingAddIds.isEmpty) return;
      await pageController.add(pendingAddIds);
    } finally {
      _profilesController.disposeCandidatePickerSession(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TenantAdminGroupMembersPage(
      loadPage: ({cursor, search}) =>
          _profilesController.fetchEditNestedGroupMembersPage(
            accountProfileId: widget.accountProfileId,
            groupId: widget.group.id,
            cursor: cursor,
            search: search,
          ),
      addMembers: (profileIds) async {
        await _profilesController.addEditNestedGroupMembers(
          accountProfileId: widget.accountProfileId,
          groupId: widget.group.id,
          addIds: profileIds,
        );
      },
      removeMembers: (profileIds) async {
        await _profilesController.removeEditNestedGroupMembers(
          accountProfileId: widget.accountProfileId,
          groupId: widget.group.id,
          removeIds: profileIds,
        );
      },
      title: widget.group.label,
      memberKeyPrefix: 'tenantAdminAccountProfileGroupMember_',
      searchFieldKey: const Key('tenantAdminAccountGroupMemberSearch'),
      onAdd: _openAddMembersPicker,
      leading: IconButton(
        tooltip: 'Voltar',
        onPressed: () => unawaited(context.router.maybePop()),
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }
}
