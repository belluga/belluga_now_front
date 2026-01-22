import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

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
  final _profileTypeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _profileTypeController.dispose();
    _displayNameController.dispose();
    _locationController.dispose();
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
              label: const Text('Voltar'),
            ),
            const SizedBox(height: 8),
            Text(
              'Criar Perfil - ${widget.accountSlug}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _profileTypeController,
              decoration: const InputDecoration(labelText: 'Tipo de perfil'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tipo de perfil é obrigatório.';
                }
                return null;
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
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Localização'),
              validator: (value) {
                final profileType = _profileTypeController.text.trim();
                final requiresLocation = profileType == 'venue';
                if (requiresLocation && (value == null || value.isEmpty)) {
                  return 'Localização é obrigatória para o tipo de perfil.';
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil salvo.')),
                );
              },
              child: const Text('Salvar Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
