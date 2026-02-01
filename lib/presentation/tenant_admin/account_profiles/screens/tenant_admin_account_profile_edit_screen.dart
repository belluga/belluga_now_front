import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileEditScreen extends StatefulWidget {
  const TenantAdminAccountProfileEditScreen({
    super.key,
    required this.accountProfileId,
    required this.controller,
    required this.locationPickerController,
  });

  final String accountProfileId;
  final TenantAdminAccountProfilesController controller;
  final TenantAdminLocationPickerController locationPickerController;

  @override
  State<TenantAdminAccountProfileEditScreen> createState() =>
      _TenantAdminAccountProfileEditScreenState();
}

class _TenantAdminAccountProfileEditScreenState
    extends State<TenantAdminAccountProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final Map<String, TextEditingController> _taxonomyControllers = {};
  XFile? _avatarFile;
  XFile? _coverFile;
  String? _avatarRemoteUrl;
  String? _coverRemoteUrl;
  bool _avatarRemoteReady = false;
  bool _coverRemoteReady = false;
  bool _avatarRemoteError = false;
  bool _coverRemoteError = false;
  String? _avatarPreloadUrl;
  String? _coverPreloadUrl;
  String? _selectedProfileType;
  TenantAdminAccountProfile? _profile;
  String? _errorMessage;
  bool _isLoading = true;
  late final TenantAdminAccountProfilesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _controller.loadProfileTypes();
      final profile = await _controller.fetchProfile(widget.accountProfileId);
      if (!mounted) return;
      _profile = profile;
      _selectedProfileType = profile.profileType;
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _syncRemoteState(profile);
      _syncTaxonomyControllers(profile);
      if (profile.location != null) {
        _latitudeController.text =
            profile.location!.latitude.toStringAsFixed(6);
        _longitudeController.text =
            profile.location!.longitude.toStringAsFixed(6);
      } else {
        _latitudeController.clear();
        _longitudeController.clear();
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    for (final controller in _taxonomyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TenantAdminProfileTypeDefinition? _selectedProfileTypeDefinition() {
    final selectedType = _selectedProfileType;
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

  bool _requiresLocation() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.isPoiEnabled ?? false;
  }

  bool _hasBio() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.hasBio ?? false;
  }

  bool _hasTaxonomies() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.hasTaxonomies ?? false;
  }

  bool _hasAvatar() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.hasAvatar ?? false;
  }

  bool _hasCover() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.hasCover ?? false;
  }

  List<String> _allowedTaxonomies() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.allowedTaxonomies ?? const [];
  }

  void _syncTaxonomyControllers(TenantAdminAccountProfile profile) {
    final allowed = _allowedTaxonomies().toSet();
    _taxonomyControllers.removeWhere((key, controller) {
      if (allowed.contains(key)) return false;
      controller.dispose();
      return true;
    });
    for (final taxonomy in allowed) {
      final controller = _taxonomyControllers.putIfAbsent(
        taxonomy,
        () => TextEditingController(),
      );
      final values = profile.taxonomyTerms
          .where((term) => term.type == taxonomy)
          .map((term) => term.value)
          .where((value) => value.trim().isNotEmpty)
          .toList();
      controller.text = values.join(', ');
    }
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms() {
    if (!_hasTaxonomies()) {
      return const [];
    }
    final terms = <TenantAdminTaxonomyTerm>[];
    for (final entry in _taxonomyControllers.entries) {
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
    final other = _longitudeController.text.trim();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Latitude inválida.';
    }
    if (_requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    if (_requiresLocation() && trimmed.isEmpty && other.isEmpty) {
      return 'Localização é obrigatória para este perfil.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _latitudeController.text.trim();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Longitude inválida.';
    }
    if (_requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Longitude é obrigatória.';
    }
    return null;
  }

  TenantAdminLocation? _currentLocation() {
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
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
    final selected = await context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
        controller: widget.locationPickerController,
      ),
    );
    if (selected == null) {
      return;
    }
    _latitudeController.text = selected.latitude.toStringAsFixed(6);
    _longitudeController.text = selected.longitude.toStringAsFixed(6);
    setState(() {});
  }

  Future<void> _autoSaveImages() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final avatarUpload =
        _hasAvatar() ? await _buildUpload(_avatarFile) : null;
    final coverUpload =
        _hasCover() ? await _buildUpload(_coverFile) : null;
    if (avatarUpload == null && coverUpload == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final updated = await _controller.updateProfile(
        accountProfileId: profile.id,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _syncRemoteState(updated);
        _isLoading = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Imagem atualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao salvar imagem: $error')),
      );
    }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato de imagem invalido. Use JPG, PNG ou WEBP.'),
        ),
      );
      return;
    }
    final size = await selected.length();
    const maxBytes = 5 * 1024 * 1024;
    if (size > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem muito grande. Maximo 5MB.'),
        ),
      );
      return;
    }
    setState(() {
      if (isAvatar) {
        _avatarFile = selected;
        _avatarRemoteReady = false;
        _avatarRemoteError = false;
        _avatarPreloadUrl = null;
      } else {
        _coverFile = selected;
        _coverRemoteReady = false;
        _coverRemoteError = false;
        _coverPreloadUrl = null;
      }
    });
    await _autoSaveImages();
  }

  void _clearImage({required bool isAvatar}) {
    setState(() {
      if (isAvatar) {
        _avatarFile = null;
        _avatarRemoteError = false;
      } else {
        _coverFile = null;
        _coverRemoteError = false;
      }
    });
  }

  Future<TenantAdminMediaUpload?> _buildUpload(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return TenantAdminMediaUpload(
      bytes: bytes,
      fileName: file.name,
    );
  }

  void _syncRemoteState(TenantAdminAccountProfile updated) {
    final avatarUrl = updated.avatarUrl;
    final coverUrl = updated.coverUrl;

    if (avatarUrl != _avatarRemoteUrl) {
      _avatarRemoteUrl = avatarUrl;
      _avatarRemoteReady = false;
      _avatarRemoteError = false;
      _avatarPreloadUrl = null;
    }
    if (coverUrl != _coverRemoteUrl) {
      _coverRemoteUrl = coverUrl;
      _coverRemoteReady = false;
      _coverRemoteError = false;
      _coverPreloadUrl = null;
    }
  }

  void _preloadRemoteImage({
    required String url,
    required bool isAvatar,
  }) {
    if (isAvatar) {
      if (_avatarPreloadUrl == url) return;
      _avatarPreloadUrl = url;
    } else {
      if (_coverPreloadUrl == url) return;
      _coverPreloadUrl = url;
    }

    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        if (!mounted) return;
        setState(() {
          if (isAvatar) {
            _avatarRemoteReady = true;
            _avatarRemoteError = false;
            _avatarFile = null;
          } else {
            _coverRemoteReady = true;
            _coverRemoteError = false;
            _coverFile = null;
          }
        });
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!mounted) return;
        setState(() {
          if (isAvatar) {
            _avatarRemoteError = true;
          } else {
            _coverRemoteError = true;
          }
        });
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final requiresLocation = _requiresLocation();
    final hasMedia = _hasAvatar() || _hasCover();
    final hasContent = _hasBio() || _hasTaxonomies();
    if (_errorMessage != null) {
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
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_profile == null && _isLoading) {
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) const LinearProgressIndicator(),
                if (_isLoading) const SizedBox(height: 12),
                _buildProfileSection(context),
                if (hasContent) ...[
                  const SizedBox(height: 16),
                  _buildContentSection(context),
                ],
                if (hasMedia) ...[
                  const SizedBox(height: 16),
                  _buildMediaSection(context),
                ],
                if (requiresLocation) ...[
                  const SizedBox(height: 16),
                  _buildLocationSection(context),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final form = _formKey.currentState;
                            if (form == null || !form.validate()) {
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            final avatarUpload =
                                _hasAvatar() ? await _buildUpload(_avatarFile) : null;
                            final coverUpload =
                                _hasCover() ? await _buildUpload(_coverFile) : null;
                            final updated = await _controller.updateProfile(
                              accountProfileId: widget.accountProfileId,
                              profileType: _selectedProfileType,
                              displayName: _displayNameController.text.trim(),
                              bio: _hasBio() ? _bioController.text.trim() : null,
                              taxonomyTerms:
                                  _hasTaxonomies() ? _buildTaxonomyTerms() : null,
                              location:
                                  requiresLocation ? _currentLocation() : null,
                              avatarUpload: avatarUpload,
                              coverUpload: coverUpload,
                            );
                            if (!mounted) return;
                            setState(() {
                              _profile = updated;
                              _syncRemoteState(updated);
                            });
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Perfil atualizado.')),
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
  }

  Widget _buildProfileSection(BuildContext context) {
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
                    .any((definition) => definition.type == _selectedProfileType);
                final effectiveSelected =
                    hasSelected ? _selectedProfileType : null;
                if (!hasSelected && _selectedProfileType != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedProfileType = null;
                    });
                  });
                }
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
                    setState(() {
                      _selectedProfileType = value;
                      if (_profile != null) {
                        _syncTaxonomyControllers(_profile!);
                      }
                      if (!_requiresLocation()) {
                        _latitudeController.clear();
                        _longitudeController.clear();
                      }
                      if (!_hasBio()) {
                        _bioController.clear();
                      }
                      if (!_hasTaxonomies()) {
                        for (final controller in _taxonomyControllers.values) {
                          controller.clear();
                        }
                      }
                    });
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
              controller: _displayNameController,
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

  Widget _buildContentSection(BuildContext context) {
    final hasBio = _hasBio();
    final allowedTaxonomies = _allowedTaxonomies();
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
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 4,
                minLines: 2,
              ),
            ],
            if (_hasTaxonomies()) ...[
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
                    controller: _taxonomyControllers[taxonomy],
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

  Widget _buildMediaSection(BuildContext context) {
    final avatarUrl = _avatarRemoteUrl;
    final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final coverUrl = _coverRemoteUrl;
    final hasCoverUrl = coverUrl != null && coverUrl.isNotEmpty;
    final hasAvatar = _hasAvatar();
    final hasCover = _hasCover();

    if (_avatarFile != null && hasAvatarUrl && !_avatarRemoteReady) {
      _preloadRemoteImage(url: avatarUrl, isAvatar: true);
    }
    if (_coverFile != null && hasCoverUrl && !_coverRemoteReady) {
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
                  if (_avatarFile != null)
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.file(
                            File(_avatarFile!.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_avatarRemoteError)
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_avatarRemoteError) return;
                            setState(() {
                              _avatarRemoteError = true;
                            });
                          });
                          return _buildAvatarError(context);
                        },
                      ),
                    )
                  else if (_avatarRemoteError)
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
                          _avatarFile?.name ??
                              (_profile?.avatarUrl?.isNotEmpty ?? false
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
                            if (_avatarFile != null)
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
              if (_coverFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_coverFile!.path),
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_coverRemoteError)
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (_coverRemoteError) return;
                        setState(() {
                          _coverRemoteError = true;
                        });
                      });
                      return _buildCoverError(context);
                    },
                  ),
                )
              else if (_coverRemoteError)
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
                  if (_coverFile != null)
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
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
              validator: _validateLatitude,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _longitudeController,
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
