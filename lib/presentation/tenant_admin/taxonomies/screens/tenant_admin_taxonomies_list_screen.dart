import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
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
  static const _appliesToOptions = <String>[
    'account_profile',
    'static_asset',
    'event',
  ];

  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();

  @override
  void initState() {
    super.initState();
    _controller.loadTaxonomies();
  }

  Future<void> _openTaxonomyForm({
    TenantAdminTaxonomyDefinition? taxonomy,
  }) async {
    _controller.resetTaxonomyForm();
    _controller.initTaxonomyForm(taxonomy);
    final selection = <String>{
      ...?taxonomy?.appliesTo,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(taxonomy == null
                  ? 'Criar taxonomia'
                  : 'Editar taxonomia'),
              content: Form(
                key: _controller.taxonomyFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _controller.slugController,
                        decoration: const InputDecoration(labelText: 'Slug'),
                        enabled: taxonomy == null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Slug obrigatorio.';
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
                            return 'Nome obrigatorio.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controller.iconController,
                        decoration: const InputDecoration(
                          labelText: 'Icon (Material)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controller.colorController,
                        decoration: const InputDecoration(
                          labelText: 'Cor (#RRGGBB)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Aplica em',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _appliesToOptions
                            .map(
                              (option) => FilterChip(
                                label: Text(option),
                                selected: selection.contains(option),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selection.add(option);
                                    } else {
                                      selection.remove(option);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.router.pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final form = _controller.taxonomyFormKey.currentState;
                    if (form == null || !form.validate()) {
                      return;
                    }
                    if (selection.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione ao menos um alvo.'),
                        ),
                      );
                      return;
                    }
                    context.router.pop(true);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final slug = _controller.slugController.text.trim();
    final name = _controller.nameController.text.trim();
    final icon = _controller.iconController.text.trim();
    final color = _controller.colorController.text.trim();
    if (taxonomy == null) {
      await _controller.submitCreateTaxonomy(
        slug: slug,
        name: name,
        appliesTo: selection.toList(),
        icon: icon.isEmpty ? null : icon,
        color: color.isEmpty ? null : color,
      );
    } else {
      await _controller.submitUpdateTaxonomy(
        taxonomyId: taxonomy.id,
        slug: slug,
        name: name,
        appliesTo: selection.toList(),
        icon: icon.isEmpty ? null : icon,
        color: color.isEmpty ? null : color,
      );
    }
  }

  Future<void> _confirmDelete(TenantAdminTaxonomyDefinition taxonomy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover taxonomia'),
        content: Text('Remover "${taxonomy.name}"?'),
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
            return StreamValueBuilder<bool>(
              streamValue: _controller.isLoadingStreamValue,
              builder: (context, isLoading) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.errorStreamValue,
                  builder: (context, error) {
                    return StreamValueBuilder(
                      streamValue: _controller.taxonomiesStreamValue,
                      builder: (context, taxonomies) {
                        return Scaffold(
                          floatingActionButton: FloatingActionButton.extended(
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
                                              onPressed:
                                                  _controller.loadTaxonomies,
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
                                  child: taxonomies.isEmpty
                                      ? _buildEmptyState(context)
                                      : ListView.separated(
                                          itemCount: taxonomies.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final taxonomy = taxonomies[index];
                                            final subtitle = taxonomy.appliesTo
                                                .join(' • ');
                                            return Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: ListTile(
                                                title: Text(taxonomy.name),
                                                subtitle: Text(
                                                  subtitle.isEmpty
                                                      ? taxonomy.slug
                                                      : subtitle,
                                                ),
                                                onTap: () {
                                                  context.router.push(
                                                    TenantAdminTaxonomyTermsRoute(
                                                      taxonomyId: taxonomy.id,
                                                      taxonomyName:
                                                          taxonomy.name,
                                                    ),
                                                  );
                                                },
                                                trailing:
                                                    PopupMenuButton<String>(
                                                  onSelected: (value) async {
                                                    if (value == 'terms') {
                                                      context.router.push(
                                                        TenantAdminTaxonomyTermsRoute(
                                                          taxonomyId:
                                                              taxonomy.id,
                                                          taxonomyName:
                                                              taxonomy.name,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    if (value == 'edit') {
                                                      await _openTaxonomyForm(
                                                        taxonomy: taxonomy,
                                                      );
                                                      return;
                                                    }
                                                    if (value == 'delete') {
                                                      await _confirmDelete(
                                                        taxonomy,
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text('Editar'),
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
            'Nenhuma taxonomia cadastrada.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openTaxonomyForm(),
            child: const Text('Criar taxonomia'),
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
