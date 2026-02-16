import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticProfileTypeDetailScreen extends StatefulWidget {
  const TenantAdminStaticProfileTypeDetailScreen({
    super.key,
    required this.definition,
  });

  final TenantAdminStaticProfileTypeDefinition definition;

  @override
  State<TenantAdminStaticProfileTypeDetailScreen> createState() =>
      _TenantAdminStaticProfileTypeDetailScreenState();
}

class _TenantAdminStaticProfileTypeDetailScreenState
    extends State<TenantAdminStaticProfileTypeDetailScreen> {
  final TenantAdminStaticProfileTypesController _controller =
      GetIt.I.get<TenantAdminStaticProfileTypesController>();

  @override
  void initState() {
    super.initState();
    _controller.initDetailType(widget.definition);
  }

  @override
  void dispose() {
    _controller.clearDetailType();
    super.dispose();
  }

  Future<void> _editLabel() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome do tipo',
      label: 'Label',
      initialValue: _currentDefinition().label,
      textCapitalization: TextCapitalization.words,
      autocorrect: true,
      enableSuggestions: true,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Label e obrigatorio.';
        }
        return null;
      },
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    if (next.isEmpty || next == _currentDefinition().label) {
      return;
    }
    await _saveChanges(label: next);
  }

  Future<void> _editSlug() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug do tipo',
      label: 'Tipo (slug)',
      initialValue: _currentDefinition().type,
      helperText: 'Deve ser unico no tenant.',
      inputFormatters: tenantAdminSlugInputFormatters,
      validator: (value) => tenantAdminValidateRequiredSlug(
        value,
        requiredMessage: 'Slug e obrigatorio.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    if (next.isEmpty || next == _currentDefinition().type) {
      return;
    }
    await _saveChanges(newType: next);
  }

  Future<void> _saveChanges({
    String? newType,
    String? label,
  }) async {
    final definition = _currentDefinition();
    final updated = await _controller.submitDetailTypeUpdate(
      type: definition.type,
      newType: newType,
      label: label,
    );
    if (!mounted) {
      return;
    }
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo atualizado.')),
      );
      return;
    }
    final error = _controller.actionErrorMessageStreamValue.value ??
        'Não foi possível atualizar o tipo.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  TenantAdminStaticProfileTypeDefinition _currentDefinition() {
    return _controller.detailTypeStreamValue.value ?? widget.definition;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminStaticProfileTypeDefinition?>(
      streamValue: _controller.detailTypeStreamValue,
      builder: (context, detailDefinition) {
        final definition = detailDefinition ?? widget.definition;
        final capabilities = <String>[
          if (definition.capabilities.isPoiEnabled) 'POI habilitado',
          if (definition.capabilities.hasBio) 'Bio',
          if (definition.capabilities.hasTaxonomies) 'Taxonomias',
          if (definition.capabilities.hasAvatar) 'Avatar',
          if (definition.capabilities.hasCover) 'Capa',
          if (definition.capabilities.hasContent) 'Conteudo',
        ];

        return StreamValueBuilder<bool>(
          streamValue: _controller.detailSavingStreamValue,
          builder: (context, isSaving) {
            return Scaffold(
              appBar: AppBar(
                title: Text(definition.label),
                actions: [
                  FilledButton.tonalIcon(
                    onPressed: isSaving
                        ? null
                        : () {
                            context.router.push(
                              TenantAdminStaticProfileTypeEditRoute(
                                profileType: definition.type,
                                definition: definition,
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
                            'Detalhes do tipo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _editableRow(
                            context,
                            label: 'Slug',
                            value: definition.type,
                            isSaving: isSaving,
                            onEdit: _editSlug,
                          ),
                          const SizedBox(height: 8),
                          _editableRow(
                            context,
                            label: 'Label',
                            value: definition.label,
                            isSaving: isSaving,
                            onEdit: _editLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capacidades',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: capabilities
                                .map((item) => Chip(label: Text(item)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (definition.allowedTaxonomies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Taxonomias permitidas',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: definition.allowedTaxonomies
                                  .map((item) => Chip(label: Text(item)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
}
