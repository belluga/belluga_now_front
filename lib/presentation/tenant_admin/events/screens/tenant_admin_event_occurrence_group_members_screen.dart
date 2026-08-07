import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> openTenantAdminEventOccurrenceGroupMembersScreen({
  required BuildContext context,
  required String eventId,
  required String occurrenceId,
  required String occurrenceKey,
  required TenantAdminNestedProfileGroup group,
}) {
  final shellRouter =
      context.innerRouterOf<StackRouter>(TenantAdminShellRoute.name);
  final navigationRouter = shellRouter ?? context.router;
  return navigationRouter.push<void>(
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
  final TenantAdminEventsController _controller = GetIt.I
      .get<TenantAdminEventsController>();

  List<TenantAdminAccountProfileSelectionSummary> _items =
      const <TenantAdminAccountProfileSelectionSummary>[];
  String? _nextCursor;
  String? _errorMessage;
  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _mutationLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFirstPage());
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await _controller.fetchOccurrenceProfileGroupMembersPage(
        eventId: widget.eventId,
        occurrenceId: widget.occurrenceId,
        groupId: widget.group.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
        _initialLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _initialLoading = false;
      });
    }
  }

  void _loadMoreIfNeeded({required double extentAfter}) {
    if (extentAfter > 200 ||
        _pageLoading ||
        _initialLoading ||
        _mutationLoading) {
      return;
    }
    final cursor = _nextCursor?.trim();
    if (cursor == null || cursor.isEmpty) {
      return;
    }
    unawaited(_loadNextPage(cursor));
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _loadMoreIfNeeded(extentAfter: notification.metrics.extentAfter);
    return false;
  }

  Future<void> _loadNextPage(String cursor) async {
    setState(() {
      _pageLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await _controller.fetchOccurrenceProfileGroupMembersPage(
        eventId: widget.eventId,
        occurrenceId: widget.occurrenceId,
        groupId: widget.group.id,
        cursor: cursor,
      );
      if (!mounted) {
        return;
      }
      final nextItems = <String, TenantAdminAccountProfileSelectionSummary>{
        for (final item in _items) item.id: item,
        for (final item in page.items) item.id: item,
      };
      setState(() {
        _items = List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
          nextItems.values,
        );
        _nextCursor = page.nextCursor;
        _pageLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _pageLoading = false;
      });
    }
  }

  Future<void> _openAddMembersPicker() async {
    if (_mutationLoading) {
      return;
    }
    await _controller.prepareRelatedAccountProfilePicker();
    if (!mounted) {
      return;
    }

    final pendingAddIds = <String>{};
    final existingIds = _items.map((item) => item.id).toSet();

    await showTenantAdminAccountProfileMultiPicker(
      context: context,
      candidatesStreamValue:
          _controller.relatedAccountProfileCandidatesStreamValue,
      isLoadingStreamValue:
          _controller.relatedAccountProfileSearchLoadingStreamValue,
      isPageLoadingStreamValue:
          _controller.relatedAccountProfileSearchPageLoadingStreamValue,
      hasMoreStreamValue:
          _controller.relatedAccountProfileSearchHasMoreStreamValue,
      loadNextPage:
          _controller.loadNextRelatedAccountProfileCandidatesForNestedGroups,
      onSearchChanged: (query) => unawaited(
        _controller.searchRelatedAccountProfileCandidatesForNestedGroups(query),
      ),
      profileTypes: _controller.relatedAccountProfileTypesStreamValue.value,
      title: 'Adicionar perfis',
      emptyMessage: 'Nenhum perfil elegível encontrado.',
      selectedProfileIds: pendingAddIds,
      selectedProfileType:
          _controller.relatedAccountProfileSelectedTypeStreamValue.value,
      onProfileTypeChanged:
          _controller.filterRelatedAccountProfileCandidatesByProfileType,
      onSelectionChanged: (profileId, selected) {
        if (existingIds.contains(profileId)) {
          return;
        }
        if (selected) {
          pendingAddIds.add(profileId);
        } else {
          pendingAddIds.remove(profileId);
        }
      },
      searchLabelText: 'Buscar perfil',
      doneLabel: 'Adicionar',
    );

    if (!mounted || pendingAddIds.isEmpty) {
      return;
    }

    setState(() {
      _mutationLoading = true;
      _errorMessage = null;
    });
    try {
      await _controller.addOccurrenceProfileGroupMembers(
        eventId: widget.eventId,
        occurrenceId: widget.occurrenceId,
        occurrenceKey: widget.occurrenceKey,
        groupId: widget.group.id,
        addIds: pendingAddIds.toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      await _loadFirstPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _mutationLoading = false;
        });
      }
    }
  }

  Future<void> _removeMember(
    TenantAdminAccountProfileSelectionSummary item,
  ) async {
    if (_mutationLoading) {
      return;
    }

    setState(() {
      _mutationLoading = true;
      _errorMessage = null;
    });
    try {
      await _controller.removeOccurrenceProfileGroupMembers(
        eventId: widget.eventId,
        occurrenceId: widget.occurrenceId,
        occurrenceKey: widget.occurrenceKey,
        groupId: widget.group.id,
        removeIds: <String>[item.id],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = _items
            .where((entry) => entry.id != item.id)
            .toList(growable: false);
      });
      if (_items.isEmpty) {
        await _loadFirstPage();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _mutationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.label),
        actions: [
          IconButton(
            tooltip: 'Adicionar perfis',
            onPressed: _mutationLoading ? null : _openAddMembersPicker,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_mutationLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _items.length == 1
                    ? '1 perfil carregado'
                    : '${_items.length} perfis carregados',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _initialLoading ? null : _loadFirstPage,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum perfil vinculado neste grupo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length + (_pageLoading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = _items[index];
                        return ListTile(
                          key: Key(
                            'tenantAdminEventGroupMember_${widget.group.id}_${item.id}',
                          ),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            (item.displayName?.trim().isNotEmpty ?? false)
                                ? item.displayName!.trim()
                                : item.id,
                          ),
                          subtitle: Text(item.id),
                          trailing: IconButton(
                            tooltip: 'Remover perfil',
                            onPressed: _mutationLoading
                                ? null
                                : () => _removeMember(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mutationLoading ? null : _openAddMembersPicker,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}
