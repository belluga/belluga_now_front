import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
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
    _controller.loadAvailableTaxonomies();
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

  Future<void> _save() async {
    final form = _controller.formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final capabilities = _controller.currentCapabilities;
    final allowedTaxonomies = _controller.selectedAllowedTaxonomies;

    if (_isEdit) {
      _controller.submitUpdateType(
        type: widget.definition!.type,
        newType: _controller.typeController.text.trim(),
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
                            'Defina nome exibido, identificador e taxonomias associadas.',
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
                                return tenantAdminValidateRequiredSlug(
                                  value,
                                  requiredMessage: 'Tipo e obrigatorio.',
                                  invalidMessage:
                                      'Tipo invalido. Use letras minusculas, numeros, - ou _.',
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTaxonomySelection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TenantAdminFormSectionCard(
                        title: 'Capacidades',
                        description:
                            'Ative os recursos que o perfil deve disponibilizar.',
                        child: StreamValueBuilder<
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
                                    'Requer localizacao no perfil',
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
                                  subtitle: const Text(
                                    'Exibe campo de descricao no perfil',
                                  ),
                                  value: capabilities.hasBio,
                                  onChanged: (value) =>
                                      _controller.updateCapabilities(
                                    hasBio: value,
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
                                  subtitle: const Text(
                                    'Mostra "Proximos Eventos"',
                                  ),
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

  Widget _buildTaxonomySelection() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.isTaxonomiesLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.taxonomiesErrorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
              streamValue: _controller.availableTaxonomiesStreamValue,
              builder: (context, availableTaxonomies) {
                return StreamValueBuilder<List<String>>(
                  streamValue: _controller.selectedAllowedTaxonomiesStreamValue,
                  builder: (context, selectedTaxonomies) {
                    final selectedSet = selectedTaxonomies.toSet();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading) const LinearProgressIndicator(),
                        if (error != null && error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TenantAdminErrorBanner(
                              rawError: error,
                              fallbackMessage:
                                  'Nao foi possivel carregar taxonomias.',
                              onRetry: _controller.loadAvailableTaxonomies,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Taxonomias permitidas',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (availableTaxonomies.isEmpty && !isLoading)
                          Text(
                            'Nenhuma taxonomia aplicavel a perfis encontrada.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableTaxonomies
                                .map(
                                  (taxonomy) => FilterChip(
                                    label: Text(
                                      '${taxonomy.name} (${taxonomy.slug})',
                                    ),
                                    selected:
                                        selectedSet.contains(taxonomy.slug),
                                    onSelected: (_) => _controller
                                        .toggleAllowedTaxonomy(taxonomy.slug),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                      ],
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
