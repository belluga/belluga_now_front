import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_group_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminAccountProfileGroupMembersRoute')
class TenantAdminAccountProfileGroupMembersRoutePage
    extends ResolverRoute<TenantAdminAccountProfile, TenantAdminModule> {
  const TenantAdminAccountProfileGroupMembersRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
    @PathParam('accountProfileId') required this.accountProfileId,
    @PathParam('groupId') required this.groupId,
  });

  final String accountSlug;
  final String accountProfileId;
  final String groupId;

  @override
  RouteResolverParams get resolverParams => {
        'accountSlug': accountSlug,
        'accountProfileId': accountProfileId,
      };

  @override
  Widget buildScreen(BuildContext context, TenantAdminAccountProfile model) {
    return TenantAdminAccountProfileGroupMembersScreen(
      key: ValueKey(
        'tenant-admin-account-profile-group-members-$accountProfileId-$groupId',
      ),
      accountProfileId: model.id,
      group: _groupById(
        groups: model.nestedProfileGroups,
        groupId: groupId,
      ),
    );
  }
}

TenantAdminNestedProfileGroup _groupById({
  required List<TenantAdminNestedProfileGroup> groups,
  required String groupId,
}) {
  for (final group in groups) {
    if (group.id == groupId) {
      return group;
    }
  }

  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(groupId),
    labelValue: TenantAdminNestedProfileGroupTextValue('Grupo'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(),
  );
}
