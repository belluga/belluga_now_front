import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomyTermFormScreen extends StatefulWidget {
  const TenantAdminTaxonomyTermFormScreen({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
    this.term,
  });

  final String taxonomyId;
  final String taxonomyName;
  final TenantAdminTaxonomyTermDefinition? term;

  @override
  State<TenantAdminTaxonomyTermFormScreen> createState() =>
      _TenantAdminTaxonomyTermFormScreenState();
}

class _TenantAdminTaxonomyTermFormScreenState
    extends State<TenantAdminTaxonomyTermFormScreen> {
  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();

  bool get _isEdit => widget.term != null;

  @override
  void initState() {
    super.initState();
    _controller.resetTermForm();
    _controller.initTermForm(widget.term);
    if (!_isEdit) {
      _controller.termNameController.addListener(_syncSlugFromName);
      _syncSlugFromName();
    }
  }

  @override
  void dispose() {
    if (!_isEdit) {
      _controller.termNameController.removeListener(_syncSlugFromName);
    }
    super.dispose();
  }

  void _syncSlugFromName() {
    if (_isEdit || !_controller.isTermSlugAutoEnabled) {
      return;
    }
    final generated = tenantAdminSlugify(_controller.termNameController.text);
    if (_controller.termSlugController.text == generated) {
      return;
    }
    _controller.termSlugController.value =
        _controller.termSlugController.value.copyWith(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _save() async {
    final form = _controller.termFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final slug = _controller.termSlugController.text.trim();
    final name = _controller.termNameController.text.trim();
    if (_isEdit) {
      await _controller.submitUpdateTerm(
        taxonomyId: widget.taxonomyId,
        termId: widget.term!.id,
        slug: slug,
        name: name,
      );
      return;
    }
    await _controller.submitCreateTerm(
      taxonomyId: widget.taxonomyId,
      slug: slug,
      name: name,
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
          builder: (context, actionErrorMessage) {
            _handleActionErrorMessage(actionErrorMessage);
            return TenantAdminFormScaffold(
              title: _isEdit ? 'Editar termo' : 'Criar termo',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.maybePop(),
                tooltip: 'Voltar',
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.termFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Termo em ${widget.taxonomyName}',
                        description:
                            'Defina o slug e o nome do termo para esta taxonomia.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.termSlugController,
                              decoration: const InputDecoration(
                                labelText: 'Slug',
                              ),
                              enabled: !_isEdit,
                              onChanged: (value) {
                                if (_isEdit) {
                                  return;
                                }
                                final generated = tenantAdminSlugify(
                                  _controller.termNameController.text,
                                );
                                if (_controller.isTermSlugAutoEnabled &&
                                    value != generated) {
                                  _controller.setTermSlugAutoEnabled(false);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Slug obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.termNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                              onChanged: (_) => _syncSlugFromName(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            if (!_isEdit) ...[
                              const SizedBox(height: 12),
                              StreamValueBuilder<bool>(
                                streamValue:
                                    _controller.isTermSlugAutoEnabledStreamValue,
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
                                      _controller.setTermSlugAutoEnabled(value);
                                      if (value) {
                                        _syncSlugFromName();
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        label: _isEdit ? 'Salvar alteracoes' : 'Criar termo',
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
    if (message == null || message.isEmpty || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.router.maybePop();
    });
  }

  void _handleActionErrorMessage(String? message) {
    if (message == null || message.isEmpty || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
