import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileEditScreen extends StatefulWidget {
  const TenantAdminAccountProfileEditScreen({
    super.key,
    required this.accountProfileId,
  });

  final String accountProfileId;

  @override
  State<TenantAdminAccountProfileEditScreen> createState() =>
      _TenantAdminAccountProfileEditScreenState();
}

class _TenantAdminAccountProfileEditScreenState
    extends State<TenantAdminAccountProfileEditScreen> {
  final TenantAdminAccountProfilesController _controller =
      GetIt.I.get<TenantAdminAccountProfilesController>();

  @override
  void initState() {
    super.initState();
    _controller.bindEditFlow();
    _controller.loadEditProfile(widget.accountProfileId);
  }

  @override
  void dispose() {
    _controller.resetFormControllers();
    _controller.resetEditState();
    super.dispose();
  }

  TenantAdminProfileTypeDefinition? _selectedProfileTypeDefinition(
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

  List<TenantAdminProfileTypeDefinition> _uniqueProfileTypes(
    List<TenantAdminProfileTypeDefinition> types,
  ) {
    final seen = <String, TenantAdminProfileTypeDefinition>{};
    for (final definition in types) {
      seen.putIfAbsent(definition.type, () => definition);
    }
    return seen.values.toList(growable: false);
  }

  bool _requiresLocation(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.isPoiEnabled ?? false;
  }

  bool _hasBio(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasBio ?? false;
  }

  bool _hasTaxonomies(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasTaxonomies ?? false;
  }

  bool _hasAvatar(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasAvatar ?? false;
  }

  bool _hasCover(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasCover ?? false;
  }

  List<String> _allowedTaxonomies(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.allowedTaxonomies ?? const [];
  }

  void _syncTaxonomyControllers({
    required List<String> allowedTaxonomies,
    required List<TenantAdminTaxonomyTerm> terms,
  }) {
    final allowed = allowedTaxonomies.toSet();
    final existingKeys = _controller.taxonomyControllers.keys.toList();
    for (final key in existingKeys) {
      if (allowed.contains(key)) continue;
      _controller.removeTaxonomyController(key);
    }
    for (final taxonomy in allowed) {
      final values = terms
          .where((term) => term.type == taxonomy)
          .map((term) => term.value)
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
      _controller.getOrCreateTaxonomyController(
        taxonomy,
        initialText: values.join(', '),
      );
    }
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms(String? selectedType) {
    if (!_hasTaxonomies(selectedType)) {
      return const [];
    }
    final terms = <TenantAdminTaxonomyTerm>[];
    for (final entry in _controller.taxonomyControllers.entries) {
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;
      final values = raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty);
      for (final value in values) {
        terms.add(TenantAdminTaxonomyTerm(type: entry.key, value: value));
      }
    }
    return terms;
  }

  String? _validateLatitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.longitudeController.text.trim();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Latitude inválida.';
    }
    if (_requiresLocation(_controller.editStateStreamValue.value.selectedProfileType) &&
        trimmed.isEmpty &&
        other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    if (_requiresLocation(_controller.editStateStreamValue.value.selectedProfileType) &&
        trimmed.isEmpty &&
        other.isEmpty) {
      return 'Localização é obrigatória para este perfil.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.latitudeController.text.trim();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Longitude inválida.';
    }
    if (_requiresLocation(_controller.editStateStreamValue.value.selectedProfileType) &&
        trimmed.isEmpty &&
        other.isNotEmpty) {
      return 'Longitude é obrigatória.';
    }
    return null;
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

  Future<void> _openMapPicker() async {
    final currentLocation = _currentLocation();
    context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
      ),
    );
  }

  Future<void> _autoSaveImages() async {
    final profile = _controller.editStateStreamValue.value.profile;
    if (profile == null) {
      return;
    }
    final state = _controller.editStateStreamValue.value;
    final avatarUpload =
        _hasAvatar(state.selectedProfileType) ? await _buildUpload(state.avatarFile) : null;
    final coverUpload =
        _hasCover(state.selectedProfileType) ? await _buildUpload(state.coverFile) : null;
    _controller.submitAutoSaveImages(
      accountProfileId: profile.id,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selected == null) {
      return;
    }
    final lowerName = selected.name.toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowed.any(lowerName.endsWith)) {
      _controller.reportEditErrorMessage(
        'Formato de imagem invalido. Use JPG, PNG ou WEBP.',
      );
      return;
    }
    final size = await selected.length();
    const maxBytes = 5 * 1024 * 1024;
    if (size > maxBytes) {
      _controller.reportEditErrorMessage(
        'Imagem muito grande. Maximo 5MB.',
      );
      return;
    }
    if (isAvatar) {
      _controller.updateAvatarFile(selected);
    } else {
      _controller.updateCoverFile(selected);
    }
    await _autoSaveImages();
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.updateAvatarFile(null);
      _controller.updateAvatarRemoteError(false);
    } else {
      _controller.updateCoverFile(null);
      _controller.updateCoverRemoteError(false);
    }
  }

  Future<TenantAdminMediaUpload?> _buildUpload(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return TenantAdminMediaUpload(
      bytes: bytes,
      fileName: file.name,
    );
  }

  void _preloadRemoteImage({
    required String url,
    required bool isAvatar,
  }) {
    final state = _controller.editStateStreamValue.value;
    if (isAvatar) {
      if (state.avatarPreloadUrl == url) return;
      _controller.updateAvatarPreloadUrl(url);
    } else {
      if (state.coverPreloadUrl == url) return;
      _controller.updateCoverPreloadUrl(url);
    }

    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        if (isAvatar) {
          _controller.updateAvatarRemoteError(false);
          _controller.updateAvatarFile(null);
          _controller.markAvatarRemoteReady(true);
        } else {
          _controller.updateCoverRemoteError(false);
          _controller.updateCoverFile(null);
          _controller.markCoverRemoteReady(true);
        }
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (isAvatar) {
          _controller.updateAvatarRemoteError(true);
        } else {
          _controller.updateCoverRemoteError(true);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.editSuccessMessageStreamValue,
      builder: (context, successMessage) {
        _handleEditSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.editErrorMessageStreamValue,
          builder: (context, errorMessage) {
            _handleEditErrorMessage(errorMessage);
            return StreamValueBuilder<TenantAdminAccountProfileEditState>(
              streamValue: _controller.editStateStreamValue,
              builder: (context, state) {
                final requiresLocation =
                    _requiresLocation(state.selectedProfileType);
                final hasMedia = _hasAvatar(state.selectedProfileType) ||
                    _hasCover(state.selectedProfileType);
                final hasContent = _hasBio(state.selectedProfileType) ||
                    _hasTaxonomies(state.selectedProfileType);
                final profile = state.profile;

                if (state.errorMessage != null) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Editar Perfil'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.router.maybePop(),
                        tooltip: 'Voltar',
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => _controller.loadEditProfile(
                                  widget.accountProfileId,
                                ),
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (profile == null && state.isLoading) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Editar Perfil'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.router.maybePop(),
                        tooltip: 'Voltar',
                      ),
                    ),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (profile != null) {
                  if (_controller.displayNameController.text !=
                      profile.displayName) {
                    _controller.displayNameController.text =
                        profile.displayName;
                  }
                  if (_controller.bioController.text != (profile.bio ?? '')) {
                    _controller.bioController.text = profile.bio ?? '';
                  }
                  if (profile.location != null) {
                    final lat = profile.location!.latitude.toStringAsFixed(6);
                    final lng = profile.location!.longitude.toStringAsFixed(6);
                    if (_controller.latitudeController.text != lat) {
                      _controller.latitudeController.text = lat;
                    }
                    if (_controller.longitudeController.text != lng) {
                      _controller.longitudeController.text = lng;
                    }
                  }
                  _syncTaxonomyControllers(
                    allowedTaxonomies:
                        _allowedTaxonomies(state.selectedProfileType),
                    terms: profile.taxonomyTerms,
                  );
                }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar Perfil'),
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
                key: _controller.editFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.isLoading) const LinearProgressIndicator(),
                    if (state.isLoading) const SizedBox(height: 12),
                    _buildProfileSection(context, state),
                    if (hasContent) ...[
                      const SizedBox(height: 16),
                      _buildContentSection(context, state),
                    ],
                    if (hasMedia) ...[
                      const SizedBox(height: 16),
                      _buildMediaSection(context, state),
                    ],
                    if (requiresLocation) ...[
                      const SizedBox(height: 16),
                      _buildLocationSection(context),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                final form =
                                    _controller.editFormKey.currentState;
                                if (form == null || !form.validate()) {
                                  return;
                                }
                                final selectedType =
                                    state.selectedProfileType;
                                if (selectedType == null) {
                                  _controller.reportEditErrorMessage(
                                    'Selecione o tipo de perfil.',
                                  );
                                  return;
                                }
                                final avatarUpload =
                                    _hasAvatar(selectedType)
                                        ? await _buildUpload(state.avatarFile)
                                        : null;
                                final coverUpload =
                                    _hasCover(selectedType)
                                        ? await _buildUpload(state.coverFile)
                                        : null;
                                _controller.submitUpdateProfile(
                                  accountProfileId: widget.accountProfileId,
                                  profileType: selectedType,
                                  displayName:
                                      _controller.displayNameController.text.trim(),
                                  bio: _hasBio(selectedType)
                                      ? _controller.bioController.text.trim()
                                      : null,
                                  taxonomyTerms: _hasTaxonomies(selectedType)
                                      ? _buildTaxonomyTerms(
                                          selectedType)
                                      : null,
                                  location: requiresLocation
                                      ? _currentLocation()
                                      : null,
                                  avatarUpload: avatarUpload,
                                  coverUpload: coverUpload,
                                );
                              },
                        child: const Text('Salvar alteracoes'),
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
      },
    );
  }

  void _handleEditSuccessMessage(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearEditSuccessMessage();
    });
  }

  void _handleEditErrorMessage(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearEditErrorMessage();
    });
  }

  Widget _buildProfileSection(
    BuildContext context,
    TenantAdminAccountProfileEditState state,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados do perfil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamValueBuilder(
              streamValue: _controller.profileTypesStreamValue,
              builder: (context, types) {
                final uniqueTypes = _uniqueProfileTypes(types);
                final hasSelected = uniqueTypes
                    .any((definition) => definition.type == state.selectedProfileType);
                final effectiveSelected =
                    hasSelected ? state.selectedProfileType : null;
                return DropdownButtonFormField<String>(
                  key: ValueKey(effectiveSelected),
                  initialValue: effectiveSelected,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de perfil',
                  ),
                  items: uniqueTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type.type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    _controller.updateSelectedProfileType(value);
                    if (!_requiresLocation(value)) {
                      _controller.latitudeController.clear();
                      _controller.longitudeController.clear();
                    }
                    if (!_hasBio(value)) {
                      _controller.bioController.clear();
                    }
                    if (!_hasTaxonomies(value)) {
                      for (final controller in _controller.taxonomyControllers.values) {
                        controller.clear();
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tipo de perfil e obrigatorio.';
                    }
                    return null;
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
                  return 'Nome de exibicao e obrigatorio.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    TenantAdminAccountProfileEditState state,
  ) {
    final hasBio = _hasBio(state.selectedProfileType);
    final allowedTaxonomies = _allowedTaxonomies(state.selectedProfileType);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conteudo do perfil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasBio) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller.bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 4,
                minLines: 2,
              ),
            ],
            if (_hasTaxonomies(state.selectedProfileType)) ...[
              const SizedBox(height: 12),
              Text(
                'Taxonomias',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final taxonomy in allowedTaxonomies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controller.taxonomyControllers[taxonomy],
                    decoration: InputDecoration(
                      labelText: taxonomy,
                      helperText: 'Separe por virgula',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(
    BuildContext context,
    TenantAdminAccountProfileEditState state,
  ) {
    final avatarUrl = state.avatarRemoteUrl;
    final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final coverUrl = state.coverRemoteUrl;
    final hasCoverUrl = coverUrl != null && coverUrl.isNotEmpty;
    final hasAvatar = _hasAvatar(state.selectedProfileType);
    final hasCover = _hasCover(state.selectedProfileType);

    if (state.avatarFile != null && hasAvatarUrl && !state.avatarRemoteReady) {
      _preloadRemoteImage(url: avatarUrl, isAvatar: true);
    }
    if (state.coverFile != null && hasCoverUrl && !state.coverRemoteReady) {
      _preloadRemoteImage(url: coverUrl, isAvatar: false);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imagens do perfil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (hasAvatar) ...[
              Row(
                children: [
                  if (state.avatarFile != null)
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.file(
                            File(state.avatarFile!.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (state.avatarRemoteError)
                          Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color:
                                  Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                      ],
                    )
                  else if (hasAvatarUrl)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.network(
                        avatarUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          if (!state.avatarRemoteError) {
                            _controller.updateAvatarRemoteError(true);
                          }
                          return _buildAvatarError(context);
                        },
                      ),
                    )
                  else if (state.avatarRemoteError)
                    _buildAvatarError(context)
                  else
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Icon(Icons.person_outline),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.avatarFile?.name ??
                              (state.profile?.avatarUrl?.isNotEmpty ?? false
                                  ? 'Imagem atual'
                                  : 'Nenhuma imagem selecionada'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _pickImage(isAvatar: true),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Selecionar'),
                            ),
                            const SizedBox(width: 8),
                            if (state.avatarFile != null)
                              TextButton(
                                onPressed: () => _clearImage(isAvatar: true),
                                child: const Text('Remover'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (hasAvatar && hasCover) const SizedBox(height: 16),
            if (hasCover) ...[
              if (state.coverFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(state.coverFile!.path),
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (state.coverRemoteError)
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                  ],
                )
              else if (hasCoverUrl)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    coverUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      if (!state.coverRemoteError) {
                        _controller.updateCoverRemoteError(true);
                      }
                      return _buildCoverError(context);
                    },
                  ),
                )
              else if (state.coverRemoteError)
                _buildCoverError(context)
              else
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _pickImage(isAvatar: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Selecionar capa'),
                  ),
                  const SizedBox(width: 8),
                  if (state.coverFile != null)
                    TextButton(
                      onPressed: () => _clearImage(isAvatar: false),
                      child: const Text('Remover'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarError(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }

  Widget _buildCoverError(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 32,
        ),
      ),
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

}
