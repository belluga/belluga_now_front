import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticProfileTypeFormScreen extends StatefulWidget {
  const TenantAdminStaticProfileTypeFormScreen({
    super.key,
    this.definition,
  });

  final TenantAdminStaticProfileTypeDefinition? definition;

  @override
  State<TenantAdminStaticProfileTypeFormScreen> createState() =>
      _TenantAdminStaticProfileTypeFormScreenState();
}

class _TenantAdminStaticProfileTypeFormScreenState
    extends State<TenantAdminStaticProfileTypeFormScreen> {
  final TenantAdminStaticProfileTypesController _controller =
      GetIt.I.get<TenantAdminStaticProfileTypesController>();

  bool get _isEdit => widget.definition != null;

  @override
  void initState() {
    super.initState();
    _controller.initForm(widget.definition);
    _controller.loadTaxonomies();
  }

  @override
  void dispose() {
    _controller.resetFormState();
    super.dispose();
  }

  List<String> _selectedTaxonomies() {
    return _controller.selectedTaxonomiesStreamValue.value
        .toList(growable: false);
  }

  Future<void> _save() async {
    final form = _controller.formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final capabilities = _controller.currentCapabilities;
    final allowedTaxonomies = _selectedTaxonomies();

    if (_isEdit) {
      _controller.submitUpdateType(
        type: widget.definition!.type,
        label: _controller.labelController.text.trim(),
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      return;
    }

    _controller.submitCreateType(
      type: _controller.typeController.text.trim(),
      label: _controller.labelController.text.trim(),
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
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
          builder: (context, errorMessage) {
            _handleErrorMessage(errorMessage);
            return Scaffold(
              appBar: AppBar(
                title: Text(_isEdit ? 'Editar Tipo' : 'Criar Tipo'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.router.maybePop(),
                  tooltip: 'Voltar',
                ),
              ),
              body: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Informacoes do tipo',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _controller.typeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo (slug)',
                                  ),
                                  enabled: !_isEdit,
                                  validator: (value) {
                                    if (!_isEdit &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Tipo e obrigatorio.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _controller.labelController,
                                  decoration:
                                      const InputDecoration(labelText: 'Label'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Label e obrigatorio.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTaxonomiesSection(context),
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                StreamValueBuilder<
                                    TenantAdminStaticProfileTypeCapabilities>(
                                  streamValue:
                                      _controller.capabilitiesStreamValue,
                                  builder: (context, capabilities) {
                                    return Column(
                                      children: [
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('POI habilitado'),
                                          subtitle: const Text(
                                            'Quando habilitado, o ativo exige localizacao',
                                          ),
                                          value: capabilities.isPoiEnabled,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            isPoiEnabled: value,
                                          ),
                                        ),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Bio habilitada'),
                                          value: capabilities.hasBio,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            hasBio: value,
                                          ),
                                        ),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Taxonomias habilitadas'),
                                          value: capabilities.hasTaxonomies,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            hasTaxonomies: value,
                                          ),
                                        ),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Avatar habilitado'),
                                          value: capabilities.hasAvatar,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            hasAvatar: value,
                                          ),
                                        ),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Capa habilitada'),
                                          value: capabilities.hasCover,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            hasCover: value,
                                          ),
                                        ),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Conteudo habilitado'),
                                          value: capabilities.hasContent,
                                          onChanged: (value) =>
                                              _controller.updateCapabilities(
                                            hasContent: value,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _save,
                            child: Text(_isEdit ? 'Salvar' : 'Criar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaxonomiesSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
          streamValue: _controller.taxonomiesStreamValue,
          builder: (context, taxonomies) {
            return StreamValueBuilder<Set<String>>(
              streamValue: _controller.selectedTaxonomiesStreamValue,
              builder: (context, selected) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxonomias permitidas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (taxonomies.isEmpty)
                      const Text('Nenhuma taxonomia estatica disponivel.'),
                    if (taxonomies.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: taxonomies
                            .map(
                              (taxonomy) => FilterChip(
                                label: Text(taxonomy.name),
                                selected: selected.contains(taxonomy.slug),
                                onSelected: (enabled) {
                                  _controller.toggleTaxonomySelection(
                                    taxonomy.slug,
                                    enabled,
                                  );
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                );
              },
            );
          },
        ),
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
      context.router.maybePop();
    });
  }

  void _handleErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
