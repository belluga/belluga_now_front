import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomy_terms_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomyTermsListScreen extends StatefulWidget {
  const TenantAdminTaxonomyTermsListScreen({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
  });

  final String taxonomyId;
  final String taxonomyName;

  @override
  State<TenantAdminTaxonomyTermsListScreen> createState() =>
      _TenantAdminTaxonomyTermsListScreenState();
}

class _TenantAdminTaxonomyTermsListScreenState
    extends State<TenantAdminTaxonomyTermsListScreen> {
  final TenantAdminTaxonomyTermsController _controller =
      GetIt.I.get<TenantAdminTaxonomyTermsController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.loadTerms(widget.taxonomyId);
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
      _controller.loadNextTermsPage();
    }
  }

  Future<void> _confirmDelete(TenantAdminTaxonomyTermDefinition term) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover termo',
      message: 'Remover "${term.name}" (${term.slug})?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) return;
    _controller.submitDeleteTerm(
      taxonomyId: widget.taxonomyId,
      termId: term.id,
    );
  }

  Future<void> _openForm({TenantAdminTaxonomyTermDefinition? term}) async {
    if (term == null) {
      await context.router.push(
        TenantAdminTaxonomyTermCreateRoute(
          taxonomyId: widget.taxonomyId,
          taxonomyName: widget.taxonomyName,
        ),
      );
      return;
    }
    await context.router.push(
      TenantAdminTaxonomyTermEditRoute(
        taxonomyId: widget.taxonomyId,
        taxonomyName: widget.taxonomyName,
        term: term,
      ),
    );
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
                  streamValue: _controller.hasMoreTermsStreamValue,
                  builder: (context, hasMore) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.isTermsPageLoadingStreamValue,
                      builder: (context, isPageLoading) {
                        return StreamValueBuilder<
                            List<TenantAdminTaxonomyTermDefinition>?>(
                          streamValue: _controller.termsStreamValue,
                          onNullWidget: _buildScaffold(
                            context: context,
                            error: error,
                            body: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          builder: (context, terms) {
                            final loadedTerms = terms ??
                                const <TenantAdminTaxonomyTermDefinition>[];
                            return _buildScaffold(
                              context: context,
                              error: error,
                              body: loadedTerms.isEmpty
                                  ? const TenantAdminEmptyState(
                                      icon: Icons.tag_outlined,
                                      title: 'Nenhum termo cadastrado',
                                      description:
                                          'Use "Criar termo" para adicionar termos nesta taxonomia.',
                                    )
                                  : _buildTermsList(
                                      loadedTerms: loadedTerms,
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
      appBar: AppBar(
        title: Text('Termos • ${widget.taxonomyName}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Criar termo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos cadastrados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar os termos da taxonomia.',
                  onRetry: () => _controller.loadTerms(widget.taxonomyId),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsList({
    required List<TenantAdminTaxonomyTermDefinition> loadedTerms,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = loadedTerms.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= loadedTerms.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final term = loadedTerms[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(term.name),
            subtitle: Text(term.slug),
            onTap: () {
              _openForm(term: term);
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openForm(term: term);
                }
                if (value == 'delete') {
                  _confirmDelete(term);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
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
    if (message == null || message.isEmpty || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearSuccessMessage();
    });
  }

  void _handleActionErrorMessage(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
