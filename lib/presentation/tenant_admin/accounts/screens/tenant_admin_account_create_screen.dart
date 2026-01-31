import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountCreateScreen extends StatefulWidget {
  const TenantAdminAccountCreateScreen({super.key});

  @override
  State<TenantAdminAccountCreateScreen> createState() =>
      _TenantAdminAccountCreateScreenState();
}

class _TenantAdminAccountCreateScreenState
    extends State<TenantAdminAccountCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentTypeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _profileDisplayNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  XFile? _avatarFile;
  XFile? _coverFile;
  String? _selectedProfileType;
  late final TenantAdminAccountsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminAccountsController>();
    _controller.loadProfileTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _profileDisplayNameController.dispose();
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
    final requires = _requiresLocation();
    if (requires && trimmed.isEmpty && other.isEmpty) {
      return 'Localização é obrigatória para este perfil.';
    }
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Latitude inválida.';
    }
    if (requires && trimmed.isEmpty && other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _latitudeController.text.trim();
    final requires = _requiresLocation();
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
      return 'Longitude inválida.';
    }
    if (requires && trimmed.isEmpty && other.isNotEmpty) {
      return 'Longitude é obrigatória.';
    }
    return null;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
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
                _buildAccountSection(context),
                const SizedBox(height: 16),
                _buildMediaSection(context),
                if (requiresLocation) ...[
                  const SizedBox(height: 16),
                  _buildLocationSection(context),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('tenant_admin_account_create_save'),
                    onPressed: () async {
                      final form = _formKey.currentState;
                      if (form == null || !form.validate()) {
                        return;
                      }
                      final selectedType = _selectedProfileType ?? '';
                      final location = _currentLocation();
                      final avatarUpload = await _buildUpload(_avatarFile);
                      final coverUpload = await _buildUpload(_coverFile);
                      await _controller.createAccountWithProfile(
                        name: _nameController.text.trim(),
                        documentType: _documentTypeController.text.trim(),
                        documentNumber: _documentNumberController.text.trim(),
                        profileType: selectedType,
                        displayName: _profileDisplayNameController.text.trim(),
                        location: location,
                        avatarUpload: avatarUpload,
                        coverUpload: coverUpload,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conta e perfil salvos.')),
                      );
                      context.router.maybePop();
                    },
                    child: const Text('Salvar conta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados da conta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome e obrigatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentTypeController,
              decoration: const InputDecoration(labelText: 'Tipo do documento'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tipo do documento e obrigatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<bool>(
              streamValue: _controller.isLoadingStreamValue,
              builder: (context, isLoading) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.errorStreamValue,
                  builder: (context, error) {
                    return StreamValueBuilder(
                      streamValue: _controller.profileTypesStreamValue,
                      builder: (context, types) {
                        final hasTypes = types.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLoading) const LinearProgressIndicator(),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Card(
                                  key: const ValueKey(
                                    'tenant_admin_account_create_profile_types_error',
                                  ),
                                  margin: EdgeInsets.zero,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Falha ao carregar tipos de perfil',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sua sessao de admin pode ter expirado. Tente novamente.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed:
                                                _controller.loadProfileTypes,
                                            child:
                                                const Text('Tentar novamente'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
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
                              onChanged: hasTypes
                                  ? (value) {
                                      setState(() {
                                        _selectedProfileType = value;
                                        if (!_requiresLocation()) {
                                          _latitudeController.clear();
                                          _longitudeController.clear();
                                        }
                                      });
                                    }
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tipo de perfil e obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            if (!isLoading && error == null && !hasTypes)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Nenhum tipo disponivel para este tenant.',
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _profileDisplayNameController,
              decoration: const InputDecoration(labelText: 'Nome de exibicao'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome de exibicao e obrigatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(labelText: 'Numero do documento'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Numero do documento e obrigatorio.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
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
                        _avatarFile?.name ?? 'Nenhuma imagem selecionada',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            key: const ValueKey(
                              'tenant_admin_account_create_avatar_pick',
                            ),
                            onPressed: () => _pickImage(isAvatar: true),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Selecionar'),
                          ),
                          const SizedBox(width: 8),
                          if (_avatarFile != null)
                            TextButton(
                              key: const ValueKey(
                                'tenant_admin_account_create_avatar_remove',
                              ),
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
                  key: const ValueKey(
                    'tenant_admin_account_create_cover_pick',
                  ),
                  onPressed: () => _pickImage(isAvatar: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Selecionar capa'),
                ),
                const SizedBox(width: 8),
                if (_coverFile != null)
                  TextButton(
                    key: const ValueKey(
                      'tenant_admin_account_create_cover_remove',
                    ),
                    onPressed: () => _clearImage(isAvatar: false),
                    child: const Text('Remover'),
                  ),
              ],
            ),
          ],
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
                    key: const ValueKey(
                      'tenant_admin_account_create_map_pick',
                    ),
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
