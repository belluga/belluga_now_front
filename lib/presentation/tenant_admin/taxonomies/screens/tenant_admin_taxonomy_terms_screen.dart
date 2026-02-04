import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomyTermsScreen extends StatefulWidget {
  const TenantAdminTaxonomyTermsScreen({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
  });

  final String taxonomyId;
  final String taxonomyName;

  @override
  State<TenantAdminTaxonomyTermsScreen> createState() =>
      _TenantAdminTaxonomyTermsScreenState();
}

class _TenantAdminTaxonomyTermsScreenState
    extends State<TenantAdminTaxonomyTermsScreen> {
  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();

  @override
  void initState() {
    super.initState();
    _controller.loadTerms(widget.taxonomyId);
  }

  Future<void> _openTermForm({
    TenantAdminTaxonomyTermDefinition? term,
  }) async {
    _controller.resetTermForm();
    _controller.initTermForm(term);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(term == null ? 'Criar termo' : 'Editar termo'),
        content: Form(
          key: _controller.termFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller.termSlugController,
                decoration: const InputDecoration(labelText: 'Slug'),
                enabled: term == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Slug obrigatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.termNameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome obrigatorio.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.router.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final form = _controller.termFormKey.currentState;
              if (form == null || !form.validate()) {
                return;
              }
              context.router.pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final slug = _controller.termSlugController.text.trim();
    final name = _controller.termNameController.text.trim();
    if (term == null) {
      await _controller.submitCreateTerm(
        taxonomyId: widget.taxonomyId,
        slug: slug,
        name: name,
      );
    } else {
      await _controller.submitUpdateTerm(
        taxonomyId: widget.taxonomyId,
        termId: term.id,
        slug: slug,
        name: name,
      );
    }
  }

  Future<void> _confirmDelete(TenantAdminTaxonomyTermDefinition term) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover termo'),
        content: Text('Remover "${term.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.router.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.router.pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.submitDeleteTerm(
      taxonomyId: widget.taxonomyId,
      termId: term.id,
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
            return StreamValueBuilder<bool>(
              streamValue: _controller.isLoadingStreamValue,
              builder: (context, isLoading) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.errorStreamValue,
                  builder: (context, error) {
                    return StreamValueBuilder(
                      streamValue: _controller.termsStreamValue,
                      builder: (context, terms) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text('Termos: ${widget.taxonomyName}'),
                          ),
                          floatingActionButton: FloatingActionButton.extended(
                            onPressed: () => _openTermForm(),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 12),
                                if (isLoading) const LinearProgressIndicator(),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                error,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  _controller.loadTerms(
                                                widget.taxonomyId,
                                              ),
                                              child:
                                                  const Text('Tentar novamente'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: terms.isEmpty
                                      ? _buildEmptyState(context)
                                      : ListView.separated(
                                          itemCount: terms.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final term = terms[index];
                                            return Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: ListTile(
                                                title: Text(term.name),
                                                subtitle: Text(term.slug),
                                                trailing:
                                                    PopupMenuButton<String>(
                                                  onSelected: (value) async {
                                                    if (value == 'edit') {
                                                      await _openTermForm(
                                                        term: term,
                                                      );
                                                    }
                                                    if (value == 'delete') {
                                                      await _confirmDelete(
                                                        term,
                                                      );
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
                                        ),
                                ),
                              ],
                            ),
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
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nenhum termo cadastrado.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openTermForm(),
            child: const Text('Criar termo'),
          ),
        ],
      ),
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
