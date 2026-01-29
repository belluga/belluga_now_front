import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminOrganizationCreateScreen extends StatefulWidget {
  const TenantAdminOrganizationCreateScreen({super.key});

  @override
  State<TenantAdminOrganizationCreateScreen> createState() =>
      _TenantAdminOrganizationCreateScreenState();
}

class _TenantAdminOrganizationCreateScreenState
    extends State<TenantAdminOrganizationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TenantAdminOrganizationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminOrganizationsController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                'Criar Organização',
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
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  await _controller.createOrganization(
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Organização salva.'),
                    ),
                  );
                  context.router.maybePop();
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
