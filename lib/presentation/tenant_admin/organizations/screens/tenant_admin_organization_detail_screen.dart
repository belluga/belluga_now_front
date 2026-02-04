import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminOrganizationDetailScreen extends StatelessWidget {
  const TenantAdminOrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizacao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
          tooltip: 'Voltar',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('ID: $organizationId'),
                const SizedBox(height: 8),
                const Text('Nome: Organizacao de exemplo'),
                const SizedBox(height: 8),
                const Text('Slug: exemplo-org'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
