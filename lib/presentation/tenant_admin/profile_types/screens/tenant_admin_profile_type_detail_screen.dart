import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminProfileTypeDetailScreen extends StatefulWidget {
  const TenantAdminProfileTypeDetailScreen({
    super.key,
    required this.definition,
  });

  final TenantAdminProfileTypeDefinition definition;

  @override
  State<TenantAdminProfileTypeDetailScreen> createState() =>
      _TenantAdminProfileTypeDetailScreenState();
}

class _TenantAdminProfileTypeDetailScreenState
    extends State<TenantAdminProfileTypeDetailScreen> {
  final TenantAdminProfileTypesController _controller =
      GetIt.I.get<TenantAdminProfileTypesController>();
  late TenantAdminProfileTypeDefinition _definition;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _definition = widget.definition;
  }

  Future<void> _editLabel() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome do tipo',
      label: 'Label',
      initialValue: _definition.label,
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
    if (next.isEmpty || next == _definition.label) {
      return;
    }
    await _saveChanges(label: next);
  }

  Future<void> _editSlug() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug do tipo',
      label: 'Tipo (slug)',
      initialValue: _definition.type,
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
    if (next.isEmpty || next == _definition.type) {
      return;
    }
    await _saveChanges(newType: next);
  }

  Future<void> _saveChanges({
    String? newType,
    String? label,
  }) async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _controller.updateType(
        type: _definition.type,
        newType: newType,
        label: label,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _definition = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo atualizado.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = <String>[
      if (_definition.capabilities.isFavoritable) 'Favoritavel',
      if (_definition.capabilities.isPoiEnabled) 'POI habilitado',
      if (_definition.capabilities.hasBio) 'Bio',
      if (_definition.capabilities.hasTaxonomies) 'Taxonomias',
      if (_definition.capabilities.hasAvatar) 'Avatar',
      if (_definition.capabilities.hasCover) 'Capa',
      if (_definition.capabilities.hasEvents) 'Agenda',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_definition.label),
        actions: [
          FilledButton.tonalIcon(
            onPressed: _isSaving
                ? null
                : () {
                    context.router.push(
                      TenantAdminProfileTypeEditRoute(
                        profileType: _definition.type,
                        definition: _definition,
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
                    value: _definition.type,
                    onEdit: _editSlug,
                  ),
                  const SizedBox(height: 8),
                  _editableRow(
                    context,
                    label: 'Label',
                    value: _definition.label,
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
          if (_definition.allowedTaxonomies.isNotEmpty) ...[
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
                      children: _definition.allowedTaxonomies
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
  }

  Widget _editableRow(
    BuildContext context, {
    required String label,
    required String value,
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
          onPressed: _isSaving ? null : onEdit,
          tooltip: 'Editar $label',
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}
