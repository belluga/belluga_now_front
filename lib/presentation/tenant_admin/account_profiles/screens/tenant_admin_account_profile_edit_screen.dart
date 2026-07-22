import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/rich_text/account_profile_rich_text_limits.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_update.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_account_profile_gallery_operations.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_gallery_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_canonical_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_contact_channels_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_nested_profile_groups_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileEditScreen extends StatefulWidget {
  const TenantAdminAccountProfileEditScreen({
    super.key,
    required this.accountSlug,
    required this.accountProfileId,
    this.initialProfile,
  });

  final String accountSlug;
  final String accountProfileId;
  final TenantAdminAccountProfile? initialProfile;

  @override
  State<TenantAdminAccountProfileEditScreen> createState() =>
      _TenantAdminAccountProfileEditScreenState();
}

class _TenantAdminAccountProfileEditScreenState
    extends State<TenantAdminAccountProfileEditScreen> {
  final TenantAdminAccountProfilesController _controller = GetIt.I
      .get<TenantAdminAccountProfilesController>();
  TenantAdminAccountProfile? _activeProfile;
  String? _syncedProfileId;
  bool _initialTaxonomiesSynced = false;
  String? _lastAvatarPreloadUrl;
  String? _lastCoverPreloadUrl;
  bool _routeParamNormalized = false;
  TenantAdminOwnershipState? _selectedOwnershipState;
  String? _syncedOwnershipAccountId;

  static const List<TenantAdminOwnershipState> _editableOwnershipStates =
      <TenantAdminOwnershipState>[
        TenantAdminOwnershipState.tenantOwned,
        TenantAdminOwnershipState.unmanaged,
      ];

  @override
  void initState() {
    super.initState();
    _controller.bindEditFlow();
    unawaited(_controller.loadAccountForEdit(_currentAccountSlugForRequests()));
    _controller.loadTaxonomies().whenComplete(
      () => _controller.loadEditProfile(
        _currentAccountProfileIdForRequests(),
        prefetchedProfile: widget.initialProfile,
      ),
    );
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

  bool _hasGallery(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasGallery ?? false;
  }

  bool _hasNestedProfileGroups(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasNestedProfileGroups ?? false;
  }

  bool _hasContactChannels(String? selectedType) {
    final definition = _selectedProfileTypeDefinition(selectedType);
    return definition?.capabilities.hasContactChannels ?? false;
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
        .where(
          (taxonomy) =>
              taxonomy.appliesToAccountProfile() &&
              allowed.contains(taxonomy.slug),
        )
        .toList(growable: false);
  }

  void _syncTaxonomySelection({
    required List<TenantAdminTaxonomyDefinition> allowed,
    required TenantAdminTaxonomyTerms terms,
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

  void _syncOwnershipSelection(TenantAdminOwnershipState? accountOwnership) {
    final accountId = _controller.accountStreamValue.value?.id;
    if (accountId == null || accountId.isEmpty) {
      return;
    }
    if (_syncedOwnershipAccountId == accountId) {
      return;
    }
    _syncedOwnershipAccountId = accountId;
    _selectedOwnershipState = accountOwnership;
  }

  bool _isResolvedSlug(String? value) {
    return _isResolvedPathParam(value);
  }

  bool _isResolvedPathParam(String? value) {
    if (value == null) {
      return false;
    }
    final trimmed = value.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith(':');
  }

  String _currentAccountProfileIdForRequests() {
    final routeId = widget.accountProfileId;
    if (_isResolvedPathParam(routeId)) {
      return routeId.trim();
    }

    final cached = _controller.accountProfileStreamValue.value?.id;
    if (_isResolvedPathParam(cached)) {
      return cached!.trim();
    }

    return routeId;
  }

  String _currentAccountSlugForRequests() {
    final routeSlug = widget.accountSlug;
    if (_isResolvedSlug(routeSlug)) {
      return routeSlug.trim();
    }
    final cachedSlug = _controller.accountStreamValue.value?.slug;
    if (_isResolvedSlug(cachedSlug)) {
      return cachedSlug!.trim();
    }
    return routeSlug;
  }

  bool _requiresPathNormalization() {
    return kIsWeb && context.router.currentPath.contains('/:');
  }

  void _normalizeRouteParamIfNeeded() {
    if (_routeParamNormalized || !mounted) {
      return;
    }
    final hasResolvedSlug = _isResolvedSlug(widget.accountSlug);
    final hasResolvedProfileId = _isResolvedPathParam(widget.accountProfileId);
    final needsPathNormalization = _requiresPathNormalization();
    if (!needsPathNormalization && hasResolvedSlug && hasResolvedProfileId) {
      _routeParamNormalized = true;
      return;
    }
    final resolvedSlug = hasResolvedSlug
        ? widget.accountSlug.trim()
        : _controller.accountStreamValue.value?.slug.trim();
    final resolvedProfileId = hasResolvedProfileId
        ? widget.accountProfileId.trim()
        : _controller.accountProfileStreamValue.value?.id.trim();
    if (!_isResolvedSlug(resolvedSlug) ||
        !_isResolvedPathParam(resolvedProfileId)) {
      return;
    }
    _routeParamNormalized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.router.replace(
        TenantAdminAccountProfileEditRoute(
          accountSlug: resolvedSlug!,
          accountProfileId: resolvedProfileId!,
        ),
      );
    });
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
    _controller.latitudeController.text = profile.location!.latitude
        .toStringAsFixed(6);
    _controller.longitudeController.text = profile.location!.longitude
        .toStringAsFixed(6);
  }

  void _attemptTaxonomySync({TenantAdminAccountProfile? profile}) {
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

  TenantAdminTaxonomyTerms _buildTaxonomyTerms(String? selectedType) {
    if (!_hasTaxonomies(selectedType)) {
      return const TenantAdminTaxonomyTerms.empty();
    }
    final terms = <TenantAdminTaxonomyTerm>[];
    final selections = _controller.taxonomySelectionStreamValue.value;
    for (final entry in selections.entries) {
      for (final value in entry.value) {
        terms.add(
          tenantAdminTaxonomyTermFromRaw(type: entry.key, value: value),
        );
      }
    }
    final taxonomyTerms = TenantAdminTaxonomyTerms();
    for (final term in terms) {
      taxonomyTerms.add(term);
    }
    return taxonomyTerms;
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
      accountProfileId: _currentAccountProfileIdForRequests(),
      profileType: currentType,
      taxonomyTerms: _buildTaxonomyTerms(currentType),
      bio: _hasBio(currentType) ? _controller.bioController.text.trim() : null,
      content: _hasContent(currentType)
          ? _controller.contentController.text.trim()
          : null,
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
        content: Text(
          'Nao foi possivel salvar a taxonomia. Alteracao desfeita.',
        ),
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
          _controller.editStateStreamValue.value.selectedProfileType,
        ) &&
        trimmed.isEmpty &&
        other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    if (_requiresLocation(
          _controller.editStateStreamValue.value.selectedProfileType,
        ) &&
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
          _controller.editStateStreamValue.value.selectedProfileType,
        ) &&
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
    return tenantAdminLocationFromRaw(latitude: lat, longitude: lng);
  }

  Future<void> _openMapPicker() async {
    final currentLocation = _currentLocation();
    context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
        backFallbackRoute: TenantAdminAccountProfileEditRoute(
          accountSlug: _currentAccountSlugForRequests(),
          accountProfileId: _currentAccountProfileIdForRequests(),
        ),
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
        ? await _controller.buildImageUpload(
            state.avatarFile,
            slot: TenantAdminImageSlot.avatar,
          )
        : null;
    final coverUpload = _hasCover(state.selectedProfileType)
        ? await _controller.buildImageUpload(
            state.coverFile,
            slot: TenantAdminImageSlot.accountProfileHeroCover,
          )
        : null;
    _controller.submitAutoSaveImages(
      accountProfileId: profile.id,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
      avatarUrl: null,
      coverUrl: null,
    );
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.clearAvatarSelection(markForRemoval: true);
      _controller.updateAvatarRemoteError(false);
    } else {
      _controller.clearCoverSelection(markForRemoval: true);
      _controller.updateCoverRemoteError(false);
    }
  }

  Future<String?> _promptGalleryWebImageUrl() async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'URL da foto da galeria',
      label: 'URL da imagem',
      initialValue: '',
      helperText: 'Use URL completa (http/https).',
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'URL obrigatória.';
        }
        final uri = Uri.tryParse(trimmed);
        final hasScheme =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!hasScheme) {
          return 'URL inválida.';
        }
        return null;
      },
    );
    return result?.value.trim();
  }

  Future<XFile?> _pickGalleryImage() async {
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: 'Adicionar foto da galeria',
    );
    if (!mounted || source == null) {
      return null;
    }

    try {
      XFile? sourceFile;
      if (source == TenantAdminImageSourceOption.device) {
        sourceFile = await _controller.pickImageFromDevice(
          slot: TenantAdminImageSlot.accountProfileGallery,
        );
      } else {
        final url = await _promptGalleryWebImageUrl();
        if (!mounted || url == null) {
          return null;
        }
        sourceFile = await _controller.fetchImageFromUrlForCrop(imageUrl: url);
      }

      if (!mounted || sourceFile == null) {
        return null;
      }

      return showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: TenantAdminImageSlot.accountProfileGallery,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, slot) =>
            _controller.prepareCroppedImage(croppedData, slot: slot),
      );
    } on TenantAdminImageIngestionException catch (error) {
      _controller.reportEditErrorMessage(error.message);
      return null;
    } catch (_) {
      _controller.reportEditErrorMessage(
        'Não foi possível preparar a foto da galeria.',
      );
      return null;
    }
  }

  Future<void> _addGalleryItem(String groupId) async {
    final file = await _pickGalleryImage();
    if (!mounted || file == null) {
      return;
    }
    _controller.addEditGalleryItem(groupId: groupId, uploadFile: file);
  }

  Future<void> _replaceGalleryItem(String groupId, String itemId) async {
    final file = await _pickGalleryImage();
    if (!mounted || file == null) {
      return;
    }
    _controller.replaceEditGalleryItemUpload(
      groupId: groupId,
      itemId: itemId,
      uploadFile: file,
    );
  }

  String? _validateGalleryState(TenantAdminAccountProfileEditDraft state) {
    final groups = state.galleryGroups;
    if (groups.length > TenantAdminAccountProfileGalleryOperations.maxGroups) {
      return 'Limite de grupos da galeria atingido.';
    }
    final totalItems =
        TenantAdminAccountProfileGalleryOperations.totalItemCount(groups);
    if (totalItems > TenantAdminAccountProfileGalleryOperations.maxItems) {
      return 'Limite total de fotos da galeria atingido.';
    }
    for (final group in groups) {
      if (group.subtitle.trim().isEmpty) {
        return 'Todos os grupos da galeria precisam de subtítulo.';
      }
      if (group.items.isEmpty) {
        return 'Cada grupo da galeria precisa ter ao menos uma foto.';
      }
    }
    return null;
  }

  Future<List<TenantAdminAccountProfileGalleryUpdateGroup>>
  _buildGalleryUpdateGroups(TenantAdminAccountProfileEditDraft state) async {
    final groups = <TenantAdminAccountProfileGalleryUpdateGroup>[];
    final orderedGroups = [...state.galleryGroups]
      ..sort((left, right) => left.order.compareTo(right.order));
    for (final group in orderedGroups) {
      final items = <TenantAdminAccountProfileGalleryUpdateItem>[];
      final orderedItems = [...group.items]
        ..sort((left, right) => left.order.compareTo(right.order));
      for (final item in orderedItems) {
        final upload = await _controller.buildImageUpload(
          item.uploadFile,
          slot: TenantAdminImageSlot.accountProfileGallery,
        );
        items.add(
          TenantAdminAccountProfileGalleryUpdateItem(
            itemIdValue: TenantAdminNestedProfileGroupTextValue(item.itemId),
            descriptionValue: TenantAdminOptionalTextValue()
              ..parse(
                item.description?.trim().isEmpty == true
                    ? null
                    : item.description?.trim(),
              ),
            orderValue: TenantAdminNestedProfileGroupOrderValue(item.order),
            upload: upload,
          ),
        );
      }
      groups.add(
        TenantAdminAccountProfileGalleryUpdateGroup(
          groupIdValue: TenantAdminNestedProfileGroupTextValue(group.groupId),
          subtitleValue: TenantAdminNestedProfileGroupTextValue(
            group.subtitle.trim(),
          ),
          orderValue: TenantAdminNestedProfileGroupOrderValue(group.order),
          items: items,
        ),
      );
    }
    return groups;
  }

  void _preloadRemoteImage({required String url, required bool isAvatar}) {
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
      (_, _) {
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
      onError: (_, _) {
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
                    _normalizeRouteParamIfNeeded();
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.editLoadingStreamValue,
                      builder: (context, isLoading) {
                        return StreamValueBuilder<TenantAdminAccountProfile?>(
                          streamValue: _controller.accountProfileStreamValue,
                          builder: (context, profile) {
                            return StreamValueBuilder<
                              TenantAdminAccountProfileEditDraft
                            >(
                              streamValue: _controller.editStateStreamValue,
                              builder: (context, state) {
                                _handleEditStateChange(state);
                                _attemptTaxonomySync(profile: profile);
                                final requiresLocation = _requiresLocation(
                                  state.selectedProfileType,
                                );
                                final hasMedia =
                                    _hasAvatar(state.selectedProfileType) ||
                                    _hasCover(state.selectedProfileType);
                                final hasContent =
                                    _hasBio(state.selectedProfileType) ||
                                    _hasContent(state.selectedProfileType) ||
                                    _hasTaxonomies(state.selectedProfileType);
                                final hasContactChannels = _hasContactChannels(
                                  state.selectedProfileType,
                                );
                                final hasNestedProfileGroups =
                                    _hasNestedProfileGroups(
                                      state.selectedProfileType,
                                    );
                                final hasGallery = _hasGallery(
                                  state.selectedProfileType,
                                );

                                if (loadError?.isNotEmpty ?? false) {
                                  return TenantAdminFormScaffold(
                                    closePolicy:
                                        buildTenantAdminCurrentRouteBackPolicy(
                                          context,
                                        ),
                                    title: 'Editar Perfil',
                                    child: TenantAdminErrorBanner(
                                      rawError: loadError ?? '',
                                      fallbackMessage:
                                          'Não foi possível carregar os dados do perfil.',
                                      onRetry: () => _controller.loadEditProfile(
                                        _currentAccountProfileIdForRequests(),
                                      ),
                                    ),
                                  );
                                }

                                if (profile is! TenantAdminAccountProfile &&
                                    isLoading) {
                                  return TenantAdminFormScaffold(
                                    closePolicy:
                                        buildTenantAdminCurrentRouteBackPolicy(
                                          context,
                                        ),
                                    title: 'Editar Perfil',
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                return TenantAdminFormScaffold(
                                  closePolicy:
                                      buildTenantAdminCurrentRouteBackPolicy(
                                        context,
                                      ),
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
                                          StreamValueBuilder<
                                            TenantAdminAccount?
                                          >(
                                            streamValue:
                                                _controller.accountStreamValue,
                                            builder: (context, account) {
                                              _syncOwnershipSelection(
                                                account?.ownershipState,
                                              );
                                              return _buildProfileSection(
                                                context,
                                                state,
                                                accountOwnership:
                                                    account?.ownershipState,
                                              );
                                            },
                                          ),
                                          if (hasMedia) ...[
                                            const SizedBox(height: 16),
                                            _buildMediaSection(context, state),
                                          ],
                                          if (hasGallery) ...[
                                            const SizedBox(height: 16),
                                            _buildGallerySection(state),
                                          ],
                                          if (hasContent) ...[
                                            _buildContentSection(
                                              context,
                                              state,
                                            ),
                                          ],
                                          if (hasContactChannels) ...[
                                            const SizedBox(height: 16),
                                            _buildContactSourceSection(
                                              context,
                                              state,
                                            ),
                                            const SizedBox(height: 16),
                                            _buildContactChannelsSection(
                                              context,
                                              state,
                                            ),
                                          ],
                                          if (requiresLocation) ...[
                                            const SizedBox(height: 16),
                                            _buildLocationSection(context),
                                          ],
                                          if (hasNestedProfileGroups) ...[
                                            const SizedBox(height: 16),
                                            TenantAdminNestedProfileGroupsEditor(
                                              keyPrefix: 'tenantAdminEdit',
                                              groups: state.nestedProfileGroups,
                                              candidatesStreamValue: _controller
                                                  .nestedProfileCandidatesStreamValue,
                                              profileTypes: _controller
                                                  .profileTypesStreamValue
                                                  .value,
                                              onSearchChanged: _controller
                                                  .searchNestedProfileCandidates,
                                              onLoadMore: _controller
                                                  .loadNextNestedProfileCandidatesPage,
                                              searchLoadingStreamValue: _controller
                                                  .nestedProfileSearchLoadingStreamValue,
                                              searchPageLoadingStreamValue:
                                                  _controller
                                                      .nestedProfileSearchPageLoadingStreamValue,
                                              searchHasMoreStreamValue: _controller
                                                  .nestedProfileSearchHasMoreStreamValue,
                                              addButtonKey: const Key(
                                                'tenantAdminEditAddNestedGroupButton',
                                              ),
                                              onAddGroup: _controller
                                                  .addEditNestedProfileGroup,
                                              onRenameGroup: _controller
                                                  .renameEditNestedProfileGroup,
                                              onMoveGroup: _controller
                                                  .moveEditNestedProfileGroup,
                                              onRemoveGroup: _controller
                                                  .removeEditNestedProfileGroup,
                                              onSelectionChanged:
                                                  (
                                                    groupId,
                                                    profileId,
                                                    selected,
                                                  ) {
                                                    _controller
                                                        .toggleEditNestedProfileGroupMember(
                                                          groupId: groupId,
                                                          profileId: profileId,
                                                          selected: selected,
                                                        );
                                                  },
                                            ),
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
                                                    final contactDraftError =
                                                        _controller
                                                            .validateEditContactDraft(
                                                              capabilityEnabled:
                                                                  hasContactChannels,
                                                            );
                                                    if (contactDraftError !=
                                                        null) {
                                                      _controller
                                                          .reportEditErrorMessage(
                                                            contactDraftError,
                                                          );
                                                      return;
                                                    }
                                                    final selectedContactSource =
                                                        _selectedEditContactSourceCandidate(
                                                          state,
                                                        );
                                                    if (hasContactChannels &&
                                                        state.contactMode ==
                                                            BellugaContactSourceMode
                                                                .mirroredAccountProfile &&
                                                        selectedContactSource ==
                                                            null) {
                                                      _controller
                                                          .reportEditErrorMessage(
                                                            'Selecione um perfil válido para espelhar o contato.',
                                                          );
                                                      return;
                                                    }
                                                    final contactBubbleValidationError =
                                                        _validateEditBubbleSelection(
                                                          state,
                                                          selectedContactSource,
                                                          capabilityEnabled:
                                                              hasContactChannels,
                                                        );
                                                    if (contactBubbleValidationError !=
                                                        null) {
                                                      _controller
                                                          .reportEditErrorMessage(
                                                            contactBubbleValidationError,
                                                          );
                                                      return;
                                                    }
                                                    final account = _controller
                                                        .accountStreamValue
                                                        .value;
                                                    if (account != null &&
                                                        _selectedOwnershipState !=
                                                            null &&
                                                        _selectedOwnershipState !=
                                                            account
                                                                .ownershipState) {
                                                      final updatedAccount =
                                                          await _controller
                                                              .updateAccount(
                                                                accountSlug:
                                                                    _currentAccountSlugForRequests(),
                                                                ownershipState:
                                                                    _selectedOwnershipState,
                                                              );
                                                      if (updatedAccount ==
                                                          null) {
                                                        return;
                                                      }
                                                      _selectedOwnershipState =
                                                          updatedAccount
                                                              .ownershipState;
                                                    }
                                                    final avatarUpload =
                                                        _hasAvatar(selectedType)
                                                        ? await _controller
                                                              .buildImageUpload(
                                                                state
                                                                    .avatarFile,
                                                                slot:
                                                                    TenantAdminImageSlot
                                                                        .avatar,
                                                              )
                                                        : null;
                                                    final coverUpload =
                                                        _hasCover(selectedType)
                                                        ? await _controller
                                                              .buildImageUpload(
                                                                state.coverFile,
                                                                slot:
                                                                    TenantAdminImageSlot
                                                                        .cover,
                                                              )
                                                        : null;
                                                    final galleryValidationError =
                                                        hasGallery
                                                        ? _validateGalleryState(
                                                            state,
                                                          )
                                                        : null;
                                                    if (galleryValidationError !=
                                                        null) {
                                                      _controller
                                                          .reportEditErrorMessage(
                                                            galleryValidationError,
                                                          );
                                                      return;
                                                    }
                                                    final galleryGroups =
                                                        hasGallery
                                                        ? await _buildGalleryUpdateGroups(
                                                            state,
                                                          )
                                                        : null;
                                                    final contactChannelDrafts =
                                                        _controller
                                                            .buildEditContactChannelDrafts(
                                                              capabilityEnabled:
                                                                  hasContactChannels,
                                                            );
                                                    _controller.submitUpdateProfile(
                                                      accountProfileId:
                                                          _currentAccountProfileIdForRequests(),
                                                      profileType: selectedType,
                                                      slug: _controller
                                                          .slugController
                                                          .text
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
                                                      content:
                                                          _hasContent(
                                                            selectedType,
                                                          )
                                                          ? _controller
                                                                .contentController
                                                                .text
                                                                .trim()
                                                          : null,
                                                      taxonomyTerms:
                                                          _hasTaxonomies(
                                                            selectedType,
                                                          )
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
                                                      avatarUrl: null,
                                                      coverUrl: null,
                                                      galleryGroups:
                                                          galleryGroups,
                                                      nestedProfileGroups:
                                                          _hasNestedProfileGroups(
                                                            selectedType,
                                                          )
                                                          ? state
                                                                .nestedProfileGroups
                                                          : null,
                                                      contactMode:
                                                          hasContactChannels
                                                          ? state.contactMode
                                                          : null,
                                                      contactSourceAccountProfileId:
                                                          hasContactChannels &&
                                                              state.contactMode ==
                                                                  BellugaContactSourceMode
                                                                      .mirroredAccountProfile
                                                          ? selectedContactSource
                                                                ?.id
                                                          : null,
                                                      contactChannelDrafts:
                                                          contactChannelDrafts,
                                                      bubbleSelection: _controller
                                                          .editBubbleSelection(
                                                            capabilityEnabled:
                                                                hasContactChannels,
                                                          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _controller.clearEditSuccessMessage();
    });
  }

  void _handleEditErrorMessage(String? message) {
    if (message == null || message.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _controller.clearEditErrorMessage();
    });
  }

  Widget _buildProfileSection(
    BuildContext context,
    TenantAdminAccountProfileEditDraft state, {
    required TenantAdminOwnershipState? accountOwnership,
  }) {
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
                (definition) => definition.type == state.selectedProfileType,
              );
              final effectiveSelected = hasSelected
                  ? state.selectedProfileType
                  : null;
              return DropdownButtonFormField<String>(
                key: ValueKey(effectiveSelected),
                initialValue: effectiveSelected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de perfil'),
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
                    terms: const TenantAdminTaxonomyTerms.empty(),
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
          DropdownButtonFormField<TenantAdminOwnershipState>(
            key: ValueKey(_selectedOwnershipState ?? accountOwnership),
            initialValue: _selectedOwnershipState ?? accountOwnership,
            decoration: const InputDecoration(labelText: 'Gestao da conta'),
            items: _editableOwnershipStates
                .map(
                  (state) => DropdownMenuItem<TenantAdminOwnershipState>(
                    value: state,
                    child: Text(state.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedOwnershipState = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Gestao da conta e obrigatoria.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                context.router
                    .push(const TenantAdminProfileTypeCreateRoute())
                    .then((_) {
                      if (!mounted) {
                        return;
                      }
                      _controller.loadProfileTypes();
                    });
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
    final allowedDefinitions = _allowedTaxonomyDefinitions(
      state.selectedProfileType,
    );
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
              maxContentBytes: accountProfileRichTextMaxBytes,
              warningThreshold: accountProfileRichTextWarningThreshold,
            ),
          ],
          if (hasContent) ...[
            if (hasBio) const SizedBox(height: 12),
            TenantAdminRichTextEditor(
              controller: _controller.contentController,
              label: 'Conteudo',
              placeholder: 'Edite o conteudo estendido do perfil',
              minHeight: 220,
              maxContentBytes: accountProfileRichTextMaxBytes,
              warningThreshold: accountProfileRichTextWarningThreshold,
            ),
          ],
          if (_hasTaxonomies(state.selectedProfileType)) ...[
            if (hasBio || hasContent) const SizedBox(height: 12),
            Text('Taxonomias', style: Theme.of(context).textTheme.labelLarge),
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
                                            children:
                                                (termsByTaxonomy[taxonomy
                                                            .slug] ??
                                                        const [])
                                                    .map(
                                                      (term) => FilterChip(
                                                        label: Text(term.name),
                                                        selected:
                                                            selections[taxonomy
                                                                    .slug]
                                                                ?.contains(
                                                                  term.slug,
                                                                ) ??
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

  TenantAdminAccountProfile? _selectedEditContactSourceCandidate(
    TenantAdminAccountProfileEditDraft state,
  ) {
    final selectedId = state.contactSourceAccountProfileId?.trim();
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final profile
        in _controller.contactSourceCandidatesStreamValue.value) {
      if (profile.id == selectedId) {
        return profile;
      }
    }
    return null;
  }

  String? _validateEditBubbleSelection(
    TenantAdminAccountProfileEditDraft state,
    TenantAdminAccountProfile? selectedSource, {
    required bool capabilityEnabled,
  }) {
    if (!capabilityEnabled ||
        state.contactMode != BellugaContactSourceMode.mirroredAccountProfile) {
      return null;
    }
    final selectedId = _persistedBubbleChannelId(state.contactBubbleSelection);
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    return selectedSource?.effectiveContactChannels.any(
              (channel) => channel.id == selectedId && channel.isBubbleEligible,
            ) !=
            true
        ? 'Selecione um canal de WhatsApp válido para o balão.'
        : null;
  }

  String? _persistedBubbleChannelId(
    BellugaContactBubbleSelectionMutation selection,
  ) => selection is BellugaContactBubbleSelectionPersisted
      ? selection.channelId
      : null;

  IconData _contactIconFor(BellugaContactIconToken token) {
    return switch (token) {
      BellugaContactIconToken.emailOutlined => Icons.email_outlined,
      BellugaContactIconToken.whatsapp => BooraIcons.whatsapp,
    };
  }

  String _formatContactChannelType(BellugaContactChannelType type) {
    return switch (type) {
      BellugaContactChannelType.email => 'E-mail',
      BellugaContactChannelType.whatsapp => 'WhatsApp',
    };
  }

  String _formatContactChannelOption(BellugaContactChannel channel) {
    final title = channel.title?.trim();
    if (title == null || title.isEmpty) {
      return channel.value;
    }
    return '${channel.value} • $title';
  }

  Widget _buildContactSourceSection(
    BuildContext context,
    TenantAdminAccountProfileEditDraft state,
  ) {
    final isMirrored =
        state.contactMode == BellugaContactSourceMode.mirroredAccountProfile;
    return TenantAdminFormSectionCard(
      title: 'Origem do Contato',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<BellugaContactSourceMode>(
            groupValue: state.contactMode,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _controller.updateEditContactMode(value);
              _controller.updateEditContactBubbleChannelId(null);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                RadioListTile<BellugaContactSourceMode>(
                  key: Key('tenantAdminEditContactModeOwn'),
                  value: BellugaContactSourceMode.own,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Usar canais deste perfil'),
                  subtitle: Text(
                    'E-mail e WhatsApp serão configurados diretamente aqui.',
                  ),
                ),
                RadioListTile<BellugaContactSourceMode>(
                  key: Key('tenantAdminEditContactModeMirrored'),
                  value: BellugaContactSourceMode.mirroredAccountProfile,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Espelhar outro perfil'),
                  subtitle: Text(
                    'Este perfil publicará os canais efetivos do perfil selecionado.',
                  ),
                ),
              ],
            ),
          ),
          if (isMirrored) ...[
            const SizedBox(height: 12),
            StreamValueBuilder<List<TenantAdminAccountProfile>>(
              streamValue: _controller.contactSourceCandidatesStreamValue,
              builder: (context, candidates) {
                final selectedSource = _selectedEditContactSourceCandidate(
                  state,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('tenantAdminEditContactSourcePicker'),
                      icon: const Icon(Icons.person_search_outlined),
                      label: Text(
                        selectedSource == null
                            ? 'Selecionar perfil de origem'
                            : selectedSource.displayName,
                      ),
                      onPressed: () async {
                        final selected = await showTenantAdminAccountProfilePicker(
                          context: context,
                          candidatesStreamValue:
                              _controller.contactSourceCandidatesStreamValue,
                          isLoadingStreamValue: _controller
                              .contactSourceCandidatesLoadingStreamValue,
                          isPageLoadingStreamValue: _controller
                              .contactSourceCandidatesPageLoadingStreamValue,
                          hasMoreStreamValue: _controller
                              .contactSourceCandidatesHasMoreStreamValue,
                          errorStreamValue: _controller
                              .contactSourceCandidatesErrorStreamValue,
                          loadNextPage:
                              _controller.loadNextContactSourceCandidatesPage,
                          title: 'Perfil de origem',
                          emptyMessage:
                              'Nenhum perfil elegível para espelhar contatos.',
                          selectedProfileId: selectedSource?.id,
                        );
                        if (!context.mounted || selected == null) return;
                        _controller.updateEditContactSourceAccountProfileId(
                          selected.id,
                        );
                        _controller.updateEditContactBubbleChannelId(null);
                      },
                    ),
                    if (candidates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Nenhum perfil próprio com contato habilitado está disponível.',
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (selectedSource == null)
                      const Text(
                        'Selecione um perfil para visualizar os canais efetivos que serão espelhados.',
                      )
                    else
                      _buildContactPreview(
                        context,
                        channels: selectedSource.effectiveContactChannels,
                        emptyMessage:
                            'O perfil selecionado ainda não possui canais de contato válidos.',
                        selectedBubbleChannelId: _persistedBubbleChannelId(
                          state.contactBubbleSelection,
                        ),
                        onBubbleChanged: (channel, selected) =>
                            _controller.updateEditContactBubbleChannelId(
                              selected ? channel.id : null,
                            ),
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

  Widget _buildContactChannelsSection(
    BuildContext context,
    TenantAdminAccountProfileEditDraft state,
  ) {
    if (state.contactMode == BellugaContactSourceMode.mirroredAccountProfile) {
      return TenantAdminFormSectionCard(
        title: 'Canais de Contato',
        child: StreamValueBuilder<List<TenantAdminAccountProfile>>(
          streamValue: _controller.contactSourceCandidatesStreamValue,
          builder: (context, _) {
            final selectedSource = _selectedEditContactSourceCandidate(state);
            if (selectedSource == null) {
              return const Text(
                'Selecione um perfil de origem para visualizar os canais efetivos.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A edição local de canais fica desativada no modo espelhado. Edite o perfil de origem para alterar os canais exibidos aqui.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _buildContactPreview(
                  context,
                  channels: selectedSource.effectiveContactChannels,
                  emptyMessage:
                      'O perfil de origem ainda não possui canais de contato válidos.',
                  selectedBubbleChannelId: _persistedBubbleChannelId(
                    state.contactBubbleSelection,
                  ),
                  onBubbleChanged: (channel, selected) =>
                      _controller.updateEditContactBubbleChannelId(
                        selected ? channel.id : null,
                      ),
                ),
              ],
            );
          },
        ),
      );
    }

    return TenantAdminFormSectionCard(
      title: 'Canais de Contato',
      child: TenantAdminContactChannelsEditor(
        drafts: state.contactChannelDrafts,
        bubbleSelection: state.contactBubbleSelection,
        expandedCtaDraftKey: state.expandedContactCtaDraftKey,
        onAddChannel: _controller.addEditContactChannel,
        onUpdateChannel: _controller.updateEditContactChannel,
        onRemoveChannel: _controller.removeEditContactChannel,
        onSelectBubble: _controller.selectEditContactBubble,
        onToggleCtaEditor: _controller.toggleEditContactCtaEditor,
        onAddInitialMessage: _controller.addEditContactInitialMessage,
        onUpdateInitialMessage: _controller.updateEditContactInitialMessage,
        onRemoveInitialMessage:
            _controller.removeEditContactInitialMessageFromChannel,
      ),
    );
  }

  Widget _buildContactPreview(
    BuildContext context, {
    required List<BellugaContactChannel> channels,
    required String emptyMessage,
    String? selectedBubbleChannelId,
    void Function(BellugaContactChannel channel, bool selected)?
    onBubbleChanged,
  }) {
    if (channels.isEmpty) {
      return Text(emptyMessage);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: channels
          .map(
            (channel) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_contactIconFor(channel.iconToken)),
                    title: Text(_formatContactChannelType(channel.type)),
                    subtitle: Text(_formatContactChannelOption(channel)),
                  ),
                  if (channel.isBubbleEligible && onBubbleChanged != null)
                    SwitchListTile(
                      key: Key(
                        'tenantAdminEditMirroredBubbleToggle_${channel.id}',
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ativar balão flutuante'),
                      value: selectedBubbleChannelId == channel.id,
                      onChanged: (selected) =>
                          onBubbleChanged(channel, selected),
                    ),
                ],
              ),
            ),
          )
          .toList(growable: false),
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
            TenantAdminCanonicalImageUploadField(
              variant: TenantAdminImageUploadVariant.avatar,
              preview: state.avatarFile != null
                  ? Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: TenantAdminXFilePreview(
                            file: state.avatarFile!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (state.avatarRemoteError)
                          Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                      ],
                    )
                  : hasAvatarUrl
                  ? ClipRRect(
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
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
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
                  : state.avatarRemoteError
                  ? _buildAvatarError(context)
                  : Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Icon(Icons.person_outline),
                    ),
              selectedLabel:
                  state.avatarFile?.name ??
                  (hasAvatarUrl ? avatarUrl : 'Nenhuma imagem selecionada'),
              addLabel: 'Adicionar avatar',
              sourceSheetTitle: 'Adicionar avatar',
              urlPromptTitle: 'URL do avatar',
              busy: state.avatarBusy,
              canRemove: state.avatarFile != null || hasAvatarUrl,
              removeButtonKey: const ValueKey(
                'accountProfileEditAvatarRemoveButton',
              ),
              onRemove: () => _clearImage(isAvatar: true),
              initialWebUrl: avatarUrl,
              slot: TenantAdminImageSlot.avatar,
              pickFromDevice: () => _controller.pickImageFromDevice(
                slot: TenantAdminImageSlot.avatar,
              ),
              fetchImageFromUrlForCrop: _controller.fetchImageFromUrlForCrop,
              readBytesForCrop: _controller.readImageBytesForCrop,
              prepareCroppedFile: _controller.prepareCroppedImage,
              onBusyChanged: _controller.updateEditAvatarBusy,
              onImageSelected: (cropped) async {
                _controller.updateAvatarFile(cropped);
                await _autoSaveImages();
              },
              onIngestionError: _controller.reportEditErrorMessage,
            ),
          ],
          if (hasAvatar && hasCover) const SizedBox(height: 16),
          if (hasCover) ...[
            TenantAdminCanonicalImageUploadField(
              variant: TenantAdminImageUploadVariant.cover,
              preview: state.coverFile != null
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: TenantAdminXFilePreview(
                            file: state.coverFile!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (state.coverRemoteError)
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                      ],
                    )
                  : hasCoverUrl
                  ? ClipRRect(
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
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
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
                  : state.coverRemoteError
                  ? _buildCoverError(context)
                  : Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.image_outlined)),
                    ),
              selectedLabel:
                  state.coverFile?.name ??
                  (hasCoverUrl ? coverUrl : 'Nenhuma imagem selecionada'),
              addLabel: 'Adicionar capa',
              sourceSheetTitle: 'Adicionar capa',
              urlPromptTitle: 'URL da capa',
              busy: state.coverBusy,
              canRemove: state.coverFile != null || hasCoverUrl,
              removeButtonKey: const ValueKey(
                'accountProfileEditCoverRemoveButton',
              ),
              onRemove: () => _clearImage(isAvatar: false),
              initialWebUrl: coverUrl,
              slot: TenantAdminImageSlot.accountProfileHeroCover,
              pickFromDevice: () => _controller.pickImageFromDevice(
                slot: TenantAdminImageSlot.accountProfileHeroCover,
              ),
              fetchImageFromUrlForCrop: _controller.fetchImageFromUrlForCrop,
              readBytesForCrop: _controller.readImageBytesForCrop,
              prepareCroppedFile: _controller.prepareCroppedImage,
              onBusyChanged: _controller.updateEditCoverBusy,
              onImageSelected: (cropped) async {
                _controller.updateCoverFile(cropped);
                await _autoSaveImages();
              },
              onIngestionError: _controller.reportEditErrorMessage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGallerySection(TenantAdminAccountProfileEditDraft state) {
    return TenantAdminAccountProfileGalleryEditor(
      groups: state.galleryGroups,
      totalItemCount: _controller.editGalleryItemCount(),
      maxGroups: TenantAdminAccountProfileGalleryOperations.maxGroups,
      maxItems: TenantAdminAccountProfileGalleryOperations.maxItems,
      onAddGroup: _controller.addEditGalleryGroup,
      onRenameGroup: _controller.renameEditGalleryGroup,
      onMoveGroup: _controller.moveEditGalleryGroup,
      onRemoveGroup: _controller.removeEditGalleryGroup,
      onAddItemRequested: _addGalleryItem,
      onReplaceItemRequested: _replaceGalleryItem,
      onMoveItem: (groupId, itemId, delta) {
        _controller.moveEditGalleryItem(
          groupId: groupId,
          itemId: itemId,
          delta: delta,
        );
      },
      onRemoveItem: (groupId, itemId) {
        _controller.removeEditGalleryItem(groupId: groupId, itemId: itemId);
      },
      onDescriptionChanged: (groupId, itemId, description) {
        _controller.updateEditGalleryItemDescription(
          groupId: groupId,
          itemId: itemId,
          description: description,
        );
      },
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
              decimal: true,
              signed: true,
            ),
            inputFormatters: tenantAdminCoordinateInputFormatters,
            textInputAction: TextInputAction.next,
            validator: _validateLatitude,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.longitudeController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
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
