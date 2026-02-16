import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';

class TenantAdminTaxonomyTermDetailScreen extends StatelessWidget {
  const TenantAdminTaxonomyTermDetailScreen({
    super.key,
    required this.taxonomyId,
    required this.taxonomyName,
    required this.term,
  });

  final String taxonomyId;
  final String taxonomyName;
  final TenantAdminTaxonomyTermDefinition term;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(term.name),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {
              context.router.push(
                TenantAdminTaxonomyTermEditRoute(
                  taxonomyId: taxonomyId,
                  taxonomyName: taxonomyName,
                  term: term,
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes do termo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildRow(context, 'Nome', term.name),
                  const SizedBox(height: 8),
                  _buildRow(context, 'Slug', term.slug),
                  const SizedBox(height: 8),
                  _buildRow(context, 'Taxonomia', taxonomyName),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
