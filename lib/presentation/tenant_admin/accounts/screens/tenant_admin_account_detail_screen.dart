import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountDetailScreen extends StatelessWidget {
  const TenantAdminAccountDetailScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

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
            'Conta: $accountSlug',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('Status: pertence ao tenant'),
          const SizedBox(height: 8),
          const Text('Documento: pendente'),
          const SizedBox(height: 8),
          const Text('Organização: nenhuma'),
        ],
      ),
    );
  }
}
