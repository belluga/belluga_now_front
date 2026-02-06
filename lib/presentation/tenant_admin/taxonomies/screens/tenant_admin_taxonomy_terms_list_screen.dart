import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.loadTerms(widget.taxonomyId);
  }

  Future<void> _confirmDelete(TenantAdminTaxonomyTermDefinition term) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover termo'),
          content: Text('Remover "${term.name}" (${term.slug})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    _controller.submitDeleteTerm(
      taxonomyId: widget.taxonomyId,
      termId: term.id,
    );
  }

  Future<void> _openForm({TenantAdminTaxonomyTermDefinition? term}) async {
    _controller.resetForm();
    _controller.initForm(term);
    await showDialog(
      context: context,
      builder: (context) {
        final isEdit = term != null;
        return AlertDialog(
          title: Text(isEdit ? 'Editar termo' : 'Criar termo'),
          content: Form(
            key: _controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controller.slugController,
                  decoration: const InputDecoration(labelText: 'Slug'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Slug é obrigatório.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _controller.nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final form = _controller.formKey.currentState;
                if (form == null || !form.validate()) {
                  return;
                }
                final currentTerm = term;
                if (isEdit && currentTerm != null) {
                  await _controller.submitUpdateTerm(
                    taxonomyId: widget.taxonomyId,
                    termId: currentTerm.id,
                    slug: _controller.slugController.text.trim(),
                    name: _controller.nameController.text.trim(),
                  );
                } else {
                  await _controller.submitCreateTerm(
                    taxonomyId: widget.taxonomyId,
                    slug: _controller.slugController.text.trim(),
                    name: _controller.nameController.text.trim(),
                  );
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(isEdit ? 'Salvar' : 'Criar'),
            ),
          ],
        );
      },
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
                    return StreamValueBuilder<List<TenantAdminTaxonomyTermDefinition>>(
                      streamValue: _controller.termsStreamValue,
                      builder: (context, terms) {
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
                                              onPressed: () => _controller
                                                  .loadTerms(widget.taxonomyId),
                                              child: const Text('Tentar novamente'),
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
                                                      await _openForm(term: term);
                                                    }
                                                    if (value == 'delete') {
                                                      await _confirmDelete(term);
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
            'Nenhum termo cadastrado ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openForm(),
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
