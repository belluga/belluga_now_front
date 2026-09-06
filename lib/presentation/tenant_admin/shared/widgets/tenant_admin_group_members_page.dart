import 'dart:async';

import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_state.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

final class TenantAdminGroupMembersPage extends StatefulWidget {
  const TenantAdminGroupMembersPage({
    super.key,
    required this.loadPage,
    required this.addMembers,
    required this.removeMembers,
    required this.title,
    required this.memberKeyPrefix,
    required this.searchFieldKey,
    required this.onAdd,
    this.leading,
  });

  final TenantAdminGroupMembersPageLoader loadPage;
  final TenantAdminGroupMembersMutation addMembers;
  final TenantAdminGroupMembersMutation removeMembers;
  final String title;
  final String memberKeyPrefix;
  final Key searchFieldKey;
  final Future<void> Function(TenantAdminGroupMembersPageController controller)
  onAdd;
  final Widget? leading;

  @override
  State<TenantAdminGroupMembersPage> createState() =>
      _TenantAdminGroupMembersPageState();
}

final class _TenantAdminGroupMembersPageState
    extends State<TenantAdminGroupMembersPage> {
  late final TenantAdminGroupMembersPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TenantAdminGroupMembersPageController(
      loadPage: widget.loadPage,
      addMembers: widget.addMembers,
      removeMembers: widget.removeMembers,
    );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminGroupMembersPageState>(
      streamValue: _controller.stateStreamValue,
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            leading: widget.leading,
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Adicionar perfis',
                onPressed: state.mutationLoading
                    ? null
                    : () => widget.onAdd(_controller),
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.mutationLoading) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.items.length == 1
                        ? '1 perfil carregado'
                        : '${state.items.length} perfis carregados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (state.searchAvailable || state.search.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    key: widget.searchFieldKey,
                    onChanged: _controller.updateSearch,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Buscar neste grupo',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              if (state.errorMessage?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              Expanded(
                child: state.initialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.items.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum perfil vinculado neste grupo.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis == Axis.vertical) {
                            _controller.loadMoreIfNeeded(
                              notification.metrics.extentAfter,
                            );
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = state.items[index];
                            final displayName = item.displayName?.trim();
                            return ListTile(
                              key: Key('${widget.memberKeyPrefix}${item.id}'),
                              title: Text(
                                displayName?.isNotEmpty == true
                                    ? displayName!
                                    : item.id,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: displayName?.isNotEmpty == true
                                  ? Text(
                                      item.id,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: IconButton(
                                tooltip: 'Remover perfil',
                                onPressed: state.mutationLoading
                                    ? null
                                    : () => _controller.remove(item.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            );
                          },
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemCount:
                              state.items.length + (state.pageLoading ? 1 : 0),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
