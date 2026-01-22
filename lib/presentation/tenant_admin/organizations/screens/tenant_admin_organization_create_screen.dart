import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

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
  final _slugController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.router.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(height: 8),
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
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final form = _formKey.currentState;
                if (form == null || !form.validate()) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Organização salva.'),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
