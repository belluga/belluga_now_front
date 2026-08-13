import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
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
  final navigationRouter = shellRouter ?? context.router;
  return navigationRouter.push<void>(
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
  final TenantAdminAccountProfilesController _controller = GetIt.I
      .get<TenantAdminAccountProfilesController>();

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
      final page = await _controller.fetchEditNestedGroupMembersPage(
        accountProfileId: widget.accountProfileId,
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
      final page = await _controller.fetchEditNestedGroupMembersPage(
        accountProfileId: widget.accountProfileId,
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
    await _controller.loadNestedProfileCandidates(
      excludeProfileId: widget.accountProfileId,
    );
    if (!mounted) {
      return;
    }

    final pendingAddIds = <String>{};
    final existingIds = _items.map((item) => item.id).toSet();

    await showTenantAdminAccountProfileMultiPicker(
      context: context,
      candidatesStreamValue: _controller.nestedProfileCandidatesStreamValue,
      isLoadingStreamValue: _controller.nestedProfileSearchLoadingStreamValue,
      isPageLoadingStreamValue:
          _controller.nestedProfileSearchPageLoadingStreamValue,
      hasMoreStreamValue: _controller.nestedProfileSearchHasMoreStreamValue,
      loadNextPage: _controller.loadNextNestedProfileCandidatesPage,
      onSearchChanged: _controller.searchNestedProfileCandidates,
      profileTypes: _controller.profileTypesStreamValue.value
          .where((profileType) => profileType.capabilities.isQueryable)
          .toList(growable: false),
      title: 'Adicionar perfis',
      emptyMessage: 'Nenhum perfil elegivel encontrado.',
      selectedProfileIds: pendingAddIds,
      onProfileTypeChanged:
          _controller.filterNestedProfileCandidatesByProfileType,
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
      await _controller.addEditNestedGroupMembers(
        accountProfileId: widget.accountProfileId,
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
      await _controller.removeEditNestedGroupMembers(
        accountProfileId: widget.accountProfileId,
        groupId: widget.group.id,
        removeIds: <String>[item.id],
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () {
            unawaited(context.router.maybePop());
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.group.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error),
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
                            'tenantAdminAccountProfileGroupMember_${item.id}',
                          ),
                          title: Text(
                            item.displayName?.trim().isNotEmpty == true
                                ? item.displayName!.trim()
                                : item.id,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: item.displayName?.trim().isNotEmpty == true
                              ? Text(
                                  item.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: IconButton(
                            tooltip: 'Remover perfil',
                            onPressed: _mutationLoading
                                ? null
                                : () => _removeMember(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemCount: _items.length + (_pageLoading ? 1 : 0),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
