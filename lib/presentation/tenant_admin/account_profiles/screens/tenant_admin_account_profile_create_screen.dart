import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileCreateScreen extends StatefulWidget {
  const TenantAdminAccountProfileCreateScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  State<TenantAdminAccountProfileCreateScreen> createState() =>
      _TenantAdminAccountProfileCreateScreenState();
}

class _TenantAdminAccountProfileCreateScreenState
    extends State<TenantAdminAccountProfileCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String? _selectedProfileType;
  late final TenantAdminAccountProfilesController _controller;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    _load();
  }

  Future<void> _load() async {
    await _controller.loadProfileTypes();
    final account =
        await _controller.resolveAccountBySlug(widget.accountSlug);
    if (!mounted) return;
    _accountId = account.id;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
              Text(
                'Criar Perfil - ${widget.accountSlug}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
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
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Nome de exibição'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome de exibição é obrigatório.';
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
                decoration:
                    const InputDecoration(labelText: 'Longitude (opcional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  if (_accountId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conta inválida.')),
                    );
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
                  await _controller.createProfile(
                    accountId: _accountId!,
                    profileType: selectedType,
                    displayName: _displayNameController.text.trim(),
                    location: location,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil salvo.')),
                  );
                  context.router.maybePop();
                },
                child: const Text('Salvar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
