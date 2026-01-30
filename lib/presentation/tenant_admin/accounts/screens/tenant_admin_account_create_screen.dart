import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
              const Text(
                'Criar Conta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório.';
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
                    return 'Tipo do documento é obrigatório.';
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: const TextStyle(color: Colors.red),
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
                                        setState(() => _selectedProfileType = value);
                                      }
                                    : null,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Tipo de perfil é obrigatório.';
                                  }
                                  return null;
                                },
                              ),
                              if (!isLoading && error == null && !hasTypes)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('Nenhum tipo disponível para este tenant.'),
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
                decoration:
                    const InputDecoration(labelText: 'Nome de exibição'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome de exibição é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentNumberController,
                decoration: const InputDecoration(labelText: 'Número do documento'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Número do documento é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(
                  labelText:
                      requiresLocation ? 'Latitude' : 'Latitude (opcional)',
                ),
                keyboardType: TextInputType.number,
                validator: _validateLatitude,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(
                  labelText:
                      requiresLocation ? 'Longitude' : 'Longitude (opcional)',
                ),
                keyboardType: TextInputType.number,
                validator: _validateLongitude,
              ),
              if (requiresLocation) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Selecionar no mapa'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  final selectedType = _selectedProfileType ?? '';
                  final location = _currentLocation();
                  await _controller.createAccountWithProfile(
                    name: _nameController.text.trim(),
                    documentType: _documentTypeController.text.trim(),
                    documentNumber: _documentNumberController.text.trim(),
                    profileType: selectedType,
                    displayName: _profileDisplayNameController.text.trim(),
                    location: location,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conta e perfil salvos.')),
                  );
                  context.router.maybePop();
                },
                child: const Text('Salvar Conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
