import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountProfileDetailScreen extends StatelessWidget {
  const TenantAdminAccountProfileDetailScreen({
    super.key,
    required this.accountProfileId,
  });

  final String accountProfileId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            'Perfil: $accountProfileId',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('Tipo: artista'),
          const SizedBox(height: 8),
          const Text('Nome de exibição: Perfil de exemplo'),
          const SizedBox(height: 8),
          const Text('Capacidades: favoritável'),
        ],
      ),
    );
  }
}
