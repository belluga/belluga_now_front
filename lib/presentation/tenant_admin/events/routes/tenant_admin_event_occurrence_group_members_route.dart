import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/application/router/support/route_scoped_resolver_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_occurrence_group_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminEventOccurrenceGroupMembersRoute')
class TenantAdminEventOccurrenceGroupMembersRoutePage
    extends RouteScopedResolverRoute<TenantAdminEvent, TenantAdminModule> {
  const TenantAdminEventOccurrenceGroupMembersRoutePage({
    super.key,
    @PathParam('eventId') required this.eventId,
    @PathParam('occurrenceId') required this.occurrenceId,
    @PathParam('occurrenceKey') required this.occurrenceKey,
    @PathParam('groupId') required this.groupId,
  });

  final String eventId;
  final String occurrenceId;
  final String occurrenceKey;
  final String groupId;

  @override
  RouteResolverParams get resolverParams => {
        'eventId': eventId,
      };

  @override
  Widget buildScreen(BuildContext context, TenantAdminEvent model) {
    return TenantAdminEventOccurrenceGroupMembersScreen(
      key: ValueKey(
        'tenant-admin-event-occurrence-group-members-$eventId-$occurrenceId-$groupId',
      ),
      eventId: eventId,
      occurrenceId: occurrenceId,
      occurrenceKey: occurrenceKey,
      group: _groupForOccurrence(
        event: model,
        occurrenceId: occurrenceId,
        groupId: groupId,
      ),
    );
  }
}

TenantAdminNestedProfileGroup _groupForOccurrence({
  required TenantAdminEvent event,
  required String occurrenceId,
  required String groupId,
}) {
  for (final occurrence in event.occurrences) {
    if (occurrence.occurrenceId != occurrenceId) {
      continue;
    }
    for (final group in occurrence.profileGroups) {
      if (group.id == groupId) {
        return group;
      }
    }
    break;
  }

  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(groupId),
    labelValue: TenantAdminNestedProfileGroupTextValue('Grupo'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(),
  );
}
