import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
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
    if (!_isEdit) {
      _controller.labelController.addListener(_syncSlugFromLabel);
      _syncSlugFromLabel();
    }
  }

  @override
  void dispose() {
    if (!_isEdit) {
      _controller.labelController.removeListener(_syncSlugFromLabel);
    }
    _controller.resetFormState();
    super.dispose();
  }

  void _syncSlugFromLabel() {
    if (!_controller.isSlugAutoEnabled || _isEdit) {
      return;
    }
    final generated = tenantAdminSlugify(_controller.labelController.text);
    if (_controller.typeController.text == generated) {
      return;
    }
    _controller.typeController.value =
        _controller.typeController.value.copyWith(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
      composing: TextRange.empty,
    );
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
            return TenantAdminFormScaffold(
              title: _isEdit ? 'Editar Tipo' : 'Criar Tipo',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Informacoes do tipo',
                        description:
                            'Defina nome e identificador do tipo de ativo.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.labelController,
                              decoration:
                                  const InputDecoration(labelText: 'Label'),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => _syncSlugFromLabel(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Label e obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.typeController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo (slug)',
                              ),
                              enabled: !_isEdit,
                              keyboardType: TextInputType.visiblePassword,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              enableSuggestions: false,
                              inputFormatters: tenantAdminSlugInputFormatters,
                              onChanged: (value) {
                                if (_isEdit) {
                                  return;
                                }
                                final generated = tenantAdminSlugify(
                                  _controller.labelController.text,
                                );
                                if (_controller.isSlugAutoEnabled &&
                                    value != generated) {
                                  _controller.setSlugAutoEnabled(false);
                                }
                              },
                              validator: (value) {
                                if (_isEdit) {
                                  return null;
                                }
                                return tenantAdminValidateRequiredSlug(
                                  value,
                                  requiredMessage: 'Tipo e obrigatorio.',
                                  invalidMessage:
                                      'Tipo invalido. Use letras minusculas, numeros, - ou _.',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTaxonomiesSection(context),
                      const SizedBox(height: 16),
                      TenantAdminFormSectionCard(
                        title: 'Capacidades',
                        description:
                            'Configure os recursos habilitados para o tipo de ativo.',
                        child: StreamValueBuilder<
                            TenantAdminStaticProfileTypeCapabilities>(
                          streamValue: _controller.capabilitiesStreamValue,
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
                      ),
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        label: _isEdit ? 'Salvar alteracoes' : 'Criar tipo',
                        icon: _isEdit ? Icons.save_outlined : Icons.add,
                        onPressed: _save,
                      ),
                    ],
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
    return TenantAdminFormSectionCard(
      title: 'Taxonomias permitidas',
      description: 'Selecione quais taxonomias podem ser usadas neste tipo.',
      child: StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
        streamValue: _controller.taxonomiesStreamValue,
        builder: (context, taxonomies) {
          return StreamValueBuilder<Set<String>>(
            streamValue: _controller.selectedTaxonomiesStreamValue,
            builder: (context, selected) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
