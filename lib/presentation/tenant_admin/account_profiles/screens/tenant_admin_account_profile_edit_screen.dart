import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
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
  TenantAdminAccountProfile? _activeProfile;
  String? _syncedProfileId;
  bool _initialTaxonomiesSynced = false;
  String? _lastAvatarPreloadUrl;
  String? _lastCoverPreloadUrl;

  @override
  void initState() {
    super.initState();
    _controller.bindEditFlow();
    _controller.loadTaxonomies().whenComplete(
        () => _controller.loadEditProfile(widget.accountProfileId));
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

  bool _hasContent(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasContent ?? false;
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

  List<TenantAdminTaxonomyDefinition> _allowedTaxonomyDefinitions(
    String? selectedType,
  ) {
    final allowed = _allowedTaxonomies(selectedType).toSet();
    return _controller.taxonomiesStreamValue.value
        .where((taxonomy) =>
            taxonomy.appliesToTarget('account_profile') &&
            allowed.contains(taxonomy.slug))
        .toList(growable: false);
  }

  void _syncTaxonomySelection({
    required List<TenantAdminTaxonomyDefinition> allowed,
    required List<TenantAdminTaxonomyTerm> terms,
  }) {
    final slugs = allowed.map((taxonomy) => taxonomy.slug).toList();
    _controller.ensureTaxonomySelectionKeys(slugs);
    _controller.setTaxonomySelectionFromTerms(terms);
    _controller.loadTermsForTaxonomies(slugs);
  }

  void _handleEditStateChange(TenantAdminAccountProfileEditDraft state) {
    final profile = _controller.accountProfileStreamValue.value;
    if (profile == null) return;
    _activeProfile = profile;
    if (_syncedProfileId != profile.id) {
      _syncedProfileId = profile.id;
      _initialTaxonomiesSynced = false;
      _syncFormControllers(profile);
      _attemptTaxonomySync(profile: profile);
    }
    _maybePreloadRemoteImages(state);
  }

  void _syncFormControllers(TenantAdminAccountProfile profile) {
    _controller.slugController.text = profile.slug ?? '';
    _controller.displayNameController.text = profile.displayName;
    _controller.bioController.text = profile.bio ?? '';
    _controller.contentController.text = profile.content ?? '';
    if (profile.location == null) {
      _controller.latitudeController.clear();
      _controller.longitudeController.clear();
      return;
    }
    _controller.latitudeController.text =
        profile.location!.latitude.toStringAsFixed(6);
    _controller.longitudeController.text =
        profile.location!.longitude.toStringAsFixed(6);
  }

  void _attemptTaxonomySync({
    TenantAdminAccountProfile? profile,
  }) {
    if (_initialTaxonomiesSynced) return;
    final currentProfile = profile ?? _activeProfile;
    if (currentProfile == null) return;
    final selectedType =
        _controller.editStateStreamValue.value.selectedProfileType;
    if (selectedType == null || selectedType.isEmpty) return;
    if (!_hasTaxonomies(selectedType)) {
      _controller.resetTaxonomySelection();
      _initialTaxonomiesSynced = true;
      return;
    }
    final allowed = _allowedTaxonomyDefinitions(selectedType);
    if (allowed.isEmpty) return;
    _syncTaxonomySelection(
      allowed: allowed,
      terms: currentProfile.taxonomyTerms,
    );
    _initialTaxonomiesSynced = true;
  }

  void _maybePreloadRemoteImages(TenantAdminAccountProfileEditDraft state) {
    final avatarUrl = state.avatarRemoteUrl;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        state.avatarFile != null &&
        !state.avatarRemoteReady &&
        _lastAvatarPreloadUrl != avatarUrl) {
      _lastAvatarPreloadUrl = avatarUrl;
      _preloadRemoteImage(url: avatarUrl, isAvatar: true);
    }
    final coverUrl = state.coverRemoteUrl;
    if (coverUrl != null &&
        coverUrl.isNotEmpty &&
        state.coverFile != null &&
        !state.coverRemoteReady &&
        _lastCoverPreloadUrl != coverUrl) {
      _lastCoverPreloadUrl = coverUrl;
      _preloadRemoteImage(url: coverUrl, isAvatar: false);
    }
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms(String? selectedType) {
    if (!_hasTaxonomies(selectedType)) {
      return const [];
    }
    final terms = <TenantAdminTaxonomyTerm>[];
    final selections = _controller.taxonomySelectionStreamValue.value;
    for (final entry in selections.entries) {
      for (final value in entry.value) {
        terms.add(TenantAdminTaxonomyTerm(type: entry.key, value: value));
      }
    }
    return terms;
  }

  Map<String, Set<String>> _cloneTaxonomySelection(
    Map<String, Set<String>> source,
  ) {
    final next = <String, Set<String>>{};
    for (final entry in source.entries) {
      next[entry.key] = Set<String>.from(entry.value);
    }
    return next;
  }

  Future<void> _toggleTaxonomyWithAutoSave({
    required String taxonomySlug,
    required String termSlug,
    required bool selected,
  }) async {
    final previous = _cloneTaxonomySelection(
      _controller.taxonomySelectionStreamValue.value,
    );
    _controller.updateTaxonomySelection(
      taxonomySlug: taxonomySlug,
      termSlug: termSlug,
      selected: selected,
    );
    final currentType =
        _controller.editStateStreamValue.value.selectedProfileType;
    final saved = await _controller.submitTaxonomySelectionUpdate(
      accountProfileId: widget.accountProfileId,
      taxonomyTerms: _buildTaxonomyTerms(currentType),
    );
    if (saved) {
      return;
    }
    _controller.taxonomySelectionStreamValue.addValue(previous);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Nao foi possivel salvar a taxonomia. Alteracao desfeita.'),
      ),
    );
  }

  String? _validateLatitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.longitudeController.text.trim();
    if (trimmed.isNotEmpty && tenantAdminParseLatitude(trimmed) == null) {
      return 'Latitude inválida.';
    }
    if (_requiresLocation(
            _controller.editStateStreamValue.value.selectedProfileType) &&
        trimmed.isEmpty &&
        other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    if (_requiresLocation(
            _controller.editStateStreamValue.value.selectedProfileType) &&
        trimmed.isEmpty &&
        other.isEmpty) {
      return 'Localização é obrigatória para este perfil.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.latitudeController.text.trim();
    if (trimmed.isNotEmpty && tenantAdminParseLongitude(trimmed) == null) {
      return 'Longitude inválida.';
    }
    if (_requiresLocation(
            _controller.editStateStreamValue.value.selectedProfileType) &&
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
    final lat = tenantAdminParseLatitude(latText);
    final lng = tenantAdminParseLongitude(lngText);
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
    final profile = _controller.accountProfileStreamValue.value;
    if (profile == null) {
      return;
    }
    final state = _controller.editStateStreamValue.value;
    final avatarUpload = _hasAvatar(state.selectedProfileType)
        ? await _buildUpload(state.avatarFile)
        : null;
    final coverUpload = _hasCover(state.selectedProfileType)
        ? await _buildUpload(state.coverFile)
        : null;
    _controller.submitAutoSaveImages(
      accountProfileId: profile.id,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
      avatarUrl:
          _hasAvatar(state.selectedProfileType) ? state.avatarRemoteUrl : null,
      coverUrl:
          _hasCover(state.selectedProfileType) ? state.coverRemoteUrl : null,
    );
  }

  Future<void> _pickImageFromDevice({required bool isAvatar}) async {
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

  Future<String?> _promptWebImageUrl({
    required String title,
    required String initialValue,
  }) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: 'URL da imagem',
      initialValue: initialValue,
      helperText: 'Use URL completa (http/https).',
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'URL obrigatoria.';
        }
        final uri = Uri.tryParse(trimmed);
        final hasScheme = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!hasScheme) {
          return 'URL invalida.';
        }
        return null;
      },
    );
    return result?.value.trim();
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: isAvatar ? 'Adicionar avatar' : 'Adicionar capa',
    );
    if (source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _pickImageFromDevice(isAvatar: isAvatar);
      return;
    }
    final state = _controller.editStateStreamValue.value;
    final initialUrl =
        isAvatar ? (state.avatarRemoteUrl ?? '') : (state.coverRemoteUrl ?? '');
    final url = await _promptWebImageUrl(
      title: isAvatar ? 'URL do avatar' : 'URL da capa',
      initialValue: initialUrl,
    );
    if (url == null || !mounted) {
      return;
    }
    if (isAvatar) {
      _controller.updateAvatarRemoteUrl(url);
    } else {
      _controller.updateCoverRemoteUrl(url);
    }
    await _autoSaveImages();
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.updateAvatarFile(null);
      _controller.updateAvatarRemoteUrl(null);
      _controller.updateAvatarRemoteError(false);
    } else {
      _controller.updateCoverFile(null);
      _controller.updateCoverRemoteUrl(null);
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
    return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
      streamValue: _controller.taxonomiesStreamValue,
      builder: (context, _) {
        _attemptTaxonomySync();
        return StreamValueBuilder<String?>(
          streamValue: _controller.editSuccessMessageStreamValue,
          builder: (context, successMessage) {
            _handleEditSuccessMessage(successMessage);
            return StreamValueBuilder<String?>(
              streamValue: _controller.editErrorMessageStreamValue,
              builder: (context, errorMessage) {
                _handleEditErrorMessage(errorMessage);
                return StreamValueBuilder<String?>(
                  streamValue: _controller.editLoadErrorStreamValue,
                  builder: (context, loadError) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.editLoadingStreamValue,
                      builder: (context, isLoading) {
                        return StreamValueBuilder<TenantAdminAccountProfile?>(
                          streamValue: _controller.accountProfileStreamValue,
                          builder: (context, profile) {
                            return StreamValueBuilder<
                                TenantAdminAccountProfileEditDraft>(
                              streamValue: _controller.editStateStreamValue,
                              builder: (context, state) {
                                _handleEditStateChange(state);
                                _attemptTaxonomySync(profile: profile);
                                final requiresLocation = _requiresLocation(
                                    state.selectedProfileType);
                                final hasMedia =
                                    _hasAvatar(state.selectedProfileType) ||
                                        _hasCover(state.selectedProfileType);
                                final hasContent =
                                    _hasBio(state.selectedProfileType) ||
                                        _hasContent(
                                          state.selectedProfileType,
                                        ) ||
                                        _hasTaxonomies(
                                          state.selectedProfileType,
                                        );

                                if (loadError != null) {
                                  return TenantAdminFormScaffold(
                                    title: 'Editar Perfil',
                                    child: TenantAdminErrorBanner(
                                      rawError: loadError,
                                      fallbackMessage:
                                          'Não foi possível carregar os dados do perfil.',
                                      onRetry: () =>
                                          _controller.loadEditProfile(
                                        widget.accountProfileId,
                                      ),
                                    ),
                                  );
                                }

                                if (profile == null && isLoading) {
                                  return TenantAdminFormScaffold(
                                    title: 'Editar Perfil',
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                return TenantAdminFormScaffold(
                                  title: 'Editar Perfil',
                                  child: SingleChildScrollView(
                                    child: Form(
                                      key: _controller.editFormKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isLoading)
                                            const LinearProgressIndicator(),
                                          if (isLoading)
                                            const SizedBox(height: 12),
                                          _buildProfileSection(context, state),
                                          if (hasMedia) ...[
                                            const SizedBox(height: 16),
                                            _buildMediaSection(context, state),
                                          ],
                                          if (hasContent) ...[
                                            const SizedBox(height: 16),
                                            _buildContentSection(
                                                context, state),
                                          ],
                                          if (requiresLocation) ...[
                                            const SizedBox(height: 16),
                                            _buildLocationSection(context),
                                          ],
                                          const SizedBox(height: 24),
                                          TenantAdminPrimaryFormAction(
                                            label: 'Salvar alteracoes',
                                            icon: Icons.save_outlined,
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                                    final form = _controller
                                                        .editFormKey
                                                        .currentState;
                                                    if (form == null ||
                                                        !form.validate()) {
                                                      return;
                                                    }
                                                    final selectedType = state
                                                        .selectedProfileType;
                                                    if (selectedType == null) {
                                                      _controller
                                                          .reportEditErrorMessage(
                                                        'Selecione o tipo de perfil.',
                                                      );
                                                      return;
                                                    }
                                                    final avatarUpload =
                                                        _hasAvatar(selectedType)
                                                            ? await _buildUpload(
                                                                state
                                                                    .avatarFile,
                                                              )
                                                            : null;
                                                    final coverUpload =
                                                        _hasCover(selectedType)
                                                            ? await _buildUpload(
                                                                state.coverFile,
                                                              )
                                                            : null;
                                                    _controller
                                                        .submitUpdateProfile(
                                                      accountProfileId: widget
                                                          .accountProfileId,
                                                      profileType: selectedType,
                                                      slug: _controller
                                                          .slugController.text
                                                          .trim(),
                                                      displayName: _controller
                                                          .displayNameController
                                                          .text
                                                          .trim(),
                                                      bio: _hasBio(selectedType)
                                                          ? _controller
                                                              .bioController
                                                              .text
                                                              .trim()
                                                          : null,
                                                      content: _hasContent(
                                                              selectedType)
                                                          ? _controller
                                                              .contentController
                                                              .text
                                                              .trim()
                                                          : null,
                                                      taxonomyTerms: _hasTaxonomies(
                                                              selectedType)
                                                          ? _buildTaxonomyTerms(
                                                              selectedType,
                                                            )
                                                          : null,
                                                      location: requiresLocation
                                                          ? _currentLocation()
                                                          : null,
                                                      avatarUpload:
                                                          avatarUpload,
                                                      coverUpload: coverUpload,
                                                      avatarUrl: _hasAvatar(
                                                              selectedType)
                                                          ? state
                                                              .avatarRemoteUrl
                                                          : null,
                                                      coverUrl: _hasCover(
                                                              selectedType)
                                                          ? state.coverRemoteUrl
                                                          : null,
                                                    );
                                                  },
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
                      },
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
    TenantAdminAccountProfileEditDraft state,
  ) {
    return TenantAdminFormSectionCard(
      title: 'Dados do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamValueBuilder(
            streamValue: _controller.profileTypesStreamValue,
            builder: (context, types) {
              final uniqueTypes = _uniqueProfileTypes(types);
              final hasSelected = uniqueTypes.any(
                  (definition) => definition.type == state.selectedProfileType);
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
                  if (!_hasContent(value)) {
                    _controller.contentController.clear();
                  }
                  if (!_hasTaxonomies(value)) {
                    _controller.resetTaxonomySelection();
                  }
                  _initialTaxonomiesSynced = true;
                  _syncTaxonomySelection(
                    allowed: _allowedTaxonomyDefinitions(value),
                    terms: const [],
                  );
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await context.router.push(
                  const TenantAdminProfileTypeCreateRoute(),
                );
                if (!mounted) {
                  return;
                }
                await _controller.loadProfileTypes();
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar tipo de perfil'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.slugController,
            decoration: const InputDecoration(labelText: 'Slug'),
            keyboardType: TextInputType.visiblePassword,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: tenantAdminSlugInputFormatters,
            textInputAction: TextInputAction.next,
            validator: (value) => tenantAdminValidateRequiredSlug(
              value,
              requiredMessage: 'Slug e obrigatorio.',
              invalidMessage:
                  'Slug invalido. Use letras minusculas, numeros, - ou _.',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.displayNameController,
            decoration: const InputDecoration(labelText: 'Nome de exibicao'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome de exibicao e obrigatorio.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    TenantAdminAccountProfileEditDraft state,
  ) {
    final hasBio = _hasBio(state.selectedProfileType);
    final hasContent = _hasContent(state.selectedProfileType);
    final allowedDefinitions =
        _allowedTaxonomyDefinitions(state.selectedProfileType);
    return TenantAdminFormSectionCard(
      title: 'Conteudo do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBio) ...[
            TenantAdminRichTextEditor(
              controller: _controller.bioController,
              label: 'Bio',
              placeholder: 'Edite a bio do perfil',
              minHeight: 160,
            ),
          ],
          if (hasContent) ...[
            if (hasBio) const SizedBox(height: 12),
            TenantAdminRichTextEditor(
              controller: _controller.contentController,
              label: 'Conteudo',
              placeholder: 'Edite o conteudo estendido do perfil',
              minHeight: 220,
            ),
          ],
          if (_hasTaxonomies(state.selectedProfileType)) ...[
            if (hasBio || hasContent) const SizedBox(height: 12),
            Text(
              'Taxonomias',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            StreamValueBuilder<bool>(
              streamValue: _controller.taxonomyAutosavingStreamValue,
              builder: (context, isTaxonomyAutosaving) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTaxonomyAutosaving)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    StreamValueBuilder(
                      streamValue: _controller.taxonomySelectionStreamValue,
                      builder: (context, selections) {
                        return StreamValueBuilder(
                          streamValue: _controller.taxonomyTermsStreamValue,
                          builder: (context, termsByTaxonomy) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final taxonomy in allowedDefinitions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(taxonomy.name),
                                        const SizedBox(height: 8),
                                        if ((termsByTaxonomy[taxonomy.slug] ??
                                                const [])
                                            .isEmpty)
                                          const Text('Sem termos cadastrados.')
                                        else
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: (termsByTaxonomy[
                                                        taxonomy.slug] ??
                                                    const [])
                                                .map(
                                                  (term) => FilterChip(
                                                    label: Text(term.name),
                                                    selected: selections[
                                                                taxonomy.slug]
                                                            ?.contains(
                                                                term.slug) ??
                                                        false,
                                                    onSelected: (selected) {
                                                      _toggleTaxonomyWithAutoSave(
                                                        taxonomySlug:
                                                            taxonomy.slug,
                                                        termSlug: term.slug,
                                                        selected: selected,
                                                      );
                                                    },
                                                  ),
                                                )
                                                .toList(growable: false),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaSection(
    BuildContext context,
    TenantAdminAccountProfileEditDraft state,
  ) {
    final avatarUrl = state.avatarRemoteUrl;
    final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final coverUrl = state.coverRemoteUrl;
    final hasCoverUrl = coverUrl != null && coverUrl.isNotEmpty;
    final hasAvatar = _hasAvatar(state.selectedProfileType);
    final hasCover = _hasCover(state.selectedProfileType);

    return TenantAdminFormSectionCard(
      title: 'Imagens do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            color: Theme.of(context).colorScheme.errorContainer,
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: const Icon(Icons.person_outline),
                        );
                      },
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
                            (hasAvatarUrl
                                ? avatarUrl
                                : 'Nenhuma imagem selecionada'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _pickImage(isAvatar: true),
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Adicionar avatar'),
                          ),
                          const SizedBox(width: 8),
                          if (state.avatarFile != null || hasAvatarUrl)
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
                        color: Theme.of(context).colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image_outlined),
                    );
                  },
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Adicionar capa'),
                ),
                const SizedBox(width: 8),
                if (state.coverFile != null || hasCoverUrl)
                  TextButton(
                    onPressed: () => _clearImage(isAvatar: false),
                    child: const Text('Remover'),
                  ),
              ],
            ),
          ],
        ],
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
    return TenantAdminFormSectionCard(
      title: 'Localizacao',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller.latitudeController,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            inputFormatters: tenantAdminCoordinateInputFormatters,
            textInputAction: TextInputAction.next,
            validator: _validateLatitude,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.longitudeController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            inputFormatters: tenantAdminCoordinateInputFormatters,
            textInputAction: TextInputAction.done,
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
    );
  }
}
