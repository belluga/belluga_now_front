import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminTaxonomyFormScreen extends StatefulWidget {
  const TenantAdminTaxonomyFormScreen({
    super.key,
    this.taxonomy,
  });

  final TenantAdminTaxonomyDefinition? taxonomy;

  @override
  State<TenantAdminTaxonomyFormScreen> createState() =>
      _TenantAdminTaxonomyFormScreenState();
}

class _TenantAdminTaxonomyFormScreenState
    extends State<TenantAdminTaxonomyFormScreen> {
  static const _iconSuggestions = <String, IconData>{
    'restaurant': Icons.restaurant_outlined,
    'music_note': Icons.music_note_outlined,
    'sports_soccer': Icons.sports_soccer_outlined,
    'theater_comedy': Icons.theater_comedy_outlined,
    'palette': Icons.palette_outlined,
    'location_on': Icons.location_on_outlined,
  };

  static const _colorSuggestions = <String, Color>{
    '#E53935': Color(0xFFE53935),
    '#FB8C00': Color(0xFFFB8C00),
    '#43A047': Color(0xFF43A047),
    '#1E88E5': Color(0xFF1E88E5),
    '#8E24AA': Color(0xFF8E24AA),
    '#546E7A': Color(0xFF546E7A),
  };

  static const _appliesToOptions = <String>[
    'account_profile',
    'static_asset',
    'event',
  ];

  final TenantAdminTaxonomiesController _controller =
      GetIt.I.get<TenantAdminTaxonomiesController>();

  bool get _isEdit => widget.taxonomy != null;

  @override
  void initState() {
    super.initState();
    _controller.resetTaxonomyForm();
    _controller.initTaxonomyForm(widget.taxonomy);
    if (!_isEdit) {
      _controller.nameController.addListener(_syncSlugFromName);
      _syncSlugFromName();
    }
  }

  @override
  void dispose() {
    if (!_isEdit) {
      _controller.nameController.removeListener(_syncSlugFromName);
    }
    super.dispose();
  }

  void _syncSlugFromName() {
    if (_isEdit || !_controller.isTaxonomySlugAutoEnabled) {
      return;
    }
    final generated = tenantAdminSlugify(_controller.nameController.text);
    if (_controller.slugController.text == generated) {
      return;
    }
    _controller.slugController.value =
        _controller.slugController.value.copyWith(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
      composing: TextRange.empty,
    );
  }

  Color? _parseHexColor(String raw) {
    final trimmed = raw.trim();
    if (!RegExp(r'^#(?:[0-9a-fA-F]{6})$').hasMatch(trimmed)) {
      return null;
    }
    final hex = trimmed.substring(1);
    final colorValue = int.parse(hex, radix: 16);
    return Color(0xFF000000 | colorValue);
  }

  Future<void> _save() async {
    final form = _controller.taxonomyFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_controller.selectedAppliesToTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um alvo.'),
        ),
      );
      return;
    }

    final slug = _controller.slugController.text.trim();
    final name = _controller.nameController.text.trim();
    final icon = _controller.iconController.text.trim();
    final color = _controller.colorController.text.trim();

    if (_isEdit) {
      await _controller.submitUpdateTaxonomy(
        taxonomyId: widget.taxonomy!.id,
        slug: slug,
        name: name,
        appliesTo: _controller.selectedAppliesToTargets.toList(growable: false),
        icon: icon.isEmpty ? null : icon,
        color: color.isEmpty ? null : color,
      );
      return;
    }

    await _controller.submitCreateTaxonomy(
      slug: slug,
      name: name,
      appliesTo: _controller.selectedAppliesToTargets.toList(growable: false),
      icon: icon.isEmpty ? null : icon,
      color: color.isEmpty ? null : color,
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
              title: _isEdit ? 'Editar taxonomia' : 'Criar taxonomia',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.taxonomyFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Identidade da taxonomia',
                        description:
                            'Defina nome, slug e metadados visuais da taxonomia.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.nameController,
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.slugController,
                              decoration: const InputDecoration(
                                labelText: 'Slug',
                              ),
                              enabled: !_isEdit,
                              onChanged: (value) {
                                if (_isEdit) {
                                  return;
                                }
                                final generated = tenantAdminSlugify(
                                  _controller.nameController.text,
                                );
                                if (_controller.isTaxonomySlugAutoEnabled &&
                                    value != generated) {
                                  _controller.setTaxonomySlugAutoEnabled(false);
                                }
                              },
                              validator: (value) {
                                return tenantAdminValidateRequiredSlug(
                                  value,
                                  requiredMessage: 'Slug obrigatorio.',
                                  invalidMessage:
                                      'Slug invalido. Use letras minusculas, numeros, - ou _.',
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.iconController,
                              decoration: const InputDecoration(
                                labelText: 'Icon (Material)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _iconSuggestions.entries
                                    .map(
                                      (entry) => ChoiceChip(
                                        avatar: Icon(entry.value, size: 16),
                                        label: Text(entry.key),
                                        selected:
                                            _controller.iconController.text ==
                                                entry.key,
                                        onSelected: (_) {
                                          _controller.iconController.text =
                                              entry.key;
                                          setState(() {});
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.colorController,
                              decoration: const InputDecoration(
                                labelText: 'Cor (#RRGGBB)',
                              ),
                              validator: tenantAdminValidateOptionalHexColor,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _colorSuggestions.entries
                                    .map(
                                      (entry) => ChoiceChip(
                                        avatar: CircleAvatar(
                                          radius: 7,
                                          backgroundColor: entry.value,
                                        ),
                                        label: Text(entry.key),
                                        selected: _controller
                                                .colorController.text
                                                .toUpperCase() ==
                                            entry.key,
                                        onSelected: (_) {
                                          _controller.colorController.text =
                                              entry.key;
                                          setState(() {});
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final previewColor = _parseHexColor(
                                  _controller.colorController.text,
                                );
                                final previewIcon = _iconSuggestions[
                                    _controller.iconController.text];
                                return Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: previewColor ??
                                            Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Icon(
                                        previewIcon ?? Icons.label_outline,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pré-visualização',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TenantAdminFormSectionCard(
                        title: 'Aplica em',
                        description:
                            'Selecione os domínios onde esta taxonomia deve ficar disponível.',
                        child: StreamValueBuilder<Set<String>>(
                          streamValue:
                              _controller.taxonomyAppliesToSelectionStreamValue,
                          builder: (context, selectedTargets) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _appliesToOptions
                                  .map(
                                    (option) => FilterChip(
                                      label: Text(option),
                                      selected:
                                          selectedTargets.contains(option),
                                      onSelected: (selected) {
                                        _controller
                                            .toggleTaxonomyAppliesToTarget(
                                          option,
                                          selected,
                                        );
                                      },
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        buttonKey:
                            const ValueKey('taxonomy-form-submit-button'),
                        label:
                            _isEdit ? 'Salvar alteracoes' : 'Criar taxonomia',
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
