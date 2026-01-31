import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
  final _formKey = GlobalKey<FormState>();
  late final TenantAdminProfileTypesController _controller;
  late final TextEditingController _typeController;
  late final TextEditingController _labelController;
  late final TextEditingController _taxonomiesController;
  bool _isFavoritable = false;
  bool _isPoiEnabled = false;
  bool _hasBio = false;
  bool _hasTaxonomies = false;
  bool _hasAvatar = false;
  bool _hasCover = false;
  bool _hasEvents = false;

  bool get _isEdit => widget.definition != null;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminProfileTypesController>();
    _typeController = TextEditingController(text: widget.definition?.type ?? '');
    _labelController =
        TextEditingController(text: widget.definition?.label ?? '');
    _taxonomiesController = TextEditingController(
      text: widget.definition?.allowedTaxonomies.join(', ') ?? '',
    );
    _isFavoritable = widget.definition?.capabilities.isFavoritable ?? false;
    _isPoiEnabled = widget.definition?.capabilities.isPoiEnabled ?? false;
    _hasBio = widget.definition?.capabilities.hasBio ?? false;
    _hasTaxonomies = widget.definition?.capabilities.hasTaxonomies ?? false;
    _hasAvatar = widget.definition?.capabilities.hasAvatar ?? false;
    _hasCover = widget.definition?.capabilities.hasCover ?? false;
    _hasEvents = widget.definition?.capabilities.hasEvents ?? false;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _labelController.dispose();
    _taxonomiesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseTaxonomies() {
    if (!_hasTaxonomies) {
      return const [];
    }
    return _taxonomiesController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final capabilities = TenantAdminProfileTypeCapabilities(
      isFavoritable: _isFavoritable,
      isPoiEnabled: _isPoiEnabled,
      hasBio: _hasBio,
      hasTaxonomies: _hasTaxonomies,
      hasAvatar: _hasAvatar,
      hasCover: _hasCover,
      hasEvents: _hasEvents,
    );

    if (_isEdit) {
      await _controller.updateType(
        type: widget.definition!.type,
        label: _labelController.text.trim(),
        allowedTaxonomies: _parseTaxonomies(),
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
      type: _typeController.text.trim(),
      label: _labelController.text.trim(),
      allowedTaxonomies: _parseTaxonomies(),
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
            key: _formKey,
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
                          controller: _typeController,
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
                          controller: _labelController,
                          decoration: const InputDecoration(labelText: 'Label'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Label e obrigatorio.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _taxonomiesController,
                          decoration: const InputDecoration(
                            labelText: 'Taxonomias (separadas por virgula)',
                          ),
                          enabled: _hasTaxonomies,
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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Favoritavel'),
                          value: _isFavoritable,
                          onChanged: (value) =>
                              setState(() => _isFavoritable = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('POI habilitado'),
                          subtitle:
                              const Text('Requer localizacao no perfil'),
                          value: _isPoiEnabled,
                          onChanged: (value) =>
                              setState(() => _isPoiEnabled = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Bio habilitada'),
                          subtitle:
                              const Text('Exibe campo de descricao no perfil'),
                          value: _hasBio,
                          onChanged: (value) =>
                              setState(() => _hasBio = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Taxonomias habilitadas'),
                          subtitle:
                              const Text('Exibe categorias/etiquetas do tipo'),
                          value: _hasTaxonomies,
                          onChanged: (value) =>
                              setState(() => _hasTaxonomies = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Avatar habilitado'),
                          value: _hasAvatar,
                          onChanged: (value) =>
                              setState(() => _hasAvatar = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Capa habilitada'),
                          value: _hasCover,
                          onChanged: (value) =>
                              setState(() => _hasCover = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Agenda habilitada'),
                          subtitle: const Text('Mostra "Proximos Eventos"'),
                          value: _hasEvents,
                          onChanged: (value) =>
                              setState(() => _hasEvents = value),
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
