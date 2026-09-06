import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_group_members_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> openTenantAdminEventOccurrenceGroupMembersScreen({
  required BuildContext context,
  required String eventId,
  required String occurrenceId,
  required String occurrenceKey,
  required TenantAdminNestedProfileGroup group,
}) {
  final shellRouter = context.innerRouterOf<StackRouter>(
    TenantAdminShellRoute.name,
  );
  return (shellRouter ?? context.router).push<void>(
    TenantAdminEventOccurrenceGroupMembersRoute(
      eventId: eventId,
      occurrenceId: occurrenceId,
      occurrenceKey: occurrenceKey,
      groupId: group.id,
    ),
  );
}

class TenantAdminEventOccurrenceGroupMembersScreen extends StatefulWidget {
  const TenantAdminEventOccurrenceGroupMembersScreen({
    super.key,
    required this.eventId,
    required this.occurrenceId,
    required this.occurrenceKey,
    required this.group,
  });

  final String eventId;
  final String occurrenceId;
  final String occurrenceKey;
  final TenantAdminNestedProfileGroup group;

  @override
  State<TenantAdminEventOccurrenceGroupMembersScreen> createState() =>
      _TenantAdminEventOccurrenceGroupMembersScreenState();
}

class _TenantAdminEventOccurrenceGroupMembersScreenState
    extends State<TenantAdminEventOccurrenceGroupMembersScreen> {
  final TenantAdminEventsController _eventsController = GetIt.I
      .get<TenantAdminEventsController>();

  Future<void> _openAddMembersPicker(
    TenantAdminGroupMembersPageController pageController,
  ) async {
    if (pageController.stateStreamValue.value.mutationLoading) return;
    await _eventsController.prepareRelatedAccountProfilePicker();
    if (!mounted) return;

    final pendingAddIds = <String>{};
    final existingIds = pageController.stateStreamValue.value.items
        .map((item) => item.id)
        .toSet();
    await showTenantAdminAccountProfileMultiPicker(
      context: context,
      candidatesStreamValue:
          _eventsController.relatedAccountProfileCandidatesStreamValue,
      isLoadingStreamValue:
          _eventsController.relatedAccountProfileSearchLoadingStreamValue,
      isPageLoadingStreamValue:
          _eventsController.relatedAccountProfileSearchPageLoadingStreamValue,
      hasMoreStreamValue:
          _eventsController.relatedAccountProfileSearchHasMoreStreamValue,
      loadNextPage: _eventsController
          .loadNextRelatedAccountProfileCandidatesForNestedGroups,
      onSearchChanged: (query) => unawaited(
        _eventsController.searchRelatedAccountProfileCandidatesForNestedGroups(
          query,
        ),
      ),
      profileTypes:
          _eventsController.relatedAccountProfileTypesStreamValue.value,
      title: 'Adicionar perfis',
      emptyMessage: 'Nenhum perfil elegível encontrado.',
      selectedProfileIds: pendingAddIds,
      selectedProfileType:
          _eventsController.relatedAccountProfileSelectedTypeStreamValue.value,
      onProfileTypeChanged:
          _eventsController.filterRelatedAccountProfileCandidatesByProfileType,
      onSelectionChanged: (profileId, selected) {
        if (existingIds.contains(profileId)) return;
        selected
            ? pendingAddIds.add(profileId)
            : pendingAddIds.remove(profileId);
      },
      searchLabelText: 'Buscar perfil',
      doneLabel: 'Adicionar',
    );
    if (!mounted || pendingAddIds.isEmpty) return;
    await pageController.add(pendingAddIds.toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    return TenantAdminGroupMembersPage(
      loadPage: ({cursor, search}) =>
          _eventsController.fetchOccurrenceProfileGroupMembersPage(
            eventId: widget.eventId,
            occurrenceId: widget.occurrenceId,
            groupId: widget.group.id,
            cursor: cursor,
            search: search,
          ),
      addMembers: (profileIds) async {
        await _eventsController.addOccurrenceProfileGroupMembers(
          eventId: widget.eventId,
          occurrenceId: widget.occurrenceId,
          occurrenceKey: widget.occurrenceKey,
          groupId: widget.group.id,
          addIds: profileIds,
        );
      },
      removeMembers: (profileIds) async {
        await _eventsController.removeOccurrenceProfileGroupMembers(
          eventId: widget.eventId,
          occurrenceId: widget.occurrenceId,
          occurrenceKey: widget.occurrenceKey,
          groupId: widget.group.id,
          removeIds: profileIds,
        );
      },
      title: widget.group.label,
      memberKeyPrefix: 'tenantAdminEventGroupMember_${widget.group.id}_',
      searchFieldKey: const Key('tenantAdminEventGroupMemberSearch'),
      onAdd: _openAddMembersPicker,
    );
  }
}
