import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_list_controls_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_profiles_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountsListScreen extends StatefulWidget {
  const TenantAdminAccountsListScreen({super.key});

  @override
  State<TenantAdminAccountsListScreen> createState() =>
      _TenantAdminAccountsListScreenState();
}

class _TenantAdminAccountsListScreenState
    extends State<TenantAdminAccountsListScreen> {
  final TenantAdminAccountProfilesListController _controller = GetIt.I
      .get<TenantAdminAccountProfilesListController>();
  static const ValueKey<String> _controlsPanelKey = ValueKey<String>(
    'tenant_admin_accounts_controls_panel',
  );
  static const ValueKey<String> _searchToggleKey = ValueKey<String>(
    'tenant_admin_accounts_search_toggle',
  );
  static const ValueKey<String> _searchFieldKey = ValueKey<String>(
    'tenant_admin_accounts_search_field',
  );
  static const ValueKey<String> _manageTypesButtonKey = ValueKey<String>(
    'tenant_admin_accounts_manage_types_button',
  );

  @override
  void initState() {
    super.initState();
    _controller.bindProfilesListScrollPagination();
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.unbindProfilesListScrollPagination();
    super.dispose();
  }

  StackRouter _navigationRouter(BuildContext context) {
    final shellRouter = context.innerRouterOf<StackRouter>(
      TenantAdminShellRoute.name,
    );
    return shellRouter ?? context.router;
  }

  void _refreshProfilesList() {
    unawaited(_controller.loadProfiles());
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.showSearchFieldStreamValue,
          builder: (context, showSearchField) {
            return StreamValueBuilder<String>(
              streamValue: _controller.searchQueryStreamValue,
              builder: (context, _) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.hasMoreProfilesStreamValue,
                  builder: (context, hasMore) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.isProfilesPageLoadingStreamValue,
                      builder: (context, isPageLoading) {
                        return StreamValueBuilder<
                          List<TenantAdminAccountProfile>?
                        >(
                          streamValue: _controller.profilesStreamValue,
                          onNullWidget: _buildScaffold(
                            context: context,
                            showSearchField: showSearchField,
                            error: error,
                            content: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          builder: (context, profiles) {
                            final loadedProfiles =
                                profiles ?? const <TenantAdminAccountProfile>[];
                            return _buildScaffold(
                              context: context,
                              showSearchField: showSearchField,
                              error: error,
                              content: loadedProfiles.isEmpty
                                  ? const TenantAdminEmptyState(
                                      icon: Icons.group_off_outlined,
                                      title: 'Nenhum perfil encontrado',
                                      description:
                                          'Crie a primeira conta deste tenant usando o botão "Criar conta".',
                                    )
                                  : _buildProfilesList(
                                      profiles: loadedProfiles,
                                      hasMore: hasMore,
                                      isPageLoading: isPageLoading,
                                    ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required bool showSearchField,
    required String? error,
    required Widget content,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final router = _navigationRouter(context);
          final messenger = ScaffoldMessenger.of(context);
          router.push<bool>(const TenantAdminAccountCreateRoute()).then((
            created,
          ) {
            if (!mounted) return;
            _refreshProfilesList();
            if (created == true) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Conta e perfil salvos.')),
              );
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TenantAdminListControlsPanel(
              key: _controlsPanelKey,
              filterLabel: 'Perfis de conta',
              filterField: const SizedBox.shrink(),
              showSearchField: showSearchField,
              onToggleSearch: _controller.toggleSearchFieldVisibility,
              onSearchChanged: _controller.updateSearchQuery,
              searchHintText: 'Nome, categoria ou taxonomia',
              manageButtonLabel: 'Tipos de perfil',
              onManagePressed: () {
                _navigationRouter(
                  context,
                ).push(const TenantAdminProfileTypesListRoute());
              },
              searchToggleKey: _searchToggleKey,
              searchFieldKey: _searchFieldKey,
              manageButtonKey: _manageTypesButtonKey,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar os perfis do tenant.',
                  onRetry: _controller.loadProfiles,
                ),
              ),
            const SizedBox(height: 12),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesList({
    required List<TenantAdminAccountProfile> profiles,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = profiles.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _controller.profilesListScrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= profiles.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final profile = profiles[index];
        final accountSlug = profile.accountSlug?.trim();
        final canEdit =
            accountSlug != null &&
            accountSlug.isNotEmpty &&
            (profile.ownershipState == TenantAdminOwnershipState.tenantOwned ||
                profile.ownershipState == TenantAdminOwnershipState.unmanaged);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey<String>(
              'tenant_admin_account_profile_card_${profile.id}',
            ),
            onTap: canEdit
                ? () {
                    _navigationRouter(context)
                        .push(
                          TenantAdminAccountProfileEditRoute(
                            accountSlug: accountSlug,
                            accountProfileId: profile.id,
                          ),
                        )
                        .then((_) {
                          if (mounted) _refreshProfilesList();
                        });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileAvatar(context, profile),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (profile.slug case final slug?)
                          if (slug.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              slug,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildProfileMetaChip(
                              context,
                              label: profile.profileType,
                            ),
                            if (profile.ownershipState case final ownership?)
                              _buildProfileMetaChip(
                                context,
                                label: ownership.label,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canEdit)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    TenantAdminAccountProfile profile,
  ) {
    final avatarUrl = profile.avatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return BellugaNetworkImage(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(20),
        errorWidget: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.account_circle_outlined),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.account_circle_outlined),
    );
  }

  Widget _buildProfileMetaChip(BuildContext context, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
