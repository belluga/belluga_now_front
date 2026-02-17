import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomiesListScreen extends StatefulWidget {
  const TenantAdminTaxonomiesListScreen({super.key});

  @override
  State<TenantAdminTaxonomiesListScreen> createState() =>
      _TenantAdminTaxonomiesListScreenState();
}

class _TenantAdminTaxonomiesListScreenState
    extends State<TenantAdminTaxonomiesListScreen> {
  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.loadTaxonomies();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      _controller.loadNextTaxonomiesPage();
    }
  }

  Future<void> _openTaxonomyForm({
    TenantAdminTaxonomyDefinition? taxonomy,
  }) async {
    if (taxonomy == null) {
      await context.router.push(
        const TenantAdminTaxonomyCreateRoute(),
      );
      return;
    }
    await context.router.push(
      TenantAdminTaxonomyEditRoute(
        taxonomyId: taxonomy.id,
        taxonomy: taxonomy,
      ),
    );
  }

  Future<void> _editTaxonomyName(TenantAdminTaxonomyDefinition taxonomy) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome da taxonomia',
      label: 'Nome',
      initialValue: taxonomy.name,
      textCapitalization: TextCapitalization.words,
      autocorrect: true,
      enableSuggestions: true,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Nome obrigatorio.';
        }
        return null;
      },
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    if (next.isEmpty || next == taxonomy.name) {
      return;
    }
    await _controller.submitUpdateTaxonomy(
      taxonomyId: taxonomy.id,
      name: next,
    );
  }

  Future<void> _editTaxonomySlug(TenantAdminTaxonomyDefinition taxonomy) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug da taxonomia',
      label: 'Slug',
      initialValue: taxonomy.slug,
      helperText: 'Deve ser unico no tenant.',
      inputFormatters: tenantAdminSlugInputFormatters,
      validator: (value) => tenantAdminValidateRequiredSlug(
        value,
        requiredMessage: 'Slug obrigatorio.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    if (next.isEmpty || next == taxonomy.slug) {
      return;
    }
    await _controller.submitUpdateTaxonomy(
      taxonomyId: taxonomy.id,
      slug: next,
    );
  }

  Future<void> _confirmDelete(TenantAdminTaxonomyDefinition taxonomy) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover taxonomia',
      message: 'Remover "${taxonomy.name}"?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) return;
    await _controller.submitDeleteTaxonomy(taxonomy.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.successMessageStreamValue,
      builder: (context, successMessage) {
        _handleSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.actionErrorMessageStreamValue,
          builder: (context, actionErrorMessage) {
            _handleActionErrorMessage(actionErrorMessage);
            return StreamValueBuilder<String?>(
              streamValue: _controller.errorStreamValue,
              builder: (context, error) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.hasMoreTaxonomiesStreamValue,
                  builder: (context, hasMore) {
                    return StreamValueBuilder<bool>(
                      streamValue:
                          _controller.isTaxonomiesPageLoadingStreamValue,
                      builder: (context, isPageLoading) {
                        return StreamValueBuilder<
                            List<TenantAdminTaxonomyDefinition>?>(
                          streamValue: _controller.taxonomiesStreamValue,
                          onNullWidget: _buildScaffold(
                            context: context,
                            error: error,
                            body: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          builder: (context, taxonomies) {
                            final loadedTaxonomies = taxonomies ??
                                const <TenantAdminTaxonomyDefinition>[];
                            return _buildScaffold(
                              context: context,
                              error: error,
                              body: loadedTaxonomies.isEmpty
                                  ? const TenantAdminEmptyState(
                                      icon: Icons.account_tree_outlined,
                                      title: 'Nenhuma taxonomia cadastrada',
                                      description:
                                          'Use "Criar taxonomia" para organizar termos por tipo.',
                                    )
                                  : _buildTaxonomiesList(
                                      loadedTaxonomies: loadedTaxonomies,
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
    required String? error,
    required Widget body,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('taxonomies-create-fab'),
        onPressed: () => _openTaxonomyForm(),
        icon: const Icon(Icons.add),
        label: const Text('Criar taxonomia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxonomias cadastradas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage: 'Não foi possível carregar as taxonomias.',
                  onRetry: _controller.loadTaxonomies,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxonomiesList({
    required List<TenantAdminTaxonomyDefinition> loadedTaxonomies,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = loadedTaxonomies.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= loadedTaxonomies.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final taxonomy = loadedTaxonomies[index];
        final subtitle = taxonomy.appliesTo.join(' • ');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(taxonomy.name),
            subtitle: Text(subtitle.isEmpty ? taxonomy.slug : subtitle),
            onTap: () {
              context.router.push(
                TenantAdminTaxonomyTermsRoute(
                  taxonomyId: taxonomy.id,
                  taxonomyName: taxonomy.name,
                ),
              );
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'terms') {
                  context.router.push(
                    TenantAdminTaxonomyTermsRoute(
                      taxonomyId: taxonomy.id,
                      taxonomyName: taxonomy.name,
                    ),
                  );
                  return;
                }
                if (value == 'edit') {
                  await _openTaxonomyForm(taxonomy: taxonomy);
                  return;
                }
                if (value == 'edit-name') {
                  await _editTaxonomyName(taxonomy);
                  return;
                }
                if (value == 'edit-slug') {
                  await _editTaxonomySlug(taxonomy);
                  return;
                }
                if (value == 'delete') {
                  await _confirmDelete(taxonomy);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit-name',
                  child: Text('Editar nome'),
                ),
                const PopupMenuItem(
                  value: 'edit-slug',
                  child: Text('Editar slug'),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar completo'),
                ),
                const PopupMenuItem(
                  value: 'terms',
                  child: Text('Termos'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Remover'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSuccessMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearSuccessMessage();
    });
  }

  void _handleActionErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
