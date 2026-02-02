import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminProfileTypeFormScreen extends StatefulWidget {
  const TenantAdminProfileTypeFormScreen({
    super.key,
    this.definition,
  });

  final TenantAdminProfileTypeDefinition? definition;

  @override
  State<TenantAdminProfileTypeFormScreen> createState() =>
      _TenantAdminProfileTypeFormScreenState();
}

class _TenantAdminProfileTypeFormScreenState
    extends State<TenantAdminProfileTypeFormScreen> {
  final TenantAdminProfileTypesController _controller =
      GetIt.I.get<TenantAdminProfileTypesController>();

  bool get _isEdit => widget.definition != null;

  @override
  void initState() {
    super.initState();
    _controller.initForm(widget.definition);
  }

  @override
  void dispose() {
    _controller.resetFormState();
    super.dispose();
  }

  List<String> _parseTaxonomies(bool hasTaxonomies) {
    if (!hasTaxonomies) {
      return const [];
    }
    return _controller.taxonomiesController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final form = _controller.formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final capabilities = _controller.currentCapabilities;

    if (_isEdit) {
      await _controller.updateType(
        type: widget.definition!.type,
        label: _controller.labelController.text.trim(),
        allowedTaxonomies: _parseTaxonomies(capabilities.hasTaxonomies),
        capabilities: capabilities,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo atualizado.')),
      );
      context.router.maybePop();
      return;
    }

    await _controller.createType(
      type: _controller.typeController.text.trim(),
      label: _controller.labelController.text.trim(),
      allowedTaxonomies: _parseTaxonomies(capabilities.hasTaxonomies),
      capabilities: capabilities,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipo criado.')),
    );
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
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
                          decoration:
                              const InputDecoration(labelText: 'Tipo (slug)'),
                          enabled: !_isEdit,
                          validator: (value) {
                            if (!_isEdit &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Tipo e obrigatorio.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _controller.labelController,
                          decoration: const InputDecoration(labelText: 'Label'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Label e obrigatorio.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        StreamValueBuilder<
                            TenantAdminProfileTypeCapabilities>(
                          streamValue: _controller.capabilitiesStreamValue,
                          builder: (context, capabilities) {
                            return TextFormField(
                              controller: _controller.taxonomiesController,
                              decoration: const InputDecoration(
                                labelText: 'Taxonomias (separadas por virgula)',
                              ),
                              enabled: capabilities.hasTaxonomies,
                            );
                          },
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        StreamValueBuilder<
                            TenantAdminProfileTypeCapabilities>(
                          streamValue: _controller.capabilitiesStreamValue,
                          builder: (context, capabilities) {
                            return Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Favoritavel'),
                                  value: capabilities.isFavoritable,
                                  onChanged: (value) =>
                                      _controller.updateCapabilities(
                                    isFavoritable: value,
                                  ),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('POI habilitado'),
                                  subtitle: const Text(
                                      'Requer localizacao no perfil'),
                                  value: capabilities.isPoiEnabled,
                                  onChanged: (value) =>
                                      _controller.updateCapabilities(
                                    isPoiEnabled: value,
                                  ),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Bio habilitada'),
                                  subtitle: const Text(
                                      'Exibe campo de descricao no perfil'),
                                  value: capabilities.hasBio,
                                  onChanged: (value) =>
                                      _controller.updateCapabilities(
                                    hasBio: value,
                                  ),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Taxonomias habilitadas'),
                                  subtitle: const Text(
                                      'Exibe categorias/etiquetas do tipo'),
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
                                  title: const Text('Agenda habilitada'),
                                  subtitle:
                                      const Text('Mostra "Proximos Eventos"'),
                                  value: capabilities.hasEvents,
                                  onChanged: (value) =>
                                      _controller.updateCapabilities(
                                    hasEvents: value,
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
  }
}
