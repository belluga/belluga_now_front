import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
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

  List<String> _parseTaxonomies() {
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
    final allowedTaxonomies = _parseTaxonomies();

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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.maybePop(),
                tooltip: 'Voltar',
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Informacoes do tipo',
                        description:
                            'Defina identificador, nome exibido e taxonomias associadas.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.typeController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo (slug)',
                              ),
                              enabled: !_isEdit,
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
                              decoration:
                                  const InputDecoration(labelText: 'Label'),
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
                              controller: _controller.taxonomiesController,
                              decoration: const InputDecoration(
                                labelText: 'Taxonomias (separadas por virgula)',
                              ),
                            ),
                            if (!_isEdit) ...[
                              const SizedBox(height: 12),
                              StreamValueBuilder<bool>(
                                streamValue:
                                    _controller.isSlugAutoEnabledStreamValue,
                                builder: (context, isSlugAutoEnabled) {
                                  return SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Gerar slug automaticamente',
                                    ),
                                    subtitle: const Text(
                                      'Você pode desligar para personalizar manualmente.',
                                    ),
                                    value: isSlugAutoEnabled,
                                    onChanged: (value) {
                                      _controller.setSlugAutoEnabled(value);
                                      if (value) {
                                        _syncSlugFromLabel();
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
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
