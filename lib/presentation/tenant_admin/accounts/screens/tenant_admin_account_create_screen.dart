import 'package:auto_route/auto_route.dart';
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

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Latitude (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: 'Longitude (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  final selectedType = _selectedProfileType ?? '';
                  final latText = _latitudeController.text.trim();
                  final lngText = _longitudeController.text.trim();
                  TenantAdminLocation? location;
                  if (latText.isNotEmpty || lngText.isNotEmpty) {
                    final lat = double.tryParse(latText);
                    final lng = double.tryParse(lngText);
                    if (lat == null || lng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Latitude/Longitude inválidas.')),
                      );
                      return;
                    }
                    location = TenantAdminLocation(latitude: lat, longitude: lng);
                  }
                  final definitions = _controller.profileTypesStreamValue.value;
                  TenantAdminProfileTypeDefinition? typeDefinition;
                  for (final def in definitions) {
                    if (def.type == selectedType) {
                      typeDefinition = def;
                      break;
                    }
                  }
                  if (typeDefinition != null &&
                      typeDefinition.capabilities.isPoiEnabled &&
                      location == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Localização é obrigatória para este perfil.'),
                      ),
                    );
                    return;
                  }
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
