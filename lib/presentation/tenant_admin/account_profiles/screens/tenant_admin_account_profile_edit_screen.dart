import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  XFile? _avatarFile;
  XFile? _coverFile;
  String? _selectedProfileType;
  TenantAdminAccountProfile? _profile;
  String? _errorMessage;
  bool _isLoading = true;
  late final TenantAdminAccountProfilesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminAccountProfilesController>();
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
    _latitudeController.dispose();
    _longitudeController.dispose();
    _controller.dispose();
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

  bool _requiresLocation() {
    final definition = _selectedProfileTypeDefinition();
    return definition?.capabilities.isPoiEnabled ?? false;
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
      TenantAdminLocationPickerRoute(initialLocation: currentLocation),
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
    final avatarUpload = await _buildUpload(_avatarFile);
    final coverUpload = await _buildUpload(_coverFile);
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
        _avatarFile = null;
        _coverFile = null;
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
    setState(() {
      if (isAvatar) {
        _avatarFile = selected;
      } else {
        _coverFile = selected;
      }
    });
    await _autoSaveImages();
  }

  void _clearImage({required bool isAvatar}) {
    setState(() {
      if (isAvatar) {
        _avatarFile = null;
      } else {
        _coverFile = null;
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

  @override
  Widget build(BuildContext context) {
    final requiresLocation = _requiresLocation();
    return Padding(
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.router.maybePop(),
                  tooltip: 'Voltar',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Editar Perfil',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_isLoading) const LinearProgressIndicator(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              StreamValueBuilder(
                streamValue: _controller.profileTypesStreamValue,
                builder: (context, types) {
                  return DropdownButtonFormField<String>(
                    key: ValueKey(_selectedProfileType),
                    initialValue: _selectedProfileType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de perfil',
                    ),
                    items: types
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
                        if (!_requiresLocation()) {
                          _latitudeController.clear();
                          _longitudeController.clear();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tipo de perfil é obrigatório.';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Nome de exibição'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome de exibição é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Imagem de perfil',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_avatarFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.file(
                        File(_avatarFile!.path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_profile?.avatarUrl != null &&
                      _profile!.avatarUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.network(
                        _profile!.avatarUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                            TextButton.icon(
                              onPressed: () => _pickImage(isAvatar: true),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Selecionar'),
                            ),
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
              const SizedBox(height: 16),
              Text(
                'Capa',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_coverFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_coverFile!.path),
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_profile?.coverUrl != null &&
                  _profile!.coverUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _profile!.coverUrl!,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                )
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
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(isAvatar: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Selecionar capa'),
                  ),
                  if (_coverFile != null)
                    TextButton(
                      onPressed: () => _clearImage(isAvatar: false),
                      child: const Text('Remover'),
                    ),
                ],
              ),
              if (requiresLocation) ...[
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
                TextButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Selecionar no mapa'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final form = _formKey.currentState;
                        if (form == null || !form.validate()) {
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final avatarUpload = await _buildUpload(_avatarFile);
                        final coverUpload = await _buildUpload(_coverFile);
                        final updated = await _controller.updateProfile(
                          accountProfileId: widget.accountProfileId,
                          profileType: _selectedProfileType,
                          displayName: _displayNameController.text.trim(),
                          location: requiresLocation ? _currentLocation() : null,
                          avatarUpload: avatarUpload,
                          coverUpload: coverUpload,
                        );
                        if (!mounted) return;
                        setState(() {
                          _profile = updated;
                          _avatarFile = null;
                          _coverFile = null;
                        });
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Perfil atualizado.')),
                        );
                      },
                child: const Text('Atualizar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
