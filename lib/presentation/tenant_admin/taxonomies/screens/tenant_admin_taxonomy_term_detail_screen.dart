import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomyTermDetailScreen extends StatefulWidget {
  const TenantAdminTaxonomyTermDetailScreen({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
    required this.term,
  });

  final String taxonomyId;
  final String taxonomyName;
  final TenantAdminTaxonomyTermDefinition term;

  @override
  State<TenantAdminTaxonomyTermDetailScreen> createState() =>
      _TenantAdminTaxonomyTermDetailScreenState();
}

class _TenantAdminTaxonomyTermDetailScreenState
    extends State<TenantAdminTaxonomyTermDetailScreen> {
  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();

  @override
  void initState() {
    super.initState();
    _controller.initDetailTerm(widget.term);
  }

  @override
  void dispose() {
    _controller.clearDetailTerm();
    super.dispose();
  }

  Future<void> _editName() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome do termo',
      label: 'Nome',
      initialValue: _currentTerm().name,
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
    if (next.isEmpty || next == _currentTerm().name) {
      return;
    }
    await _saveChanges(name: next);
  }

  Future<void> _editSlug() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug do termo',
      label: 'Slug',
      initialValue: _currentTerm().slug,
      helperText: 'Deve ser unico dentro da taxonomia.',
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
    if (next.isEmpty || next == _currentTerm().slug) {
      return;
    }
    await _saveChanges(slug: next);
  }

  Future<void> _saveChanges({
    String? slug,
    String? name,
  }) async {
    final term = _currentTerm();
    final updated = await _controller.submitDetailTermUpdate(
      taxonomyId: widget.taxonomyId,
      termId: term.id,
      slug: slug,
      name: name,
    );
    if (!mounted) {
      return;
    }
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termo atualizado.')),
      );
      return;
    }
    final error = _controller.actionErrorMessageStreamValue.value ??
        'Não foi possível atualizar o termo.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  TenantAdminTaxonomyTermDefinition _currentTerm() {
    return _controller.detailTermStreamValue.value ?? widget.term;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminTaxonomyTermDefinition?>(
      streamValue: _controller.detailTermStreamValue,
      builder: (context, termValue) {
        final term = termValue ?? widget.term;
        return StreamValueBuilder<bool>(
          streamValue: _controller.detailTermSavingStreamValue,
          builder: (context, isSaving) {
            return Scaffold(
              appBar: AppBar(
                title: Text(term.name),
                actions: [
                  FilledButton.tonalIcon(
                    onPressed: isSaving
                        ? null
                        : () {
                            context.router.push(
                              TenantAdminTaxonomyTermEditRoute(
                                taxonomyId: widget.taxonomyId,
                                taxonomyName: widget.taxonomyName,
                                termId: term.id,
                                term: term,
                              ),
                            );
                          },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes do termo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _editableRow(
                            context,
                            label: 'Nome',
                            value: term.name,
                            isSaving: isSaving,
                            onEdit: _editName,
                          ),
                          const SizedBox(height: 8),
                          _editableRow(
                            context,
                            label: 'Slug',
                            value: term.slug,
                            isSaving: isSaving,
                            onEdit: _editSlug,
                          ),
                          const SizedBox(height: 8),
                          _buildRow(context, 'Taxonomia', widget.taxonomyName),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _editableRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isSaving,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          onPressed: isSaving ? null : onEdit,
          tooltip: 'Editar $label',
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
