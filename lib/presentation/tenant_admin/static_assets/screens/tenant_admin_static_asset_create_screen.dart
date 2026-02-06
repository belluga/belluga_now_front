import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticAssetCreateScreen extends StatefulWidget {
  const TenantAdminStaticAssetCreateScreen({super.key});

  @override
  State<TenantAdminStaticAssetCreateScreen> createState() =>
      _TenantAdminStaticAssetCreateScreenState();
}

class _TenantAdminStaticAssetCreateScreenState
    extends State<TenantAdminStaticAssetCreateScreen> {
  final TenantAdminStaticAssetsController _controller =
      GetIt.I.get<TenantAdminStaticAssetsController>();

  @override
  void initState() {
    super.initState();
    _controller.initCreate();
  }

  @override
  void dispose() {
    _controller.clearSubmitMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.submitSuccessStreamValue,
      builder: (context, successMessage) {
        _handleSubmitSuccess(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.submitErrorStreamValue,
          builder: (context, errorMessage) {
            _handleSubmitError(errorMessage);
            return StreamValueBuilder<String?>(
              streamValue: _controller.errorStreamValue,
              builder: (context, error) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.selectedProfileTypeStreamValue,
                  builder: (context, selectedType) {
                    final selectedDefinition =
                        _profileTypeDefinition(selectedType);
                    final requiresLocation =
                        selectedDefinition?.capabilities.isPoiEnabled ?? false;
                    final hasBio =
                        selectedDefinition?.capabilities.hasBio ?? false;
                    final hasContent =
                        selectedDefinition?.capabilities.hasContent ?? false;
                    final hasTaxonomies =
                        selectedDefinition?.capabilities.hasTaxonomies ?? false;
                    final hasAvatar =
                        selectedDefinition?.capabilities.hasAvatar ?? false;
                    final hasCover =
                        selectedDefinition?.capabilities.hasCover ?? false;
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Criar ativo'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.router.maybePop(),
                        ),
                      ),
                      body: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Form(
                          key: _controller.formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBasicSection(context, error),
                                const SizedBox(height: 16),
                                _buildStatusSection(),
                                if (hasBio ||
                                    hasContent ||
                                    _hasTagsOrCategories()) ...[
                                  const SizedBox(height: 16),
                                  _buildContentSection(
                                    context,
                                    hasBio: hasBio,
                                    hasContent: hasContent,
                                  ),
                                ],
                                if (hasAvatar || hasCover) ...[
                                  const SizedBox(height: 16),
                                  _buildMediaSection(
                                    hasAvatar: hasAvatar,
                                    hasCover: hasCover,
                                  ),
                                ],
                                if (hasTaxonomies) ...[
                                  const SizedBox(height: 16),
                                  _buildTaxonomySection(context),
                                ],
                                if (requiresLocation) ...[
                                  const SizedBox(height: 16),
                                  _buildLocationSection(context),
                                ],
                                const SizedBox(height: 24),
                                _buildSubmitButton(),
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
          },
        );
      },
    );
  }

  TenantAdminStaticProfileTypeDefinition? _profileTypeDefinition(
    String? selectedType,
  ) {
    if (selectedType == null || selectedType.isEmpty) {
      return null;
    }
    for (final definition in _controller.profileTypesStreamValue.value) {
      if (definition.type == selectedType) {
        return definition;
      }
    }
    return null;
  }

  void _clearCapabilityFields(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    if (!(definition?.capabilities.hasBio ?? false)) {
      _controller.bioController.clear();
    }
    if (!(definition?.capabilities.hasContent ?? false)) {
      _controller.contentController.clear();
    }
    if (!(definition?.capabilities.hasTaxonomies ?? false)) {
      _controller.selectedTaxonomyTermsStreamValue.addValue(const {});
    }
    if (!(definition?.capabilities.hasAvatar ?? false)) {
      _controller.avatarUrlController.clear();
    }
    if (!(definition?.capabilities.hasCover ?? false)) {
      _controller.coverUrlController.clear();
    }
    if (!(definition?.capabilities.isPoiEnabled ?? false)) {
      _controller.latitudeController.clear();
      _controller.longitudeController.clear();
    }
  }

  bool _hasTagsOrCategories() {
    return true;
  }

  Map<String, String> _taxonomyLabels(
    List<TenantAdminTaxonomyDefinition> taxonomies,
  ) {
    return {
      for (final taxonomy in taxonomies) taxonomy.slug: taxonomy.name,
    };
  }

  Future<void> _openMapPicker() async {
    final currentLocation = _currentLocation();
    context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
      ),
    );
  }

  TenantAdminLocation? _currentLocation() {
    final latText = _controller.latitudeController.text.trim();
    final lngText = _controller.longitudeController.text.trim();
    if (latText.isEmpty || lngText.isEmpty) {
      return null;
    }
    final lat = double.tryParse(latText);
    final lng = double.tryParse(lngText);
    if (lat == null || lng == null) {
      return null;
    }
    return TenantAdminLocation(latitude: lat, longitude: lng);
  }

  String? _validateLatitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.longitudeController.text.trim();
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isEmpty) {
      return 'Localizacao obrigatoria.';
    }
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Latitude invalida.';
    }
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Latitude obrigatoria.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.latitudeController.text.trim();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Longitude invalida.';
    }
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Longitude obrigatoria.';
    }
    return null;
  }

  void _handleSubmitSuccess(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearSubmitMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.router.maybePop();
    });
  }

  void _handleSubmitError(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearSubmitMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Widget _buildBasicSection(BuildContext context, String? error) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados basicos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<bool>(
              streamValue: _controller.isLoadingStreamValue,
              builder: (context, isLoading) {
                return StreamValueBuilder<List<TenantAdminStaticProfileTypeDefinition>>(
                  streamValue: _controller.profileTypesStreamValue,
                  builder: (context, profileTypes) {
                    final hasTypes = profileTypes.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading) const LinearProgressIndicator(),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    error,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _controller.loadProfileTypes,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        StreamValueBuilder<String?>(
                          streamValue:
                              _controller.selectedProfileTypeStreamValue,
                          builder: (context, selectedType) {
                            return DropdownButtonFormField<String>(
                              key: ValueKey(selectedType),
                              initialValue: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de ativo',
                              ),
                              items: profileTypes
                                  .map(
                                    (type) => DropdownMenuItem<String>(
                                      value: type.type,
                                      child: Text(type.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: hasTypes
                                  ? (value) {
                                      _controller
                                          .updateSelectedProfileType(value);
                                      _clearCapabilityFields(value);
                                    }
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tipo de ativo e obrigatorio.';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        if (!isLoading && error == null && !hasTypes)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Nenhum tipo de ativo disponivel.',
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.displayNameController,
              decoration: const InputDecoration(labelText: 'Nome de exibicao'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome e obrigatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.slugController,
              decoration: const InputDecoration(labelText: 'Slug'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Slug e obrigatorio.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamValueBuilder<bool>(
          streamValue: _controller.isActiveStreamValue,
          builder: (context, isActive) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              subtitle: const Text('Exibir ativo nas superficies publicas.'),
              value: isActive,
              onChanged: _controller.updateIsActive,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context, {
    required bool hasBio,
    required bool hasContent,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conteudo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasBio) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
            ],
            if (hasContent) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.contentController,
                decoration: const InputDecoration(labelText: 'Conteudo'),
                maxLines: 6,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (separadas por virgulas)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.categoriesController,
              decoration: const InputDecoration(
                labelText: 'Categorias (separadas por virgulas)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection({
    required bool hasAvatar,
    required bool hasCover,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Midia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasAvatar) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.avatarUrlController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
              ),
            ],
            if (hasCover) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.coverUrlController,
                decoration: const InputDecoration(labelText: 'Capa URL'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaxonomySection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamValueBuilder<bool>(
          streamValue: _controller.taxonomyLoadingStreamValue,
          builder: (context, isLoading) {
            return StreamValueBuilder<String?>(
              streamValue: _controller.taxonomyErrorStreamValue,
              builder: (context, taxonomyError) {
                return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
                  streamValue: _controller.taxonomiesStreamValue,
                  builder: (context, taxonomies) {
                    return StreamValueBuilder<
                        Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
                      streamValue: _controller.taxonomyTermsStreamValue,
                      builder: (context, termsByTaxonomy) {
                        return StreamValueBuilder<Map<String, Set<String>>>(
                          streamValue:
                              _controller.selectedTaxonomyTermsStreamValue,
                          builder: (context, selectedTerms) {
                            final labels = _taxonomyLabels(taxonomies);
                            final allowed =
                                _controller.selectedProfileTypeStreamValue.value;
                            final allowedTaxonomies =
                                _profileTypeDefinition(allowed)
                                        ?.allowedTaxonomies ??
                                    const [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Taxonomias',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                if (isLoading) const LinearProgressIndicator(),
                                if (taxonomyError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      taxonomyError,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                                for (final taxonomy in allowedTaxonomies) ...[
                                  Text(
                                    labels[taxonomy] ?? taxonomy,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildTaxonomyChips(
                                    taxonomySlug: taxonomy,
                                    terms:
                                        termsByTaxonomy[taxonomy] ?? const [],
                                    selected:
                                        selectedTerms[taxonomy] ?? const {},
                                  ),
                                  const SizedBox(height: 12),
                                ],
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
          },
        ),
      ),
    );
  }

  Widget _buildTaxonomyChips({
    required String taxonomySlug,
    required List<TenantAdminTaxonomyTermDefinition> terms,
    required Set<String> selected,
  }) {
    if (terms.isEmpty) {
      return const Text('Nenhum termo cadastrado.');
    }
    return Wrap(
      spacing: 8,
      children: terms
          .map(
            (term) => FilterChip(
              label: Text(term.name),
              selected: selected.contains(term.slug),
              onSelected: (enabled) {
                _controller.updateTaxonomySelection(
                  taxonomySlug: taxonomySlug,
                  termSlug: term.slug,
                  selected: enabled,
                );
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Localizacao',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
              validator: _validateLatitude,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.longitudeController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
              validator: _validateLongitude,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Selecionar no mapa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.submitLoadingStreamValue,
      builder: (context, isLoading) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _controller.submitCreate,
            child: Text(isLoading ? 'Salvando...' : 'Salvar ativo'),
          ),
        );
      },
    );
  }
}
