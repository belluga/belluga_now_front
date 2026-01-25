import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
  final _store = GetIt.I.get<TenantAdminStore>();

  @override
  void dispose() {
    _nameController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  _store.addAccount(
                    name: _nameController.text.trim(),
                    documentType: _documentTypeController.text.trim(),
                    documentNumber: _documentNumberController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conta salva.')),
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

